import type {
  ExtensionAPI,
  ExtensionContext,
  ExtensionCommandContext,
} from "@earendil-works/pi-coding-agent";
import {
  codexAccountForCwd,
  codexAccountForProvider,
  codexProviderForAccount,
  createCodexProvider,
  DEFAULT_CODEX_MODEL,
  type CodexAccount,
} from "./shared/codex-accounts.js";

const ACCOUNT_CHOICES = ["personal", "work", "auto"] as const;
type AccountChoice = (typeof ACCOUNT_CHOICES)[number];

function parseAccountChoice(value: string): AccountChoice | undefined {
  const normalized = value.trim().toLowerCase();
  return ACCOUNT_CHOICES.find((choice) => choice === normalized);
}

function resolveAccount(choice: AccountChoice, cwd: string): CodexAccount {
  return choice === "auto" ? codexAccountForCwd(cwd) : choice;
}

async function selectAccount(ctx: ExtensionContext): Promise<CodexAccount | undefined> {
  if (ctx.mode !== "tui") return undefined;
  const selected = await ctx.ui.select("OpenAI Codex account", ["Personal", "Work", "Auto"]);
  return selected ? resolveAccount(selected.toLowerCase() as AccountChoice, ctx.cwd) : undefined;
}

async function switchAccount(
  pi: ExtensionAPI,
  ctx: ExtensionContext,
  account: CodexAccount,
): Promise<void> {
  const provider = codexProviderForAccount(account);
  if (ctx.model?.provider === provider) return;

  const modelId =
    (codexAccountForProvider(ctx.model?.provider ?? "") && ctx.model?.id) || DEFAULT_CODEX_MODEL;
  const model = ctx.modelRegistry.find(provider, modelId);
  if (!model) {
    ctx.ui.notify(`OpenAI Codex model ${provider}/${modelId} is unavailable`, "error");
    return;
  }

  if (await pi.setModel(model)) {
    ctx.ui.notify(`Using the ${account} OpenAI account`, "info");
    return;
  }

  const displayName = account === "work" ? "OpenAI Codex (Work)" : "OpenAI Codex (Personal)";
  ctx.ui.notify(
    `${displayName} is not logged in. Run /login, choose ${displayName}, then run /codex-account ${account}.`,
    "error",
  );
}

export default function codexAccounts(pi: ExtensionAPI) {
  pi.registerProvider(createCodexProvider("personal"));
  pi.registerProvider(createCodexProvider("work"));

  pi.registerFlag("codex-account", {
    description: "OpenAI Codex account: auto, personal, work, or ask",
    type: "string",
    default: "auto",
  });

  pi.registerCommand("codex-account", {
    description: "Switch between personal and work OpenAI subscriptions",
    getArgumentCompletions: (prefix) => {
      const choices = ACCOUNT_CHOICES.filter((choice) => choice.startsWith(prefix.toLowerCase()));
      return choices.length > 0
        ? choices.map((choice) => ({ value: choice, label: choice }))
        : null;
    },
    handler: async (args: string, ctx: ExtensionCommandContext) => {
      const input = args.trim();
      const account = input
        ? (() => {
            const choice = parseAccountChoice(input);
            return choice ? resolveAccount(choice, ctx.cwd) : undefined;
          })()
        : await selectAccount(ctx);

      if (!account) {
        if (input) ctx.ui.notify("Expected personal, work, or auto", "error");
        return;
      }
      await switchAccount(pi, ctx, account);
    },
  });

  pi.on("session_start", async (_event, ctx) => {
    const configured = String(pi.getFlag("codex-account") ?? "auto")
      .trim()
      .toLowerCase();
    let account: CodexAccount | undefined;

    if (configured === "ask") {
      account = await selectAccount(ctx);
      if (!account) account = codexAccountForCwd(ctx.cwd);
    } else {
      const choice = parseAccountChoice(configured);
      if (!choice) {
        ctx.ui.notify(
          `Invalid --codex-account value "${configured}"; using automatic selection`,
          "warning",
        );
      }
      account = resolveAccount(choice ?? "auto", ctx.cwd);
    }

    await switchAccount(pi, ctx, account);
  });
}
