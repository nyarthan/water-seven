#!/usr/bin/env python3
"""Emit bounded process evidence from a Markdown-wrapped Claude JSONL transcript."""

from __future__ import annotations

import argparse
import json
import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any


CORRECTION_RE = re.compile(
    r"\b(?:actually|correction|instead|wrong|don't|do not|not that|please stop|should be|meant|make sure)\b",
    re.IGNORECASE,
)
ERROR_RE = re.compile(r"\b(?:error|failed|failure|invalid|not found|permission denied|timed out)\b", re.IGNORECASE)
PATH_RE = re.compile(r"(?<![\w])(?:~/|\.\./|/(?:Users|home|mnt)/)[^\s`'\"<>]+")
WRITE_TOOLS = {"Edit", "Write", "MultiEdit", "NotebookEdit"}
SHELL_TOOLS = {"Bash", "Shell", "exec_command"}


def clean(value: str, limit: int) -> str:
    value = re.sub(r"\s+", " ", value).strip()
    if len(value) <= limit:
        return value
    return value[: max(0, limit - 1)].rstrip() + "…"


def user_text(message: Any) -> str:
    if not isinstance(message, dict):
        return ""
    content = message.get("content")
    if isinstance(content, str):
        return content
    if not isinstance(content, list):
        return ""
    # Attachments and tool results are source payloads, not user prompts.
    return "\n".join(
        block.get("text", "")
        for block in content
        if isinstance(block, dict) and block.get("type") == "text"
    )


def assistant_blocks(message: Any) -> list[dict[str, Any]]:
    if not isinstance(message, dict):
        return []
    content = message.get("content")
    if isinstance(content, str):
        return [{"type": "text", "text": content}]
    if isinstance(content, list):
        return [block for block in content if isinstance(block, dict)]
    return []


def tool_target(name: str, tool_input: Any, limit: int) -> str:
    if not isinstance(tool_input, dict):
        return ""
    for key in ("file_path", "path", "notebook_path"):
        value = tool_input.get(key)
        if isinstance(value, str):
            return clean(value, limit)
    if name in SHELL_TOOLS:
        command = tool_input.get("command") or tool_input.get("cmd")
        if isinstance(command, str):
            return clean(command, limit)
    return ""


@dataclass
class Sample:
    metadata: list[str] = field(default_factory=list)
    metadata_issues: list[tuple[int, str]] = field(default_factory=list)
    prompts: list[tuple[int, str]] = field(default_factory=list)
    corrections: list[tuple[int, str]] = field(default_factory=list)
    process_text: list[tuple[int, str]] = field(default_factory=list)
    writes: list[tuple[int, str]] = field(default_factory=list)
    pointer_candidates: list[tuple[int, str]] = field(default_factory=list)
    git_actions: list[tuple[int, str]] = field(default_factory=list)
    errors: list[tuple[int, str]] = field(default_factory=list)
    final_text: tuple[int, str] | None = None
    json_events: int = 0
    parse_errors: int = 0
    frontmatter_outcome: str = ""
    legacy_outcome: str = ""
    legacy_outcome_line: int = 0


def parse_wrapper(path: Path, max_items: int, max_chars: int) -> Sample:
    sample = Sample()
    in_jsonl = False
    with path.open("r", encoding="utf-8", errors="replace") as handle:
        for line_number, raw_line in enumerate(handle, 1):
            if not in_jsonl:
                stripped = raw_line.rstrip("\n")
                if stripped == "```jsonl":
                    in_jsonl = True
                    continue
                if stripped.startswith("outcome:"):
                    sample.frontmatter_outcome = stripped.partition(":")[2].strip()
                    sample.metadata.append(f"Frontmatter outcome: {sample.frontmatter_outcome or '<empty>'}")
                elif stripped.startswith("- Outcome:"):
                    sample.legacy_outcome = stripped.partition(":")[2].strip()
                    sample.legacy_outcome_line = line_number
                elif stripped.startswith(("- Agent/tool:", "- Goal:", "- Session ID:", "- Date range:", "- Messages:", "- First prompt:")):
                    sample.metadata.append(stripped)
                continue

            stripped = raw_line.strip()
            if stripped == "```":
                break
            if not stripped:
                continue
            sample.json_events += 1
            try:
                event = json.loads(stripped)
            except json.JSONDecodeError:
                sample.parse_errors += 1
                continue

            event_type = event.get("type")
            if event_type == "user":
                # Claude serializes commands, task notifications, and local-command
                # annotations as user events too. Only human-typed prompts are evidence.
                text = ""
                if event.get("promptSource") == "typed":
                    text = clean(user_text(event.get("message")), max_chars)
                    if text and len(sample.prompts) < max_items:
                        sample.prompts.append((line_number, text))
                    if text and CORRECTION_RE.search(text) and len(sample.corrections) < max_items:
                        sample.corrections.append((line_number, text))

                result = event.get("toolUseResult")
                if isinstance(result, dict):
                    result_text = clean(str(result.get("content") or result.get("stderr") or ""), max_chars)
                    if result_text and ERROR_RE.search(result_text) and len(sample.errors) < max_items:
                        sample.errors.append((line_number, result_text))

            if event_type != "assistant":
                continue

            for block in assistant_blocks(event.get("message")):
                block_type = block.get("type")
                if block_type == "text":
                    text = clean(str(block.get("text", "")), max_chars)
                    if text:
                        sample.final_text = (line_number, text)
                        if len(sample.process_text) < max_items:
                            sample.process_text.append((line_number, text))
                elif block_type == "tool_use":
                    name = str(block.get("name", "unknown"))
                    tool_input = block.get("input")
                    target = tool_target(name, tool_input, max_chars)
                    rendered = clean(f"{name}: {target}" if target else name, max_chars)
                    if name in WRITE_TOOLS and len(sample.writes) < max_items:
                        sample.writes.append((line_number, rendered))
                    if name in WRITE_TOOLS and isinstance(tool_input, dict):
                        body = "\n".join(
                            str(tool_input.get(key, "")) for key in ("content", "new_string")
                        )
                        for match in PATH_RE.finditer(body):
                            if len(sample.pointer_candidates) >= max_items:
                                break
                            candidate = match.group(0).rstrip(".,;:)]}")
                            sample.pointer_candidates.append(
                                (line_number, clean(f"{rendered} contains `{candidate}`", max_chars))
                            )
                    if name in SHELL_TOOLS and re.search(r"(?:^|\s)git\s", target) and len(sample.git_actions) < max_items:
                        sample.git_actions.append((line_number, rendered))

    if sample.legacy_outcome and sample.legacy_outcome != sample.frontmatter_outcome:
        sample.metadata_issues.append(
            (
                sample.legacy_outcome_line,
                "Legacy Metadata outcome "
                f"`{sample.legacy_outcome}` disagrees with authoritative frontmatter "
                f"`{sample.frontmatter_outcome or '<empty>'}`.",
            )
        )
    return sample


def section(title: str, items: list[tuple[int, str]]) -> list[str]:
    output = [f"## {title}", ""]
    if not items:
        return output + ["- None observed in the bounded sample.", ""]
    output.extend(f"- L{line}: {text}" for line, text in items)
    output.append("")
    return output


def render(path: Path, sample: Sample, max_items: int, max_chars: int) -> str:
    lines = [
        "# Bounded process-trace sample",
        "",
        f"- Wrapper: `{path}`",
        f"- Size: {path.stat().st_size} bytes",
        f"- JSONL events scanned programmatically: {sample.json_events}",
        f"- JSON parse errors: {sample.parse_errors}",
        f"- Output bounds: {max_items} items/category, {max_chars} characters/item",
        "- Source attachments and tool-result payloads: suppressed",
        "",
        "## Wrapper metadata",
        "",
    ]
    lines.extend(f"- {item}" for item in sample.metadata)
    if not sample.metadata:
        lines.append("- None found.")
    lines.append("")
    lines.extend(section("Wrapper metadata consistency", sample.metadata_issues))
    lines.extend(section("Typed user prompts", sample.prompts))
    lines.extend(section("Correction or constraint candidates", sample.corrections))
    lines.extend(section("Assistant process statements", sample.process_text))
    lines.extend(section("Write and edit targets", sample.writes))
    lines.extend(section("External-path pointer candidates in writes", sample.pointer_candidates))
    lines.extend(section("Version-control actions", sample.git_actions))
    lines.extend(section("Error candidates", sample.errors))
    lines.extend(section("Final assistant text", [sample.final_text] if sample.final_text else []))
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("wrapper", type=Path)
    parser.add_argument("--max-items", type=int, default=12)
    parser.add_argument("--max-chars", type=int, default=280)
    args = parser.parse_args()
    if args.max_items < 1 or args.max_chars < 40:
        parser.error("--max-items must be positive and --max-chars must be at least 40")
    if not args.wrapper.is_file():
        parser.error(f"wrapper not found: {args.wrapper}")
    sample = parse_wrapper(args.wrapper, args.max_items, args.max_chars)
    print(render(args.wrapper.resolve(), sample, args.max_items, args.max_chars))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
