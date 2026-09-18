import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import {
  decodeKittyPrintable,
  Editor,
  type EditorTheme,
  Key,
  matchesKey,
  Text,
  truncateToWidth,
  visibleWidth,
  wrapTextWithAnsi,
} from "@earendil-works/pi-tui";
import { Effect, Schema } from "effect";
import { icons } from "./shared/icons.js";

const SuggestedAnswer = Schema.NonEmptyString.annotate({
  description: "A concise answer that the user is likely to choose verbatim",
});

const Question = Schema.Struct({
  label: Schema.optionalKey(
    Schema.NonEmptyString.annotate({
      description: "A short tab label, such as 'Scope' or 'Database'",
    }),
  ),
  question: Schema.NonEmptyString.annotate({
    description: "The specific question to show the user",
  }),
  suggestions: Schema.optionalKey(
    Schema.Array(SuggestedAnswer).check(Schema.isMaxLength(8)).annotate({
      description:
        "Suggested answers. Omit this unless the choices are genuinely useful and the user is more likely to choose one than write a different answer.",
    }),
  ),
});

const AskUserQuestions = Schema.Struct({
  questions: Schema.NonEmptyArray(Question).check(Schema.isMaxLength(8)).annotate({
    description:
      "Questions that should be answered together. Use one item for a single question and multiple items only when answering them in one pass is valuable.",
  }),
});

type AskUserQuestions = Schema.Schema.Type<typeof AskUserQuestions>;
type Question = Schema.Schema.Type<typeof Question>;

// Pi's tool API infers an unsafe JSON Schema through this structural marker.
// Effect Schema remains the source of truth for generation and runtime decoding.
interface ToolParameters {
  readonly "~unsafe": AskUserQuestions;
}
const parameters = Schema.toJsonSchemaDocument(AskUserQuestions)
  .schema as unknown as ToolParameters;

interface Answer {
  readonly questionIndex: number;
  readonly label: string;
  readonly answer: string;
  readonly suggestionIndex?: number;
}

interface AnswerDetails {
  readonly questions: ReadonlyArray<{
    readonly label: string;
    readonly question: string;
    readonly suggestions: ReadonlyArray<string>;
  }>;
  readonly answers: ReadonlyArray<Answer>;
  readonly cancelled: boolean;
}

type DialogResult =
  | { readonly _tag: "Submitted"; readonly answers: ReadonlyArray<Answer> }
  | { readonly _tag: "Cancelled"; readonly answers: ReadonlyArray<Answer> };

const FREE_FORM_LABEL = "Type your own answer";
const SUBMIT_GROUP_KEY = Key.ctrl("y");

export default function askUserQuestion(pi: ExtensionAPI) {
  pi.registerTool<ToolParameters, AnswerDetails>({
    name: "ask_user_question",
    label: "Ask User Question",
    description:
      "Ask the user one or more related questions when their input is needed to continue. Group questions only when answering them together is useful. Suggested answers are optional: provide them only when valuable and likely to be chosen over free text. Free-form input is always available.",
    promptSnippet:
      "Ask the user one or more related questions, optionally with high-value suggestions",
    promptGuidelines: [
      "Use ask_user_question when user input is required before continuing.",
      "For ask_user_question, group multiple questions only when answering them together is more convenient than asking separately.",
      "For ask_user_question, omit suggestions unless they are genuinely valuable and the user is more likely to choose one verbatim than provide a free-text answer.",
    ],
    parameters,
    prepareArguments(args) {
      if (!args || typeof args !== "object") return args as AskUserQuestions;
      const input = args as {
        questions?: ReadonlyArray<Question>;
        question?: string;
        suggestions?: ReadonlyArray<string>;
      };
      if (input.questions) return input as AskUserQuestions;
      if (typeof input.question === "string") {
        const question: Question = input.suggestions
          ? { question: input.question, suggestions: input.suggestions }
          : { question: input.question };
        return { questions: [question] };
      }
      return args as AskUserQuestions;
    },
    executionMode: "sequential",

    execute(_toolCallId, untrustedParams, _signal, _onUpdate, ctx) {
      return Effect.runPromise(
        Effect.gen(function* () {
          const params = yield* Schema.decodeUnknownEffect(AskUserQuestions)(untrustedParams);
          const questions = params.questions.map((question, index) => ({
            label: question.label ?? `Q${index + 1}`,
            question: question.question,
            suggestions: [...(question.suggestions ?? [])],
          }));

          if (ctx.mode !== "tui") {
            return {
              content: [
                {
                  type: "text" as const,
                  text: "Cannot ask the user: interactive TUI mode is not available.",
                },
              ],
              details: { questions, answers: [], cancelled: true },
            };
          }

          const result = yield* Effect.promise(() =>
            ctx.ui.custom<DialogResult>((tui, theme, _keybindings, done) => {
              const isMulti = questions.length > 1;
              let currentTab = 0;
              let inputMode = questions[0]!.suggestions.length === 0;
              let focused = false;
              let validationMessage: string | undefined;
              let cachedWidth: number | undefined;
              let cachedLines: string[] | undefined;
              const selectedIndices = questions.map((question) =>
                question.suggestions.length === 0 ? question.suggestions.length : 0,
              );
              const drafts = questions.map(() => "");
              const answers: Array<Answer | undefined> = questions.map(() => undefined);

              const editorTheme: EditorTheme = {
                borderColor: (text) => theme.fg("accent", text),
                selectList: {
                  selectedPrefix: (text) => theme.fg("accent", text),
                  selectedText: (text) => theme.fg("accent", text),
                  description: (text) => theme.fg("muted", text),
                  scrollInfo: (text) => theme.fg("dim", text),
                  noMatch: (text) => theme.fg("warning", text),
                },
              };
              const editor = new Editor(tui, editorTheme, { paddingX: 0 });

              const refresh = () => {
                cachedWidth = undefined;
                cachedLines = undefined;
                tui.requestRender();
              };

              const currentQuestion = () => questions[currentTab]!;
              const freeFormIndex = () => currentQuestion().suggestions.length;
              const completedAnswers = () => answers.filter((answer): answer is Answer => !!answer);

              const enterInputMode = (initialText?: string) => {
                selectedIndices[currentTab] = freeFormIndex();
                inputMode = true;
                validationMessage = undefined;
                editor.focused = focused;
                const existing = answers[currentTab];
                const value =
                  initialText ??
                  drafts[currentTab] ??
                  (existing?.suggestionIndex ? "" : (existing?.answer ?? ""));
                editor.setText(value);
                refresh();
              };

              const switchTab = (nextTab: number) => {
                if (inputMode) drafts[currentTab] = editor.getText();
                currentTab = (nextTab + questions.length) % questions.length;
                validationMessage = undefined;
                inputMode = currentQuestion().suggestions.length === 0;
                const answer = answers[currentTab];
                const customAnswer =
                  answer && answer.suggestionIndex === undefined ? answer.answer : "";
                editor.setText(drafts[currentTab] || customAnswer);
                editor.focused = focused && inputMode;
                refresh();
              };

              const advance = () => {
                if (!isMulti) {
                  done({ _tag: "Submitted", answers: completedAnswers() });
                  return;
                }
                const nextUnanswered = answers.findIndex(
                  (answer, index) => index > currentTab && answer === undefined,
                );
                if (nextUnanswered >= 0) switchTab(nextUnanswered);
                else if (currentTab < questions.length - 1) switchTab(currentTab + 1);
                else {
                  inputMode = false;
                  editor.focused = false;
                  refresh();
                }
              };

              const saveSuggested = (index: number) => {
                const question = currentQuestion();
                answers[currentTab] = {
                  questionIndex: currentTab + 1,
                  label: question.label,
                  answer: question.suggestions[index]!,
                  suggestionIndex: index + 1,
                };
                selectedIndices[currentTab] = index;
                drafts[currentTab] = "";
                validationMessage = undefined;
                advance();
              };

              const saveFreeForm = (answer: string) => {
                const question = currentQuestion();
                const value = answer.trim();
                drafts[currentTab] = value;
                answers[currentTab] = {
                  questionIndex: currentTab + 1,
                  label: question.label,
                  answer: value,
                };
                selectedIndices[currentTab] = question.suggestions.length;
                inputMode = false;
                editor.focused = false;
                validationMessage = undefined;
                advance();
              };

              const submitGroup = () => {
                if (inputMode) saveFreeForm(editor.getText());
                if (answers.every(Boolean)) {
                  done({ _tag: "Submitted", answers: completedAnswers() });
                } else {
                  const remaining = answers.filter((answer) => !answer).length;
                  validationMessage = `${remaining} question${remaining === 1 ? "" : "s"} still unanswered`;
                  refresh();
                }
              };

              editor.onSubmit = saveFreeForm;

              const choose = (index: number) => {
                if (index === freeFormIndex()) enterInputMode();
                else saveSuggested(index);
              };

              const handleInput = (data: string) => {
                if (isMulti && matchesKey(data, SUBMIT_GROUP_KEY)) {
                  submitGroup();
                  return;
                }

                if (inputMode) {
                  if (isMulti && matchesKey(data, Key.tab)) {
                    switchTab(currentTab + 1);
                    return;
                  }
                  if (isMulti && matchesKey(data, Key.shift("tab"))) {
                    switchTab(currentTab - 1);
                    return;
                  }
                  if (matchesKey(data, Key.escape)) {
                    if (!isMulti && currentQuestion().suggestions.length === 0) {
                      done({ _tag: "Cancelled", answers: completedAnswers() });
                    } else {
                      drafts[currentTab] = editor.getText();
                      inputMode = false;
                      editor.focused = false;
                      refresh();
                    }
                    return;
                  }
                  editor.handleInput(data);
                  drafts[currentTab] = editor.getText();
                  refresh();
                  return;
                }

                if (isMulti && (matchesKey(data, Key.tab) || matchesKey(data, Key.right))) {
                  switchTab(currentTab + 1);
                  return;
                }
                if (isMulti && (matchesKey(data, Key.shift("tab")) || matchesKey(data, Key.left))) {
                  switchTab(currentTab - 1);
                  return;
                }
                if (matchesKey(data, Key.up)) {
                  const count = currentQuestion().suggestions.length + 1;
                  selectedIndices[currentTab] = (selectedIndices[currentTab]! - 1 + count) % count;
                  refresh();
                  return;
                }
                if (matchesKey(data, Key.down)) {
                  const count = currentQuestion().suggestions.length + 1;
                  selectedIndices[currentTab] = (selectedIndices[currentTab]! + 1) % count;
                  refresh();
                  return;
                }
                if (matchesKey(data, Key.enter)) {
                  choose(selectedIndices[currentTab]!);
                  return;
                }
                if (matchesKey(data, Key.escape)) {
                  done({ _tag: "Cancelled", answers: completedAnswers() });
                  return;
                }

                const printable =
                  decodeKittyPrintable(data) ??
                  (data.length === 1 && data.charCodeAt(0) >= 32 ? data : undefined);
                if (printable?.length === 1 && /^[a-z]$/i.test(printable)) {
                  enterInputMode(printable);
                  return;
                }
                if (printable?.length === 1 && printable >= "1" && printable <= "9") {
                  const index = Number(printable) - 1;
                  if (index <= freeFormIndex()) choose(index);
                }
              };

              const render = (width: number): string[] => {
                if (cachedLines && cachedWidth === width) return cachedLines;

                const renderWidth = Math.max(1, width);
                const lines: string[] = [];
                const question = currentQuestion();
                const addWrapped = (prefix: string, text: string) => {
                  const prefixWidth = visibleWidth(prefix);
                  if (prefixWidth >= renderWidth) {
                    lines.push(...wrapTextWithAnsi(prefix + text, renderWidth));
                    return;
                  }
                  const wrapped = wrapTextWithAnsi(text, renderWidth - prefixWidth);
                  const continuation = " ".repeat(prefixWidth);
                  wrapped.forEach((line, index) =>
                    lines.push(`${index === 0 ? prefix : continuation}${line}`),
                  );
                };

                if (isMulti) {
                  const availableWidth = Math.max(1, renderWidth - 2);
                  const tabs = questions.map((item, index) => {
                    const active = index === currentTab;
                    const answered = answers[index] !== undefined;
                    const maxTabWidth = Math.max(1, Math.min(24, availableWidth));
                    const tabWidth = Math.min(
                      Math.max(8, visibleWidth(item.label) + 7),
                      maxTabWidth,
                    );
                    const labelWidth = Math.max(1, tabWidth - 7);
                    const labelText = truncateToWidth(item.label, labelWidth, "…");
                    const number = theme.fg(active ? "accent" : "dim", `${index + 1}`);
                    const label = active
                      ? theme.fg("accent", theme.bold(labelText))
                      : theme.fg(answered ? "text" : "muted", labelText);
                    const status = answered
                      ? theme.fg("success", icons.statusAnswered)
                      : theme.fg("dim", icons.statusUnanswered);
                    const title =
                      tabWidth < 8
                        ? truncateToWidth(` ${number}`, tabWidth, "")
                        : ` ${number} ${label} ${status}  `;
                    const paddedTitle =
                      title + " ".repeat(Math.max(0, tabWidth - visibleWidth(title)));
                    return {
                      width: tabWidth,
                      title: active ? theme.bg("toolPendingBg", paddedTitle) : paddedTitle,
                    };
                  });

                  let row: typeof tabs = [];
                  let rowWidth = 0;
                  const flushRow = () => {
                    if (row.length === 0) return;
                    lines.push(` ${row.map((tab) => tab.title).join(" ")}`);
                    row = [];
                    rowWidth = 0;
                  };

                  for (const tab of tabs) {
                    const nextWidth = rowWidth + (row.length === 0 ? 0 : 1) + tab.width;
                    if (row.length > 0 && nextWidth > availableWidth) flushRow();
                    row.push(tab);
                    rowWidth += (row.length === 1 ? 0 : 1) + tab.width;
                  }
                  flushRow();
                }

                const panelStart = lines.length;
                lines.push("");
                addWrapped(" ", theme.fg("accent", theme.bold(question.question)));
                lines.push("");

                question.suggestions.forEach((suggestion, index) => {
                  const selected = selectedIndices[currentTab] === index;
                  const number = theme.fg(selected ? "accent" : "dim", `${index + 1}. `);
                  const label = selected
                    ? theme.fg("accent", theme.bold(suggestion))
                    : theme.fg("text", suggestion);
                  addWrapped("  ", number + label);
                });

                const otherIndex = question.suggestions.length;
                const freeFormSelected = selectedIndices[currentTab] === otherIndex;
                if (inputMode) {
                  const prefix = `  ${theme.fg("accent", `${otherIndex + 1}. `)}`;
                  const prefixWidth = visibleWidth(prefix);
                  if (prefixWidth >= renderWidth) {
                    lines.push(truncateToWidth(prefix, renderWidth));
                    lines.push(...editor.render(renderWidth).slice(1, -1));
                  } else {
                    const editorLines = editor.render(renderWidth - prefixWidth).slice(1, -1);
                    const continuation = " ".repeat(prefixWidth);
                    editorLines.forEach((line, index) =>
                      lines.push(`${index === 0 ? prefix : continuation}${line}`),
                    );
                  }
                } else {
                  const number = theme.fg(
                    freeFormSelected ? "accent" : "dim",
                    `${otherIndex + 1}. `,
                  );
                  const existing = answers[currentTab];
                  const customAnswer =
                    existing?.suggestionIndex === undefined ? existing?.answer : undefined;
                  const text = customAnswer || `${FREE_FORM_LABEL}…`;
                  const label = freeFormSelected
                    ? theme.fg("accent", theme.bold(text))
                    : theme.fg(customAnswer ? "text" : "muted", text);
                  addWrapped("  ", number + label);
                }

                lines.push("");
                if (validationMessage) {
                  addWrapped(" ", theme.fg("warning", validationMessage));
                  lines.push("");
                }

                for (let index = panelStart; index < lines.length; index++) {
                  const line = truncateToWidth(lines[index]!, renderWidth, "");
                  const padding = " ".repeat(Math.max(0, renderWidth - visibleWidth(line)));
                  lines[index] = theme.bg("toolPendingBg", line + padding);
                }

                const hint = (key: string, description: string) =>
                  theme.fg("dim", key) + theme.fg("muted", ` ${description}`);
                const help = inputMode
                  ? [hint("enter", "answer"), hint("shift+enter", "new line"), hint("esc", "back")]
                  : [
                      hint("↑↓", "navigate"),
                      hint("enter", "answer"),
                      hint("1–9", "quick select"),
                      hint("a–z", "write"),
                    ];
                if (isMulti) {
                  help.push(hint("tab/shift+tab", "questions"), hint("ctrl+y", "submit all"));
                } else {
                  help.push(hint("esc", "cancel"));
                }
                addWrapped(" ", help.join("  "));
                lines.push("");

                cachedWidth = width;
                cachedLines = lines;
                return lines;
              };

              return {
                get focused() {
                  return focused;
                },
                set focused(value: boolean) {
                  focused = value;
                  editor.focused = value && inputMode;
                },
                handleInput,
                render,
                invalidate() {
                  cachedWidth = undefined;
                  cachedLines = undefined;
                  editor.invalidate();
                },
              };
            }),
          );

          const cancelled = result._tag === "Cancelled";
          const answerLines = result.answers.map((answer) => {
            const value = answer.suggestionIndex
              ? `selected ${answer.suggestionIndex}. ${answer.answer}`
              : `answered freely: ${answer.answer}`;
            return `${answer.label}: ${value}`;
          });

          return {
            content: [
              {
                type: "text" as const,
                text: cancelled
                  ? `The user cancelled the questions.${answerLines.length ? `\nPartial answers:\n${answerLines.join("\n")}` : ""}`
                  : answerLines.join("\n"),
              },
            ],
            details: { questions, answers: result.answers, cancelled },
          };
        }),
      );
    },

    renderCall(args, theme) {
      const count = args.questions.length;
      const summary = count === 1 ? args.questions[0]!.question : `${count} related questions`;
      return new Text(
        theme.fg("toolTitle", theme.bold("ask_user_question ")) + theme.fg("muted", summary),
        0,
        0,
      );
    },

    renderResult(result, _options, theme) {
      if (result.details.cancelled) {
        return new Text(theme.fg("warning", "Cancelled"), 0, 0);
      }
      const lines = result.details.answers.map((answer) => {
        const value = answer.suggestionIndex
          ? `${answer.suggestionIndex}. ${answer.answer}`
          : answer.answer;
        return `${theme.fg("success", `${icons.statusAnswered} `)}${theme.fg("muted", `${answer.label}: `)}${theme.fg("accent", value)}`;
      });
      return new Text(lines.join("\n"), 0, 0);
    },
  });
}
