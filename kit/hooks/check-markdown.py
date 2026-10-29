"""PostToolUse hook for Write and Edit.

Checks written Markdown against the documentation standards: forbidden
characters and symbols, horizontal rules, directory trees, custom note
formats, inline shell comments, and section order. Exits with code 2 so
Claude sees the violations and fixes them.
"""

import json
import os
import re
import sys

EM_DASH = "—"
HORIZONTAL_RULE = re.compile(r"^ {0,3}([-*_])( *\1){2,} *$")
DIRECTORY_TREE = re.compile(r"[├└]──")
SHELL_LANGUAGES = {"bash", "sh", "shell", "zsh", "console"}
INLINE_COMMENT = re.compile(r"^\s*[^#\s].*\s#\s")
CUSTOM_NOTE = re.compile(r"^\s*(>\s*)?(\*\*|__)?(note|tip|warning|important|caution|info)(\*\*|__)?\s*:", re.IGNORECASE)
SECTION_ORDER = [
    re.compile(r"(?i)^(overview|introduction|about)\b"),
    re.compile(r"(?i)^(prerequisites?|requirements)\b"),
    re.compile(r"(?i)^(deploy(ment|ing)?|install(ation|ing)?|setup|set up|getting started)\b"),
    re.compile(r"(?i)^(configur(ation|e|ing))\b"),
    re.compile(r"(?i)^(clean ?up|undeploy(ment)?|uninstall(ation)?|teardown|removal)\b"),
]
EMOJI = re.compile(
    "[\U0001F000-\U0001FAFF☀-➿⬀-⯿️]"
)


def scan_lines(text):
    """Yield (line number, line, block) for every content line.

    block is None for prose and the fence's language (possibly empty) for
    lines inside a fenced code block. Leading YAML frontmatter and the fence
    lines themselves are skipped.
    """
    lines = text.splitlines()
    start = 0
    if lines and lines[0].strip() == "---":
        for i in range(1, len(lines)):
            if lines[i].strip() == "---":
                start = i + 1
                break
    fence = language = None
    for number, line in enumerate(lines[start:], start=start + 1):
        marker = re.match(r"^ {0,3}(`{3,}|~{3,})\s*([\w+-]*)", line)
        if marker:
            if fence is None:
                fence, language = marker.group(1)[0], marker.group(2).lower()
            elif marker.group(1)[0] == fence:
                fence = language = None
            continue
        yield number, line, language if fence else None


def section_order_problems(text):
    """Return a problem when the standard sections appear out of order.

    Only sections that exist are compared: Overview, Prerequisites,
    Deployment, Configuration, Cleanup.
    """
    found = []
    for number, line, block in scan_lines(text):
        heading = re.match(r"^#{1,6}\s+(.*)", line) if block is None else None
        if not heading:
            continue
        for rank, pattern in enumerate(SECTION_ORDER):
            if pattern.search(heading.group(1)):
                found.append((rank, number, heading.group(1).strip()))
                break
    for (rank_a, _, title_a), (rank_b, number_b, title_b) in zip(found, found[1:]):
        if rank_b < rank_a:
            return [f"line {number_b}: section '{title_b}' must come before '{title_a}' "
                    "(order: Overview, Prerequisites, Deployment, Configuration, Cleanup)"]
    return []


def find_violations(text, whole_file):
    """Return a list of human-readable rule violations in the Markdown text.

    Em dashes, emojis, and directory trees are checked everywhere. Horizontal
    rules, custom note formats, and inline shell comments are checked outside
    or inside code blocks as appropriate. Section order needs the whole file.
    """
    problems = []
    for number, line in enumerate(text.splitlines(), start=1):
        if EM_DASH in line:
            problems.append(f"line {number}: em dash, use a comma, colon, or period")
        if EMOJI.search(line):
            problems.append(f"line {number}: emoji or decorative symbol")
        if DIRECTORY_TREE.search(line):
            problems.append(f"line {number}: project directory structure, remove it")
    for number, line, block in scan_lines(text):
        if block is None and HORIZONTAL_RULE.match(line):
            problems.append(f"line {number}: horizontal rule, use a heading instead")
        if block is None and CUSTOM_NOTE.match(line):
            problems.append(f"line {number}: custom note format, use a GitHub callout such as > [!NOTE]")
        if block in SHELL_LANGUAGES and INLINE_COMMENT.search(line):
            problems.append(f"line {number}: inline comment, move it to its own line above the command")
    if whole_file:
        problems += section_order_problems(text)
    return problems


def written_text(tool_input):
    """Return only the text Claude wrote in this tool call.

    Checking the new text instead of the whole file keeps the hook from
    demanding fixes to lines Claude did not touch.
    """
    if "content" in tool_input:
        return tool_input["content"]
    if "new_string" in tool_input:
        return tool_input["new_string"]
    return "\n".join(edit.get("new_string", "") for edit in tool_input.get("edits", []))


def main():
    """Read the hook payload, check the written Markdown, report problems.

    Files inside any .claude directory (memory, rules, plugin data) are not
    documentation and are skipped.
    """
    tool_input = json.load(sys.stdin).get("tool_input", {})
    path = tool_input.get("file_path", "")
    if not path.lower().endswith((".md", ".mdx")):
        return 0
    if f"{os.sep}.claude{os.sep}" in os.path.abspath(path):
        return 0
    problems = find_violations(written_text(tool_input), "content" in tool_input)
    if not problems:
        return 0
    print(
        f"The text just written to {path} breaks the documentation "
        "standards. Fix these now (line numbers are relative to the "
        "written text):\n" + "\n".join(problems[:30]),
        file=sys.stderr,
    )
    return 2


if __name__ == "__main__":
    sys.exit(main())
