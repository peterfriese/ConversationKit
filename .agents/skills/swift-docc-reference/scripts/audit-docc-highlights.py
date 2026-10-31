#!/usr/bin/env python3
"""
audit-docc-highlights.py

Script to audit DocC static tutorial output for Myers diff brace shifts.

DocC uses the Myers diff algorithm to generate step-by-step code highlights. Because
Myers diff operates without Swift AST / scope awareness, inserting a new block that ends
with a closing brace '}' immediately after an existing scope ending with '}' can result in
an ambiguous edit graph. The diff engine often slides the insertion upward by one line:
it highlights the preceding scope's closing brace and leaves the actual new closing brace
unhighlighted.

This script scans all tutorial JSON files in the DocC static output, identifies contiguous
highlight blocks, and verifies that no block starts on a preceding closing brace while
leaving the corresponding closing brace unhighlighted.

Exit code:
  0 - All tutorial code step highlights are clean (0 shifted braces).
  1 - Shifted braces detected or error occurred.
"""

import argparse
import json
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple


def strip_comment(line: str) -> str:
    """Removes trailing Swift comments (// ... or /* ... */) and whitespace."""
    start_block = line.find("/*")
    if start_block != -1:
        end_block = line.find("*/", start_block + 2)
        if end_block != -1:
            line = line[:start_block] + line[end_block + 2:]
    idx = line.find("//")
    if idx != -1:
        return line[:idx].strip()
    return line.strip()


def is_closing_brace(line: str) -> bool:
    """Returns True if the line consists solely of a closing brace or closure terminator."""
    cleaned = strip_comment(line)
    return cleaned in {"}", "})", "},", "});", ");", "};"}


def find_contiguous_blocks(lines: List[int]) -> List[List[int]]:
    """Groups unique sorted 1-based line numbers into contiguous integer ranges."""
    blocks: List[List[int]] = []
    current: List[int] = []
    for line in sorted(set(lines)):
        if not current or line == current[-1] + 1:
            current.append(line)
        else:
            blocks.append(current)
            current = [line]
    if current:
        blocks.append(current)
    return blocks


def _extract_inline_text(items: List[Dict[str, Any]]) -> str:
    """Recursively extracts text from DocC inline content items."""
    parts: List[str] = []
    for item in items:
        text = item.get("text", "") or item.get("code", "")
        if text:
            parts.append(text)
        if "inlineContent" in item:
            parts.append(_extract_inline_text(item["inlineContent"]))
    return "".join(parts)


def get_step_mapping(doc_data: Dict[str, Any]) -> Dict[str, Dict[str, Any]]:
    """Maps referenced code filenames to tutorial task titles, step numbers, and captions."""
    mapping: Dict[str, Dict[str, Any]] = {}
    for section in doc_data.get("sections", []):
        if section.get("kind") == "tasks":
            for task in section.get("tasks", []):
                task_title = task.get("title", "")
                for idx, step in enumerate(task.get("stepsSection", []), 1):
                    code_file = step.get("code")
                    if code_file:
                        caption_parts = []
                        for p in step.get("content", []):
                            inline = p.get("inlineContent", [])
                            if inline:
                                caption_parts.append(_extract_inline_text(inline))
                        step_data = {
                            "task_title": task_title,
                            "step_number": idx,
                            "step_caption": " ".join(caption_parts).strip(),
                        }
                        mapping[code_file] = step_data
                        mapping[Path(code_file).name] = step_data
    return mapping


def audit_tutorial_highlights(
    tutorials_dir: Path, verbose: bool = False
) -> Tuple[int, int, int, List[Dict[str, Any]]]:
    """
    Audits tutorial JSON file(s) in the given directory or file path.

    Returns:
        (total_files, total_code_refs, total_blocks, shifted_cases)
    """
    if tutorials_dir.is_file():
        json_files = [tutorials_dir] if tutorials_dir.suffix == ".json" else []
    else:
        json_files = sorted(tutorials_dir.rglob("*.json"))

    if not json_files:
        raise FileNotFoundError(f"No JSON files found in {tutorials_dir}")

    total_files = len(json_files)
    total_code_refs = 0
    total_blocks = 0
    shifted_cases: List[Dict[str, Any]] = []

    for json_path in json_files:
        if verbose:
            print(f"Auditing tutorial file: {json_path}")
        try:
            with open(json_path, "r", encoding="utf-8") as f:
                data = json.load(f)
        except Exception as e:
            print(f"Warning: Failed to parse {json_path}: {e}", file=sys.stderr)
            continue

        step_map = get_step_mapping(data)
        refs = data.get("references", {})

        for ref_id, ref_val in refs.items():
            raw_highlights = ref_val.get("highlights", [])
            if not raw_highlights:
                continue

            total_code_refs += 1
            content: List[str] = ref_val.get("content", [])
            hl_line_numbers = [
                h.get("line") for h in raw_highlights if h.get("line") is not None
            ]

            blocks = find_contiguous_blocks(hl_line_numbers)
            total_blocks += len(blocks)

            step_info = step_map.get(ref_id) or step_map.get(Path(ref_id).name, {})
            step_num = step_info.get("step_number", "Unknown")
            task_title = step_info.get("task_title", "Unknown")
            step_caption = step_info.get("step_caption", "")

            if verbose:
                print(
                    f"  Ref: {ref_id} (Step {step_num}) - {len(blocks)} highlight block(s)"
                )

            for block in blocks:
                first_line = block[0]
                last_line = block[-1]
                first_text = (
                    content[first_line - 1]
                    if 1 <= first_line <= len(content)
                    else ""
                )
                next_line_text = (
                    content[last_line] if last_line < len(content) else ""
                )

                first_is_brace = is_closing_brace(first_text)
                next_is_brace = is_closing_brace(next_line_text)

                # Myers diff shift defect occurs when a multi-line inserted block erroneously
                # starts on the preceding scope's closing brace AND omits the newly inserted closing brace.
                if len(block) >= 2 and first_is_brace and next_is_brace:
                    shifted_cases.append({
                        "json_file": json_path,
                        "ref_id": ref_id,
                        "step_number": step_num,
                        "task_title": task_title,
                        "step_caption": step_caption,
                        "block_start": first_line,
                        "block_end": last_line,
                        "erroneous_brace_line": first_line,
                        "erroneous_brace_text": first_text,
                        "omitted_brace_line": last_line + 1,
                        "omitted_brace_text": next_line_text,
                        "content": content,
                    })

    return total_files, total_code_refs, total_blocks, shifted_cases


def format_context_snippet(
    content: List[str],
    block_start: int,
    block_end: int,
    omitted_line: Optional[int],
    context_padding: int = 3,
) -> str:
    """Formats surrounding code context with visual indicators."""
    start_idx = max(1, block_start - context_padding)
    end_bound = omitted_line if omitted_line is not None else block_end
    end_idx = min(len(content), end_bound + context_padding)

    output_lines: List[str] = []
    for line_num in range(start_idx, end_idx + 1):
        line_str = content[line_num - 1]
        if line_num == block_start and is_closing_brace(line_str):
            marker = "ERR-BRACE >"
        elif block_start <= line_num <= block_end:
            marker = "       HL >"
        elif line_num == omitted_line:
            marker = "   MISSED >"
        else:
            marker = "          "
        output_lines.append(f"  {marker} {line_num:4d}: {line_str}")
    return "\n".join(output_lines)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Audit DocC static tutorial output for Myers Diff brace shifts."
    )
    parser.add_argument(
        "path",
        nargs="?",
        default=".build/docc-static/data/tutorials",
        help="Path to the DocC static tutorials data directory (default: .build/docc-static/data/tutorials)",
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="Enable verbose output",
    )
    parser.add_argument(
        "--allow-empty",
        action="store_true",
        help="Exit cleanly (status 0) if the target path does not exist or contains no tutorials",
    )

    args = parser.parse_args()
    target_path = Path(args.path)

    if not target_path.exists():
        if args.allow_empty:
            if args.verbose:
                print(f"Tutorial data path does not exist, skipping: {target_path}")
            return 0
        print(
            f"Error: Tutorial data path does not exist: {target_path}\n"
            f"Ensure static DocC documentation is compiled first (e.g., run 'just docc' or 'swift package generate-documentation').",
            file=sys.stderr,
        )
        return 1

    try:
        total_files, total_code_refs, total_blocks, shifted_cases = (
            audit_tutorial_highlights(target_path, verbose=args.verbose)
        )
    except FileNotFoundError as e:
        if args.allow_empty:
            if args.verbose:
                print(f"{e}, skipping (--allow-empty enabled).")
            return 0
        print(f"Error: {e}", file=sys.stderr)
        return 1
    except Exception as e:
        print(f"Error during audit: {e}", file=sys.stderr)
        return 1

    if shifted_cases:
        print("=" * 80, file=sys.stderr)
        print(
            f"❌ DocC Highlight Audit FAILED: {len(shifted_cases)} shifted brace defect(s) detected!",
            file=sys.stderr,
        )
        print("=" * 80, file=sys.stderr)

        for idx, case in enumerate(shifted_cases, 1):
            print(f"\n[Defect {idx}/{len(shifted_cases)}]", file=sys.stderr)
            print(f"  Tutorial File : {case['json_file'].name}", file=sys.stderr)
            print(f"  Code Reference: {case['ref_id']}", file=sys.stderr)
            print(
                f"  Location      : Step {case['step_number']} in \"{case['task_title']}\"",
                file=sys.stderr,
            )
            if case["step_caption"]:
                print(f"  Step Caption  : {case['step_caption'][:100]}...", file=sys.stderr)
            print(
                f"  Highlight Span: Lines {case['block_start']} to {case['block_end']}",
                file=sys.stderr,
            )
            print(
                f"  Problem       : Contiguous highlight begins on preceding closing brace at line {case['erroneous_brace_line']}:",
                file=sys.stderr,
            )
            print(f"                  Line {case['erroneous_brace_line']}: {case['erroneous_brace_text']}", file=sys.stderr)
            if case["omitted_brace_line"]:
                print(
                    f"                  and omits following closing brace at line {case['omitted_brace_line']}:",
                    file=sys.stderr,
                )
                print(
                    f"                  Line {case['omitted_brace_line']}: {case['omitted_brace_text']}",
                    file=sys.stderr,
                )

            print("\n  Code Context:", file=sys.stderr)
            snippet = format_context_snippet(
                case["content"],
                case["block_start"],
                case["block_end"],
                case["omitted_brace_line"],
            )
            print(snippet, file=sys.stderr)

            print("\n  Remediation:", file=sys.stderr)
            print(
                "  1. Rule of Prefix Stability: Ensure no lines above the newly added code were modified or deleted between step N and N+1.",
                file=sys.stderr,
            )
            print(
                "  2. Anchoring Intermediate Scopes: Insert a blank line after the preceding scope's closing brace.",
                file=sys.stderr,
            )
            print(
                "  3. Escape Hatches: If refactoring, use @Code(..., reset: true) or specify previousFile: explicitly.",
                file=sys.stderr,
            )

        print("\n" + "=" * 80, file=sys.stderr)
        print(
            f"FAILURE: {len(shifted_cases)} shifted brace highlight(s) require correction.",
            file=sys.stderr,
        )
        print("=" * 80, file=sys.stderr)
        return 1

    print(
        f"✓ DocC Highlight Audit: All {total_files} tutorial files verified "
        f"({total_code_refs} code steps, {total_blocks} highlight blocks). "
        f"0 shifted braces detected."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
