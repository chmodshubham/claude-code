"""PostToolUse hook for Bash.

Records when tests, linters, or other validation commands run, for the Stop
check. After a new commit, tells Claude to report its hash, message, and
summary.
"""

import json
import os
import re
import subprocess
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from standards_common import read_payload, touch  # noqa: E402

VALIDATION = re.compile(
    r"(^|[;&|(]\s*|\s)(rtk\s+)?((uv|poetry|pipenv|hatch|pdm)\s+run\s+|npx\s+|bunx\s+|(npm|pnpm|yarn|bun)\s+(run\s+)?)?"
    r"(pytest|tox|nox|jest|vitest|mocha|playwright\s+test|ruff|flake8|pylint|mypy|pyright|black|isort|eslint|tsc|"
    r"prettier|biome|go\s+(test|vet|build)|golangci-lint|staticcheck|cargo\s+(test|clippy|check|build|fmt)|"
    r"mvn|\./mvnw|gradle|\./gradlew|dotnet\s+(test|build)|make\s+(test|lint|check)|terraform\s+(validate|fmt)|"
    r"tflint|checkov|shellcheck|rspec|rubocop|phpunit|phpstan|ctest|swift\s+test|"
    r"test|tests|lint|typecheck|type-check|check|verify)(?=$|[\s;&|)])"
)
COMMIT = re.compile(r"(^|[^a-z])git(\s+-[Cc]\s+\S+|\s+-\S+)*\s+commit(\s|$)")


def commit_context(cwd):
    """Return a reminder to report the commit made in the last minute, or None."""
    try:
        result = subprocess.run(["git", "-C", cwd, "log", "-1", "--format=%h%x00%s%x00%ct"],
                                capture_output=True, text=True, check=False, timeout=10)
    except (OSError, subprocess.SubprocessError):
        return None
    parts = result.stdout.strip().split("\x00")
    if result.returncode != 0 or len(parts) != 3 or time.time() - int(parts[2]) > 60:
        return None
    return (f"Commit {parts[0]} created: \"{parts[1]}\". Verify it with git log -1 --stat and "
            "report the hash, message, and a one-line summary of the files changed.")


def main():
    """Record validation runs and add commit report context."""
    payload = read_payload()
    command = payload.get("tool_input", {}).get("command", "")
    if VALIDATION.search(command):
        touch(payload, "last_validation")
    if COMMIT.search(command):
        context = commit_context(payload.get("cwd", "."))
        if context:
            print(json.dumps({"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": context}}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
