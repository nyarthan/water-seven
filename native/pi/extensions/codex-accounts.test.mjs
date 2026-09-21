import test from "node:test";
import assert from "node:assert/strict";

import {
  codexAccountForCwd,
  codexAccountForProvider,
  codexProviderForAccount,
  PERSONAL_CODEX_PROVIDER,
  WORK_CODEX_PROVIDER,
} from "./shared/codex-account-routing.ts";

const home = "/Users/test";

test("bettermarks and its descendants use the work account", () => {
  assert.equal(codexAccountForCwd(`${home}/Projects/bettermarks`, home), "work");
  assert.equal(codexAccountForCwd(`${home}/Projects/bettermarks/product/repository`, home), "work");
});

test("similarly named and unrelated directories use the personal account", () => {
  assert.equal(codexAccountForCwd(`${home}/Projects/bettermarks-old`, home), "personal");
  assert.equal(codexAccountForCwd(`${home}/Projects/water-seven`, home), "personal");
});

test("account provider mappings round trip", () => {
  assert.equal(codexProviderForAccount("personal"), PERSONAL_CODEX_PROVIDER);
  assert.equal(codexProviderForAccount("work"), WORK_CODEX_PROVIDER);
  assert.equal(codexAccountForProvider(PERSONAL_CODEX_PROVIDER), "personal");
  assert.equal(codexAccountForProvider(WORK_CODEX_PROVIDER), "work");
  assert.equal(codexAccountForProvider("anthropic"), undefined);
});
