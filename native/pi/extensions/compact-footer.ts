import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";
import { basename } from "node:path";

const CODEX_USAGE_URL = "https://chatgpt.com/backend-api/wham/usage";
const SEPARATOR = " · ";
const BAR_WIDTH = 10;

interface UsageWindow {
  readonly usedPercent: number;
  readonly windowSeconds: number;
}

interface CodexUsage {
  readonly primary: UsageWindow;
  readonly secondary: UsageWindow;
}

interface UsageWindowPayload {
  readonly used_percent?: unknown;
  readonly limit_window_seconds?: unknown;
}

interface UsagePayload {
  readonly rate_limit?: {
    readonly primary_window?: UsageWindowPayload;
    readonly secondary_window?: UsageWindowPayload;
  };
}

type ActiveModel = NonNullable<ExtensionContext["model"]>;

function isCodexSubscription(
  ctx: ExtensionContext,
  model: ActiveModel | undefined,
): model is ActiveModel {
  return Boolean(
    model &&
    model.provider === "openai-codex" &&
    model.api === "openai-codex-responses" &&
    ctx.modelRegistry.isUsingOAuth(model),
  );
}

function decodeJwtPayload(token: string): Record<string, unknown> | undefined {
  try {
    const encoded = token.split(".")[1];
    if (!encoded) return undefined;
    const normalized = encoded.replace(/-/g, "+").replace(/_/g, "/");
    const padded = normalized.padEnd(Math.ceil(normalized.length / 4) * 4, "=");
    return JSON.parse(Buffer.from(padded, "base64").toString("utf8")) as Record<string, unknown>;
  } catch {
    return undefined;
  }
}

function getAccountId(token: string): string | undefined {
  const payload = decodeJwtPayload(token);
  const auth = payload?.["https://api.openai.com/auth"];
  if (!auth || typeof auth !== "object") return undefined;
  const accountId = (auth as Record<string, unknown>)["chatgpt_account_id"];
  return typeof accountId === "string" ? accountId : undefined;
}

function parseWindow(value: UsageWindowPayload | undefined): UsageWindow | undefined {
  const usedPercent = value?.used_percent;
  const windowSeconds = value?.limit_window_seconds;
  if (typeof usedPercent !== "number" || typeof windowSeconds !== "number") return undefined;
  if (!Number.isFinite(usedPercent) || !Number.isFinite(windowSeconds) || windowSeconds <= 0)
    return undefined;
  return { usedPercent: Math.max(0, Math.min(100, usedPercent)), windowSeconds };
}

function parseUsage(value: unknown): CodexUsage | undefined {
  if (!value || typeof value !== "object") return undefined;
  const rateLimit = (value as UsagePayload).rate_limit;
  const primary = parseWindow(rateLimit?.primary_window);
  const secondary = parseWindow(rateLimit?.secondary_window);
  return primary && secondary ? { primary, secondary } : undefined;
}

function formatWindow(seconds: number): string {
  if (seconds < 86_400) return `${Math.round(seconds / 3_600)}h`;
  return `${Math.round(seconds / 86_400)}d`;
}

function sanitizeStatus(text: string): string {
  return text
    .replace(/[\r\n\t]/g, " ")
    .replace(/ +/g, " ")
    .trim();
}

export default function compactFooter(pi: ExtensionAPI) {
  let projectName = "";
  let activeModel: ActiveModel | undefined;
  let codexUsage: CodexUsage | undefined;
  let requestRender: (() => void) | undefined;
  let usageAbort: AbortController | undefined;
  let usageRequestId = 0;

  async function resolveProjectName(ctx: ExtensionContext): Promise<string> {
    const result = await pi.exec("git", ["rev-parse", "--show-toplevel"], {
      cwd: ctx.cwd,
      timeout: 2_000,
    });
    const root = result.code === 0 ? result.stdout.trim() : "";
    return basename(root || ctx.cwd);
  }

  async function refreshCodexUsage(ctx: ExtensionContext): Promise<void> {
    const model = activeModel;
    const requestId = ++usageRequestId;
    usageAbort?.abort();
    usageAbort = undefined;

    if (!isCodexSubscription(ctx, model)) {
      codexUsage = undefined;
      requestRender?.();
      return;
    }

    const controller = new AbortController();
    usageAbort = controller;

    try {
      const auth = await ctx.modelRegistry.getApiKeyAndHeaders(model);
      if (!auth.ok || !auth.apiKey) return;
      const accountId = getAccountId(auth.apiKey);
      if (!accountId) return;

      const response = await fetch(CODEX_USAGE_URL, {
        headers: {
          Authorization: `Bearer ${auth.apiKey}`,
          "ChatGPT-Account-Id": accountId,
        },
        signal: controller.signal,
      });
      if (!response.ok) return;
      const nextUsage = parseUsage(await response.json());
      if (requestId !== usageRequestId || controller.signal.aborted) return;
      codexUsage = nextUsage;
      requestRender?.();
    } catch (error) {
      if (!(error instanceof DOMException && error.name === "AbortError")) {
        // Usage telemetry is optional; keep the footer quiet if the private endpoint changes.
      }
    } finally {
      if (usageAbort === controller) usageAbort = undefined;
    }
  }

  pi.on("session_start", async (_event, ctx) => {
    if (ctx.mode !== "tui") return;

    activeModel = ctx.model;
    projectName = await resolveProjectName(ctx);

    ctx.ui.setFooter((tui, theme, footerData) => {
      const unsubscribe = footerData.onBranchChange(() => tui.requestRender());
      const render = () => tui.requestRender();
      requestRender = render;

      const separator = () => theme.fg("dim", SEPARATOR);
      const join = (parts: readonly string[]) => parts.filter(Boolean).join(separator());
      const usageColor = (percent: number): "success" | "warning" | "error" =>
        percent >= 90 ? "error" : percent >= 70 ? "warning" : "success";

      const contextSegment = (compact: boolean): string => {
        const usage = ctx.getContextUsage();
        const percent = usage?.percent;
        const label = theme.fg("dim", "ctx ");
        if (percent === null || percent === undefined) return `${label}${theme.fg("dim", "?")}`;

        const rounded = Math.max(0, Math.min(100, Math.round(percent)));
        if (compact) return `${label}${theme.fg(usageColor(rounded), `${rounded}%`)}`;

        const filled = Math.max(0, Math.min(BAR_WIDTH, Math.round((rounded / 100) * BAR_WIDTH)));
        const bar =
          theme.fg(usageColor(rounded), "█".repeat(filled)) +
          theme.fg("dim", "░".repeat(BAR_WIDTH - filled));
        return `${label}[${bar}] ${theme.fg(usageColor(rounded), `${rounded}%`)}`;
      };

      const limitSegment = (window: UsageWindow): string => {
        const percent = Math.round(window.usedPercent);
        return `${theme.fg("dim", `${formatWindow(window.windowSeconds)} `)}${theme.fg(
          usageColor(percent),
          `${percent}%`,
        )}`;
      };

      return {
        invalidate() {},
        dispose() {
          unsubscribe();
          if (requestRender === render) requestRender = undefined;
        },
        render(width: number): string[] {
          const branch = footerData.getGitBranch();
          const model = activeModel;
          const modelLabel = theme.fg("text", model?.id ?? "no-model");
          const thinking = model?.reasoning ? theme.fg("accent", pi.getThinkingLevel()) : "";
          const limits =
            isCodexSubscription(ctx, model) && codexUsage
              ? [limitSegment(codexUsage.primary), limitSegment(codexUsage.secondary)]
              : [];

          let showProject = Boolean(projectName);
          let showBranch = Boolean(branch);
          let showThinking = Boolean(thinking);
          let compactContext = false;

          const buildLeft = () =>
            join([
              showProject ? theme.fg("text", projectName) : "",
              showBranch && branch ? theme.fg("dim", branch) : "",
            ]);
          const buildRight = () =>
            join([
              modelLabel,
              showThinking ? thinking : "",
              contextSegment(compactContext),
              ...limits,
            ]);
          const fits = () => {
            const left = buildLeft();
            const right = buildRight();
            return visibleWidth(left) + (left ? 2 : 0) + visibleWidth(right) <= width;
          };

          if (!fits()) showProject = false;
          if (!fits()) showBranch = false;
          if (!fits()) showThinking = false;
          if (!fits()) compactContext = true;

          const left = buildLeft();
          const right = buildRight();
          const gap = left
            ? " ".repeat(Math.max(2, width - visibleWidth(left) - visibleWidth(right)))
            : "";
          const mainLine = truncateToWidth(left + gap + right, width, "");
          const lines = [mainLine];

          const statuses = [...footerData.getExtensionStatuses().entries()]
            .sort(([leftKey], [rightKey]) => leftKey.localeCompare(rightKey))
            .map(([, text]) => sanitizeStatus(text))
            .filter(Boolean);
          if (statuses.length > 0)
            lines.push(truncateToWidth(statuses.join(" "), width, theme.fg("dim", "…")));

          return lines;
        },
      };
    });

    void refreshCodexUsage(ctx);
  });

  pi.on("model_select", async (event, ctx) => {
    activeModel = event.model;
    codexUsage = undefined;
    requestRender?.();
    void refreshCodexUsage(ctx);
  });

  pi.on("thinking_level_select", () => {
    requestRender?.();
  });

  pi.on("agent_settled", async (_event, ctx) => {
    if (isCodexSubscription(ctx, activeModel)) void refreshCodexUsage(ctx);
  });

  pi.on("session_shutdown", () => {
    usageRequestId++;
    usageAbort?.abort();
    usageAbort = undefined;
    requestRender = undefined;
  });
}
