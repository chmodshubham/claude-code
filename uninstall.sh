#!/usr/bin/env bash
# Removes the plugins and tools that install.sh added to a project: Claude Code
# plugins, rtk, and read-once. Rules, hooks, agents, skills, CLAUDE.md, and
# .claudeignore stay. With --global it also removes the programs installed on
# the Mac for them: the rtk binary, MemPalace, and third-party marketplaces.
# Usage: uninstall.sh [project-dir] [--global]
# From GitHub: curl -fsSL https://raw.githubusercontent.com/chmodshubham/claude-code/main/uninstall.sh | bash -s -- [--global]
set -euo pipefail

PROJECT_DIR="$PWD"
GLOBAL=0
for arg in "$@"; do
  case "$arg" in
    --global) GLOBAL=1 ;;
    -h|--help) sed -n '2,7p' "${BASH_SOURCE[0]:-/dev/null}" 2>/dev/null || true; exit 0 ;;
    -*) printf 'Unknown option: %s\n' "$arg" >&2; exit 1 ;;
    *) PROJECT_DIR="$arg" ;;
  esac
done
PROJECT_DIR=$(cd "$PROJECT_DIR" 2>/dev/null && pwd) || { printf 'Project directory not found\n' >&2; exit 1; }
CLAUDE_DIR="$PROJECT_DIR/.claude"
SETTINGS="$CLAUDE_DIR/settings.json"
MANIFEST="$CLAUDE_DIR/standards-manifest.json"
KIT_PLUGINS="code-review@claude-plugins-official
code-simplifier@claude-plugins-official
claude-code-setup@claude-plugins-official
superpowers@claude-plugins-official
codebase-cleanup@claude-code-workflows
code-refactoring@claude-code-workflows
code-documentation@claude-code-workflows
documentation-generation@claude-code-workflows
caveman@caveman
ecc@ecc
andrej-karpathy-skills@karpathy-skills
mempalace@mempalace
ui-ux-pro-max@ui-ux-pro-max-skill
impeccable@impeccable"
THIRD_PARTY_MARKETPLACES="claude-code-workflows caveman mempalace ecc karpathy-skills ui-ux-pro-max-skill impeccable"
TOOL_FILES=".claude/rules/rtk.md .claude/hooks/read-once/hook.sh .claude/hooks/read-once/compact.sh"

# Print a progress line.
log() { printf '==> %s\n' "$*"; }

# Print a warning to stderr without stopping the script.
warn() { printf 'WARNING: %s\n' "$*" >&2; }

# Apply a jq filter to a JSON file in place, keeping its permissions.
# $1 file, remaining arguments are passed to jq.
jq_in_place() {
  local file="$1" tmp
  shift
  tmp=$(mktemp)
  jq "$@" "$file" >"$tmp"
  cat "$tmp" >"$file"
  rm -f "$tmp"
}

# Uninstall the project-scope plugins that install.sh recorded. Without a
# record, try every plugin the kit can install and skip the ones not present.
remove_plugins() {
  local plugins plugin
  if ! command -v claude >/dev/null; then
    warn "Claude Code is not installed, so there are no plugins to remove."
    return 0
  fi
  if [[ -f "$MANIFEST" ]]; then
    plugins=$(jq -r '.plugins // [] | .[]' "$MANIFEST")
  else
    warn "No install record at $MANIFEST. Trying every plugin the kit installs."
    plugins="$KIT_PLUGINS"
  fi
  log "Removing plugins from $PROJECT_DIR"
  cd "$PROJECT_DIR"
  while IFS= read -r plugin; do
    [[ -n "$plugin" ]] || continue
    if claude plugin uninstall "$plugin" --scope project >/dev/null 2>&1; then
      log "Removed $plugin"
    elif [[ -f "$MANIFEST" ]]; then
      warn "Could not uninstall $plugin"
    fi
  done <<<"$plugins"
  remove_marketplaces
  cd - >/dev/null
  if [[ -f "$MANIFEST" ]]; then
    jq_in_place "$MANIFEST" '.plugins = [] | .marketplaces = []'
  fi
}

# Remove the marketplace declarations that install.sh added to the project
# settings. Without a record, remove any kit marketplace declared there.
remove_marketplaces() {
  local names name
  if [[ -f "$MANIFEST" ]]; then
    names=$(jq -r '.marketplaces // [] | .[]' "$MANIFEST")
  elif [[ -f "$SETTINGS" ]]; then
    names=$(jq -r '.extraKnownMarketplaces // {} | keys[]' "$SETTINGS" \
      | grep -Fx -f <(printf '%s\n' claude-plugins-official $THIRD_PARTY_MARKETPLACES) || true)
  else
    names=""
  fi
  while IFS= read -r name; do
    [[ -n "$name" ]] || continue
    claude plugin marketplace remove "$name" --scope project >/dev/null 2>&1 \
      && log "Removed marketplace $name from the project settings"
  done <<<"$names"
}

# Remove the project's rtk and read-once setup: their hook entries in
# .claude/settings.json, their files, and the read-once cache.
remove_tools() {
  log "Removing rtk and read-once from $PROJECT_DIR"
  if [[ -f "$SETTINGS" ]]; then
    jq_in_place "$SETTINGS" '
      def tool_hook: contains("/.claude/hooks/read-once/") or . == "rtk hook claude";
      if .hooks then
        .hooks |= (map_values(map(select(any(.hooks[]?; (.command // "") | tool_hook) | not)))
          | with_entries(select(.value != [])))
      else . end
      | if .enabledPlugins == {} then del(.enabledPlugins) else . end
      | if .extraKnownMarketplaces == {} then del(.extraKnownMarketplaces) else . end'
  fi
  local file
  for file in $TOOL_FILES; do
    rm -f "$PROJECT_DIR/$file"
  done
  rm -rf "$CLAUDE_DIR/read-once-cache"
  rmdir "$CLAUDE_DIR/hooks/read-once" 2>/dev/null || true
  if [[ -f "$MANIFEST" ]]; then
    jq_in_place "$MANIFEST" --arg files "$TOOL_FILES" '.tools = [] | .files = ((.files // []) - ($files | split(" ")))'
  fi
}

# Remove the programs installed on the Mac for the plugins and tools: the
# rtk binary, MemPalace, and the third-party marketplaces.
uninstall_global() {
  log "Removing the rtk binary, MemPalace, and third-party marketplaces"
  if command -v brew >/dev/null && brew list --formula rtk >/dev/null 2>&1; then
    brew uninstall rtk || warn "brew uninstall rtk failed"
  fi
  if command -v uv >/dev/null; then
    uv tool uninstall mempalace >/dev/null 2>&1 || true
  fi
  if command -v claude >/dev/null; then
    local name
    for name in $THIRD_PARTY_MARKETPLACES; do
      claude plugin marketplace remove "$name" >/dev/null 2>&1 || true
    done
  fi
}

# Remove the project plugins and tools, then the machine-level programs when
# requested.
main() {
  if [[ ! -t 0 ]] && { : </dev/tty; } 2>/dev/null; then
    exec </dev/tty
  fi
  [[ "$PROJECT_DIR" != "$HOME" && "$PROJECT_DIR" != "/" ]] || { warn "Not a project directory: $PROJECT_DIR"; exit 1; }
  command -v jq >/dev/null || { warn "jq is required: brew install jq"; exit 1; }
  local file
  for file in "$SETTINGS" "$MANIFEST"; do
    if [[ -f "$file" ]] && ! jq -e . "$file" >/dev/null 2>&1; then
      warn "$file is not valid JSON. Fix it, then run this again."
      exit 1
    fi
  done
  command -v claude >/dev/null || export PATH="$HOME/.local/bin:$PATH"
  remove_plugins
  remove_tools
  if [[ $GLOBAL -eq 1 ]]; then
    uninstall_global
  fi
  log "Done. Restart Claude Code."
}

main; exit
