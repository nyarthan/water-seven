interface UnknownRecord {
  readonly [key: string]: unknown;
}

function isRecord(value: unknown): value is UnknownRecord {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function prepareOption(value: unknown): unknown {
  if (typeof value === "string") return { label: value };
  return value;
}

function prepareQuestion(value: unknown): unknown {
  if (!isRecord(value)) return value;

  const { header, label, id, options, suggestions, multiSelect, ...rest } = value;
  if (options !== undefined && suggestions !== undefined) return value;

  const preparedHeader = header ?? label ?? id;
  const rawOptions = options ?? suggestions;
  const preparedOptions = Array.isArray(rawOptions) ? rawOptions.map(prepareOption) : rawOptions;

  return {
    ...rest,
    ...(preparedHeader === undefined ? {} : { header: preparedHeader }),
    ...(preparedOptions === undefined ? {} : { options: preparedOptions }),
    ...(multiSelect === undefined || multiSelect === false ? {} : { multiSelect }),
  };
}

/** Normalize known historical and model-familiar shapes before Pi validates the tool call. */
export function prepareAskUserQuestionArguments(args: unknown): unknown {
  if (!isRecord(args)) return args;

  if (Array.isArray(args["questions"])) {
    const { questions, ...rest } = args;
    return { ...rest, questions: questions.map(prepareQuestion) };
  }

  if (typeof args["question"] === "string") {
    return { questions: [prepareQuestion(args)] };
  }

  return args;
}
