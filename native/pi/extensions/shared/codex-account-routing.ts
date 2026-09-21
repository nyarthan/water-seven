import { homedir } from "node:os";
import { isAbsolute, join, relative, resolve } from "node:path";

export const PERSONAL_CODEX_PROVIDER = "openai-codex";
export const WORK_CODEX_PROVIDER = "openai-codex-work";
export const DEFAULT_CODEX_MODEL = "gpt-5.6-sol";

export type CodexAccount = "personal" | "work";

export function codexProviderForAccount(account: CodexAccount): string {
  return account === "work" ? WORK_CODEX_PROVIDER : PERSONAL_CODEX_PROVIDER;
}

export function codexAccountForProvider(provider: string): CodexAccount | undefined {
  if (provider === PERSONAL_CODEX_PROVIDER) return "personal";
  if (provider === WORK_CODEX_PROVIDER) return "work";
  return undefined;
}

export function codexAccountForCwd(cwd: string, home = homedir()): CodexAccount {
  const workRoot = resolve(join(home, "Projects", "bettermarks"));
  const pathFromWorkRoot = relative(workRoot, resolve(cwd));
  const isInsideWorkRoot =
    pathFromWorkRoot === "" ||
    (!pathFromWorkRoot.startsWith("..") && !isAbsolute(pathFromWorkRoot));
  return isInsideWorkRoot ? "work" : "personal";
}
