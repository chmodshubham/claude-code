"""PreToolUse hook for file edits.

Blocks edits to project files until plan.md and todo.md exist and have been
created or updated in the current session (Engineering standards, planning).
Set STANDARDS_PLAN_GATE=off in the environment to disable it.
"""

import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from standards_common import classify, newest, planning_files, project_dir, read_payload, session_start  # noqa: E402


def deny(reason):
    """Print a PreToolUse deny decision with the given reason."""
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }))


def main():
    """Check that planning files are current before allowing the edit."""
    if os.environ.get("STANDARDS_PLAN_GATE", "").lower() == "off":
        return 0
    payload = read_payload()
    tool_input = payload.get("tool_input", {})
    path = tool_input.get("file_path") or tool_input.get("notebook_path") or ""
    project = project_dir(payload)
    if not path or classify(path, project) == "exempt":
        return 0
    plans, todos = planning_files(project)
    if not plans or not todos:
        deny("Create plan.md and todo.md before changing project files. Use the plan-task skill.")
        return 0
    started = session_start(payload)
    if started is not None and (newest(plans) < started or newest(todos) < started):
        deny("Update plan.md and todo.md for this task before changing project files. Use the plan-task skill.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
