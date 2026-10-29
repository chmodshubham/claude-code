#!/usr/bin/env bash
# PreToolUse hook for Bash. Enforces the git, secret, and destructive-command
# rules from Engineering.md and the Claude usage guide. Denies or asks via JSON.
set -euo pipefail

input=$(cat)
cmd=$(jq -r '.tool_input.command // ""' <<<"$input")
cwd=$(jq -r '.cwd // "."' <<<"$input")

# Print a PreToolUse permission decision and stop.
# $1 is deny or ask, $2 is the reason shown to Claude and the user.
decide() {
  jq -n --arg d "$1" --arg r "$2" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: $d, permissionDecisionReason: $r}}'
  exit 0
}

# Return success when the command matches the extended regex in $1.
has() {
  grep -Eq -- "$1" <<<"$cmd"
}

# Scan the changes a commit would include for credentials.
# Prints the first matching line, or nothing when the diff looks clean.
staged_secrets() {
  local diff
  diff=$(git -C "$cwd" diff --cached 2>/dev/null || true)
  if has '(^|[[:space:]])(-[a-zA-Z]*a[a-zA-Z]*|--all)([[:space:]]|$)'; then
    diff+=$'\n'$(git -C "$cwd" diff 2>/dev/null || true)
  fi
  grep -E '^\+' <<<"$diff" | grep -Em1 \
    -e 'AKIA[0-9A-Z]{16}' \
    -e '-----BEGIN [A-Z ]*PRIVATE KEY-----' \
    -e '(ghp|gho|ghs|ghu)_[A-Za-z0-9]{36}' \
    -e 'github_pat_[A-Za-z0-9_]{20,}' \
    -e 'xox[baprs]-[A-Za-z0-9-]{10,}' \
    -e 'sk-(ant-)?[A-Za-z0-9_-]{20,}' \
    -e '(api[_-]?key|secret|passw(or)?d|token)["'\'']?[[:space:]]*[:=][[:space:]]*["'\''][^"'\'' ]{8,}' \
    || true
}

if has '--no-verify'; then
  decide deny "Skipping git hooks with --no-verify is not allowed. Fix what the hook reports instead."
fi

GIT='(^|[^a-z])git([[:space:]]+-[Cc][[:space:]]+[^[:space:]]+|[[:space:]]+-[^[:space:]]+)*[[:space:]]+'

if has "${GIT}commit([[:space:]]|$)"; then
  if grep -Eiq 'co-authored-by' <<<"$cmd"; then
    decide deny "Co-authored-by trailers are not allowed unless the author explicitly asks for one."
  fi
  if ! has '(^|[[:space:]])(-[a-zA-Z]*s[a-zA-Z]*|--signoff)([[:space:]]|$)'; then
    decide deny "Commits must be signed off. Re-run with git commit -s."
  fi
  leak=$(staged_secrets)
  if [[ -n "$leak" ]]; then
    decide deny "The commit appears to contain a secret: ${leak:0:120}. Remove it before committing."
  fi
  decide ask "Commit requested. Approve only if you explicitly authorized this commit. Review the staged diff first."
fi

if has "${GIT}push([[:space:]]|$)"; then
  if has '(^|[[:space:]])(-f|--force|--force-with-lease)([=[:space:]]|$)|[[:space:]]\+[^[:space:]]+'; then
    decide ask "Force push requested. This rewrites remote history."
  fi
  decide ask "Push requested. Confirm the branch and commits before approving."
fi

if has "${GIT}(rebase|filter-branch|filter-repo)([[:space:]]|$)|${GIT}reset[[:space:]].*--hard|${GIT}(clean|branch)[[:space:]].*-[a-zA-Z]*[fD]"; then
  decide ask "This command rewrites history or discards work."
fi

if has '(^|[^a-z])rm[[:space:]]+(-[a-zA-Z]*(r[a-zA-Z]*f|f[a-zA-Z]*r)|-[rR][[:space:]]+-f|-f[[:space:]]+-[rR]|--recursive)'; then
  decide ask "Recursive force delete requested. Check the path before approving."
fi

if has '(terraform|tofu)[[:space:]]+(apply|destroy)|cdk[[:space:]]+(deploy|destroy)|(sam|serverless|sls)[[:space:]]+deploy|kubectl[[:space:]]+(apply|delete|replace|scale|rollout)|helm[[:space:]]+(install|upgrade|uninstall|rollback)|aws[[:space:]].*[[:space:]](delete|terminate|remove|deregister)-|npm[[:space:]]+publish|docker[[:space:]]+push'; then
  decide ask "This command changes shared or production infrastructure."
fi

exit 0
