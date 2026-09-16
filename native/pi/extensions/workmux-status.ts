/**
 * Workmux status tracking extension for Pi.
 *
 * Based on Workmux v0.1.263's bundled extension, with two waiting-state
 * workarounds until Workmux/Pi expose this behavior upstream:
 * - blocking Pi UI prompts report `waiting`
 * - a settled assistant response ending in a question reports `waiting`
 *
 * See: https://workmux.raine.dev/guide/status-tracking
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

type AssistantState = { stopReason?: string; errorMessage?: string };

interface AgentMessageLike {
  role?: unknown;
  content?: unknown;
}

function textContent(content: unknown): string {
  if (typeof content === "string") return content;
  if (!Array.isArray(content)) return "";

  return content
    .filter(
      (block): block is { type: "text"; text: string } =>
        typeof block === "object" &&
        block !== null &&
        "type" in block &&
        block.type === "text" &&
        "text" in block &&
        typeof block.text === "string",
    )
    .map((block) => block.text)
    .join("\n");
}

/**
 * Infer when a settled response asks the user to continue the interaction.
 * This is intentionally conservative: Pi does not provide a semantic
 * "waiting for input" event for ordinary assistant text.
 */
export function responseRequestsInput(messages: readonly unknown[]): boolean {
  const assistant = [...messages]
    .reverse()
    .find(
      (message): message is AgentMessageLike =>
        typeof message === "object" &&
        message !== null &&
        "role" in message &&
        message.role === "assistant",
    );

  if (!assistant) return false;

  const text = textContent(assistant.content).trimEnd();
  return /[?？](?:\s|["'”’)\]}>*_`~])*$/.test(text);
}

export default function workmuxStatus(pi: ExtensionAPI) {
  let sessionActive = false;
  let parentWorking = false;
  let activeCount: number | undefined;
  let blockingPromptCount = 0;
  let settledResponseRequestsInput = false;
  let unsubscribe: (() => void) | undefined;
  let writes = Promise.resolve();
  let lastStatus: string | undefined;

  function setStatus(status: string) {
    const deduplicate = activeCount !== undefined;
    // Event bus callbacks are not awaited by Pi. Serialize external writes so an
    // older command cannot finish after a newer status and overwrite it.
    writes = writes.then(async () => {
      if (deduplicate && status === lastStatus) return;
      try {
        const result = await pi.exec("workmux", ["set-window-status", status]);
        lastStatus = result.code === 0 ? status : undefined;
      } catch {
        lastStatus = undefined;
      }
    });
    return writes;
  }

  function reportActivity() {
    if (blockingPromptCount > 0) return setStatus("waiting");
    if (parentWorking || (activeCount ?? 0) > 0) return setStatus("working");
    return setStatus(settledResponseRequestsInput ? "waiting" : "done");
  }

  function latestAssistantWasAborted(ctx: ExtensionContext) {
    const branch = ctx.sessionManager.getBranch() as Array<{
      type?: string;
      message?: AssistantState & { role?: string };
    }>;
    for (let index = branch.length - 1; index >= 0; index--) {
      const entry = branch[index];
      if (entry?.type !== "message" || entry.message?.role !== "assistant") {
        continue;
      }
      return (
        entry.message.stopReason === "aborted" ||
        (entry.message.stopReason === "error" &&
          /\boperation was aborted\b/i.test(entry.message.errorMessage ?? ""))
      );
    }
    return false;
  }

  pi.on("session_start", async (_event, ctx) => {
    unsubscribe?.();
    sessionActive = false;
    await writes;
    activeCount = undefined;
    blockingPromptCount = 0;
    settledResponseRequestsInput = false;
    lastStatus = undefined;
    parentWorking = !ctx.isIdle();
    await pi.exec("workmux", ["register-agent"]).catch(() => {});
    sessionActive = true;
    unsubscribe = pi.events.on("suba:activity", (data) => {
      if (!sessionActive || !data || typeof data !== "object") return;
      const count = (data as { activeCount?: unknown }).activeCount;
      if (typeof count !== "number" || !Number.isSafeInteger(count) || count < 0) return;
      activeCount = count;
      return reportActivity();
    });
    // The publisher may have restored children before this handler subscribed.
    pi.events.emit("suba:activity:request", {});
    await writes;
  });

  pi.on("agent_start", async () => {
    if (!sessionActive) return;
    parentWorking = true;
    settledResponseRequestsInput = false;
    await reportActivity();
  });

  pi.on("agent_end", async (event) => {
    settledResponseRequestsInput = responseRequestsInput(event.messages);
  });

  pi.on("agent_settled", async (_event, ctx) => {
    if (!sessionActive) return;
    parentWorking = !ctx.isIdle();
    if (activeCount !== undefined) {
      await reportActivity();
    } else if (!latestAssistantWasAborted(ctx)) {
      await reportActivity();
    }
  });

  pi.on("ui_prompt_start", async () => {
    if (!sessionActive) return;
    blockingPromptCount += 1;
    await setStatus("waiting");
  });

  pi.on("ui_prompt_end", async () => {
    if (!sessionActive) return;
    blockingPromptCount = Math.max(0, blockingPromptCount - 1);
    await reportActivity();
  });

  pi.on("session_shutdown", async () => {
    unsubscribe?.();
    unsubscribe = undefined;
    const wasActive = sessionActive;
    sessionActive = false;
    blockingPromptCount = 0;
    settledResponseRequestsInput = false;
    if (wasActive && activeCount !== undefined) await setStatus("done");
    await writes;
  });
}
