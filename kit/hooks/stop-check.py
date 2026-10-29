"""Stop hook.

When code changed since the last check, blocks Claude from stopping once and
lists what the engineering standards still require: an updated todo.md, a
validation run after the last change, and a completion report.
"""

import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from standards_common import marker_time, newest, planning_files, project_dir, read_payload, touch  # noqa: E402


def last_assistant_text(transcript):
    """Return the text of the last assistant message in the transcript, or None.

    Reads the JSONL transcript from the end and ignores lines it cannot parse.
    """
    if not transcript or not os.path.exists(transcript):
        return None
    with open(transcript, encoding="utf-8", errors="replace") as handle:
        lines = handle.readlines()[-400:]
    for line in reversed(lines):
        try:
            entry = json.loads(line)
        except ValueError:
            continue
        if entry.get("type") != "assistant":
            continue
        content = entry.get("message", {}).get("content", [])
        text = " ".join(c.get("text", "") for c in content if isinstance(c, dict) and c.get("type") == "text")
        if text.strip():
            return text
    return None


def main():
    """Block stopping once per batch of code changes if requirements are open."""
    payload = read_payload()
    last_edit = marker_time(payload, "last_edit")
    checked = marker_time(payload, "stop_checked")
    if payload.get("stop_hook_active") or last_edit is None or (checked and checked >= last_edit):
        return 0

    problems = []
    _, todos = planning_files(project_dir(payload))
    todo_time = newest(todos)
    if todo_time is None or todo_time < last_edit:
        problems.append("Update todo.md: tick verified items and record open issues, blockers, and deferred work.")
    validation = marker_time(payload, "last_validation")
    if validation is None or validation < last_edit:
        problems.append("Run the project's tests, linters, and type checks (see CLAUDE.md Commands) after the last "
                        "code change and read the results. If they cannot run, record why in todo.md and the report.")
    doc_edit = marker_time(payload, "last_doc_edit")
    if doc_edit is None or doc_edit < last_edit:
        problems.append("Check whether docs describe the changed behavior. Update them, or state that no doc change is needed.")
    text = last_assistant_text(payload.get("transcript_path"))
    if text is not None and not ("plan.md" in text and "todo.md" in text):
        problems.append("Finish with the completion report: what was implemented, main files changed, validation "
                        "commands and actual results, open issues, and the plan.md and todo.md locations.")

    touch(payload, "stop_checked")
    if problems:
        reason = "Engineering standards are not met yet:\n- " + "\n- ".join(problems)
        print(json.dumps({"decision": "block", "reason": reason}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
