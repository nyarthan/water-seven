import test from "node:test";
import assert from "node:assert/strict";

import { prepareAskUserQuestionArguments } from "./shared/ask-user-question-input.ts";

test("keeps the advertised header/question/options shape", () => {
  const input = {
    questions: [
      {
        header: "Scope",
        question: "How broad should the change be?",
        options: [{ label: "Minimal", description: "Only the required behavior" }],
      },
    ],
  };

  assert.deepEqual(prepareAskUserQuestionArguments(input), input);
});

test("normalizes the legacy label and string suggestions shape", () => {
  assert.deepEqual(
    prepareAskUserQuestionArguments({
      questions: [
        {
          label: "Scope",
          question: "How broad should the change be?",
          suggestions: ["Minimal", "Complete"],
        },
      ],
    }),
    {
      questions: [
        {
          header: "Scope",
          question: "How broad should the change be?",
          options: [{ label: "Minimal" }, { label: "Complete" }],
        },
      ],
    },
  );
});

test("normalizes object suggestions without losing descriptions", () => {
  assert.deepEqual(
    prepareAskUserQuestionArguments({
      questions: [
        {
          question: "Choose an approach",
          suggestions: [{ label: "Incremental", description: "Change one boundary at a time" }],
        },
      ],
    }),
    {
      questions: [
        {
          question: "Choose an approach",
          options: [{ label: "Incremental", description: "Change one boundary at a time" }],
        },
      ],
    },
  );
});

test("uses an id as a fallback header and ignores false multiSelect", () => {
  assert.deepEqual(
    prepareAskUserQuestionArguments({
      questions: [
        {
          id: "scope",
          question: "Choose a scope",
          options: [{ label: "Focused" }],
          multiSelect: false,
        },
      ],
    }),
    {
      questions: [
        {
          header: "scope",
          question: "Choose a scope",
          options: [{ label: "Focused" }],
        },
      ],
    },
  );
});

test("wraps the historical singular question shape", () => {
  assert.deepEqual(
    prepareAskUserQuestionArguments({ question: "Continue?", suggestions: ["Yes", "No"] }),
    {
      questions: [
        {
          question: "Continue?",
          options: [{ label: "Yes" }, { label: "No" }],
        },
      ],
    },
  );
});

test("leaves unsupported multi-select semantics for schema validation to reject", () => {
  assert.deepEqual(
    prepareAskUserQuestionArguments({
      questions: [{ question: "Choose", options: [{ label: "One" }], multiSelect: true }],
    }),
    {
      questions: [{ question: "Choose", options: [{ label: "One" }], multiSelect: true }],
    },
  );
});

test("does not resolve ambiguous options and suggestions", () => {
  const input = {
    questions: [
      {
        question: "Choose",
        options: [{ label: "One" }],
        suggestions: ["Two"],
      },
    ],
  };

  assert.deepEqual(prepareAskUserQuestionArguments(input), input);
});
