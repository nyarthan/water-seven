import test from "node:test";
import assert from "node:assert/strict";

import workmuxStatus, { responseRequestsInput } from "./workmux-status.ts";

const assistant = (text) => ({
  role: "assistant",
  content: [{ type: "text", text }],
});

test("a final assistant question waits for user input", () => {
  assert.equal(
    responseRequestsInput([
      assistant(
        "Would you like the broad architecture overview, or a focused analysis of the current feature branch?",
      ),
    ]),
    true,
  );
});

test("trailing Markdown does not hide a final question", () => {
  assert.equal(responseRequestsInput([assistant("Continue with **option A?**")]), true);
});

test("a completed statement remains done", () => {
  assert.equal(responseRequestsInput([assistant("The requested change is complete.")]), false);
});

test("an earlier question does not override the final statement", () => {
  assert.equal(
    responseRequestsInput([assistant("Why did this fail? The configuration was stale.")]),
    false,
  );
});

test("the last assistant message wins over tool messages", () => {
  assert.equal(
    responseRequestsInput([
      assistant("Should I continue?"),
      { role: "toolResult", content: [{ type: "text", text: "ok" }] },
    ]),
    true,
  );
});

test("status lifecycle distinguishes waiting from done", async () => {
  const handlers = new Map();
  const eventHandlers = new Map();
  const statuses = [];
  const context = {
    isIdle: () => true,
    sessionManager: { getBranch: () => [] },
  };
  const pi = {
    on(event, handler) {
      handlers.set(event, handler);
    },
    async exec(_command, args) {
      if (args[0] === "set-window-status") statuses.push(args[1]);
      return { code: 0, stdout: "", stderr: "" };
    },
    events: {
      on(event, handler) {
        eventHandlers.set(event, handler);
        return () => eventHandlers.delete(event);
      },
      emit() {},
    },
  };

  workmuxStatus(pi);

  await handlers.get("session_start")({}, context);
  await handlers.get("agent_start")();
  assert.equal(statuses.at(-1), "working");

  await handlers.get("ui_prompt_start")();
  assert.equal(statuses.at(-1), "waiting");
  await handlers.get("ui_prompt_end")();
  assert.equal(statuses.at(-1), "working");

  await handlers.get("agent_end")({ messages: [assistant("Should I continue?")] });
  await handlers.get("agent_settled")({}, context);
  assert.equal(statuses.at(-1), "waiting");

  await handlers.get("agent_start")();
  await handlers.get("agent_end")({ messages: [assistant("Everything is complete.")] });
  await handlers.get("agent_settled")({}, context);
  assert.equal(statuses.at(-1), "done");

  await handlers.get("session_shutdown")();
});
