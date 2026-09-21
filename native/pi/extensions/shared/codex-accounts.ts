import type { Provider } from "@earendil-works/pi-ai";
import { openaiCodexProvider } from "@earendil-works/pi-ai/providers/openai-codex";
import { codexProviderForAccount, type CodexAccount } from "./codex-account-routing.js";

export * from "./codex-account-routing.js";

export function createCodexProvider(account: CodexAccount): Provider<"openai-codex-responses"> {
  const provider = openaiCodexProvider();
  const id = codexProviderForAccount(account);
  const models = provider.getModels().map((model) => ({ ...model, provider: id }));

  return {
    ...provider,
    id,
    name: `OpenAI Codex (${account === "work" ? "Work" : "Personal"})`,
    getModels: () => models,
  };
}
