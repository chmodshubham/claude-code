#!/usr/bin/env bash
# Adds the project standards to Claude's context. "prompt" mode prints a short
# reminder on every message; "full" mode reprints every standards rule file
# after compaction so long sessions cannot drift from them.
set -euo pipefail

rules_dir="${CLAUDE_PROJECT_DIR:-.}/.claude/rules"

if [[ "${1:-prompt}" == "full" ]]; then
  echo "Context was compacted. These project standards still apply in full:"
  for rule in "$rules_dir"/standards-*.md; do
    if [[ -f "$rule" ]]; then
      echo
      cat "$rule"
    fi
  done
  exit 0
fi

cat <<'EOF'
Project standards (.claude/rules/standards-*.md) apply to this message, even if earlier messages drifted from them:
- Before editing: investigate, find the root cause, then create or update plan.md and todo.md with the plan-task skill. Edits are blocked until both are updated this session.
- Simplest correct fix, no workarounds, no unrelated changes. Follow existing conventions. Every function gets a 2 to 3 line comment or docstring. No bug-fix comments, no hardcoded secrets.
- After code changes: run tests, linters, and type checks and read the results; run the standards-reviewer agent; update todo.md with verified status only.
- Docs: use the write-docs skill and the docs-reviewer agent. Plain English, required section order, directory and every cd for commands, GitHub callouts, no emojis, em dashes, or horizontal rules.
- Git: never commit unless the author asks; the author runs /commit. Always git commit -s, never Co-authored-by, never amend or --no-verify.
- Unsure or missing information: say so or ask. Never claim a check passed without running it.
- Use the finish-task skill before declaring a task complete. End with the completion report including the plan.md and todo.md paths.
EOF
