"""PostToolUse hook for file edits.

Records the edit for the Stop check, then checks the written code against the
engineering standards: function comments, bug-fix comments, hardcoded secrets,
and shellcheck for shell scripts. Exits with code 2 so Claude fixes problems.
"""

import ast
import os
import re
import shutil
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from standards_common import classify, find_secret, project_dir, read_payload, touch  # noqa: E402

JS_KEYWORDS = r"(?!(?:if|for|while|switch|catch|return|function|else|do|try|with|new|typeof|await)\b)"
FUNCTION_PATTERNS = {
    (".js", ".jsx", ".mjs", ".cjs", ".ts", ".tsx"): [
        re.compile(r"^\s*(export\s+)?(default\s+)?(async\s+)?function\s*\*?\s*[\w$]+\s*[<(]"),
        re.compile(r"^\s*(export\s+)?(const|let|var)\s+[\w$]+\s*(:[^=]+)?=\s*(async\s+)?(\([^)]*\)|[\w$]+)\s*(:[^=]+)?=>"),
        re.compile(r"^\s*(public\s+|private\s+|protected\s+|static\s+|async\s+|readonly\s+|get\s+|set\s+)*"
                   + JS_KEYWORDS + r"[\w$]+\s*(<[^>]*>)?\([^)]*\)\s*(:\s*[^={]+)?\{\s*$"),
    ],
    (".go",): [re.compile(r"^func\s")],
    (".rs",): [re.compile(r"^\s*(pub(\([\w:]+\))?\s+)?(const\s+)?(async\s+)?(unsafe\s+)?(extern\s+\"\w+\"\s+)?fn\s+\w+")],
    (".sh", ".bash", ".zsh"): [re.compile(r"^\s*(function\s+)?[A-Za-z_][\w-]*\s*\(\)\s*\{?\s*$"),
                               re.compile(r"^\s*function\s+[A-Za-z_][\w-]*\s*\{?\s*$")],
    (".java", ".cs"): [re.compile(r"^\s*(public|private|protected|internal)\s+[\w<>\[\],.?\s]*\s[\w$]+\s*\([^;]*$")],
    (".kt", ".kts"): [re.compile(r"^\s*(\w+\s+)*fun\s+")],
    (".rb",): [re.compile(r"^\s*def\s+")],
    (".php",): [re.compile(r"^\s*((public|private|protected|static|abstract|final)\s+)*function\s+\w+")],
    (".swift",): [re.compile(r"^\s*(\w+\s+)*func\s+")],
}
COMMENT_START = re.compile(r"^\s*(#|//|/\*|\*|--|<!--|\"\"\"|''')")
DECORATOR = re.compile(r"^\s*(@|#\[)")
BUG_FIX_COMMENT = re.compile(
    r"(?i)\b(fix(e[sd])?\s+(for\s+)?(the\s+)?(bug|issue)|bug\s*#?\d+|issue\s*#\d+|workaround\s+for|"
    r"hack\b|as\s+requested|per\s+(the\s+)?user|temporary\s+fix|quick\s+fix)"
)


def written_ranges(tool_input, content):
    """Return the set of 1-based line numbers in the file that this edit wrote.

    Write covers the whole file. Edit and MultiEdit cover every place where
    their new text now appears.
    """
    if "content" in tool_input:
        return set(range(1, content.count("\n") + 2))
    fragments = [tool_input.get("new_string", "")]
    fragments += [edit.get("new_string", "") for edit in tool_input.get("edits", [])]
    lines = set()
    for fragment in filter(None, fragments):
        start = content.find(fragment)
        while start != -1:
            first = content.count("\n", 0, start) + 1
            lines.update(range(first, first + fragment.count("\n") + 1))
            start = content.find(fragment, start + 1)
    return lines


def has_comment_above(lines, index):
    """Return True when a comment sits directly above line index (0-based).

    Decorator and attribute lines between the comment and the definition are
    skipped.
    """
    index -= 1
    while index >= 0 and DECORATOR.match(lines[index]):
        index -= 1
    return index >= 0 and bool(COMMENT_START.match(lines[index]) or lines[index].rstrip().endswith("*/"))


def undocumented_python(content, ranges):
    """Return (line, name) for written Python functions with no docstring or comment."""
    try:
        tree = ast.parse(content)
    except SyntaxError:
        return []
    lines = content.splitlines()
    missing = []
    for node in ast.walk(tree):
        if not isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)) or node.lineno not in ranges:
            continue
        first = min([node.lineno] + [d.lineno for d in node.decorator_list])
        if ast.get_docstring(node) is None and not has_comment_above(lines, first - 1):
            missing.append((node.lineno, node.name))
    return missing


def undocumented_other(path, content, ranges):
    """Return (line, text) for written functions in other languages with no comment above."""
    patterns = next((p for exts, p in FUNCTION_PATTERNS.items() if path.endswith(exts)), None)
    if patterns is None:
        return []
    lines = content.splitlines()
    missing = []
    for number in sorted(ranges):
        line = lines[number - 1] if number <= len(lines) else ""
        if any(p.match(line) for p in patterns) and not has_comment_above(lines, number - 1):
            missing.append((number, line.strip()[:80]))
    return missing


def shellcheck(path):
    """Run shellcheck on a shell script and return its findings as lines."""
    if not shutil.which("shellcheck"):
        return []
    result = subprocess.run(["shellcheck", "-f", "gcc", "-S", "warning", path],
                            capture_output=True, text=True, check=False)
    return result.stdout.splitlines()[:20]


def main():
    """Record the edit, check the written code, and report problems to Claude."""
    payload = read_payload()
    tool_input = payload.get("tool_input", {})
    path = tool_input.get("file_path", "")
    kind = classify(path, project_dir(payload)) if path else "exempt"
    if kind == "doc":
        touch(payload, "last_doc_edit")
    if kind != "code" or not os.path.isfile(path):
        return 0
    touch(payload, "last_edit")
    with open(path, encoding="utf-8", errors="replace") as handle:
        content = handle.read()
    ranges = written_ranges(tool_input, content)
    lines = content.splitlines()
    written = "\n".join(lines[n - 1] for n in sorted(ranges) if n <= len(lines))

    problems = []
    missing = undocumented_python(content, ranges) if path.endswith(".py") else undocumented_other(path, content, ranges)
    for number, name in missing:
        problems.append(f"line {number}: function `{name}` needs a 2 to 3 line comment or docstring directly before it")
    for number in sorted(ranges):
        line = lines[number - 1] if number <= len(lines) else ""
        if COMMENT_START.match(line) and BUG_FIX_COMMENT.search(line):
            problems.append(f"line {number}: comment describes a fix or request, describe the code's intent instead")
    secret = find_secret(written)
    if secret:
        problems.append(f"hardcoded secret: {secret}. Load it from config or the environment")
    if path.endswith((".sh", ".bash")) or content.startswith(("#!/bin/bash", "#!/usr/bin/env bash", "#!/bin/sh")):
        problems += [f"shellcheck: {finding}" for finding in shellcheck(path)]

    if not problems:
        return 0
    print(f"{path} breaks the engineering standards. Fix these now:\n" + "\n".join(problems[:30]), file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main())
