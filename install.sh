#!/usr/bin/env bash
# Sets up Claude Code for one project: prerequisites, Claude Code, tools,
# plugins, standards rules, hooks, agents, skills, permissions, CLAUDE.md (via
# init), and .claudeignore, adjusted to the project's stack.
# Usage: install.sh [--only NAMES | --without NAMES] [--list] [project-dir]
set -euo pipefail

REPO_URL="https://github.com/chmodshubham/claude-code"
REPO_TARBALL="https://codeload.github.com/chmodshubham/claude-code/tar.gz/refs/heads/main"
USAGE="Usage: install.sh [--only NAMES | --without NAMES] [--list] [project-dir]

  --only NAMES     Comma-separated plugins or tools to install; all others are skipped.
  --without NAMES  Comma-separated plugins or tools to skip; all others are installed.
                   On a re-run, a plugin this kit installed earlier that is now
                   skipped is removed from the project.
  --list           Print the names that --only and --without accept, then exit.
  project-dir      Project to set up. Defaults to the current directory.

With neither option, every plugin and tool is installed.

From GitHub:
  curl -fsSL https://raw.githubusercontent.com/chmodshubham/claude-code/main/install.sh | bash -s -- --only caveman,rtk"
PLUGINS="code-review@claude-plugins-official
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
TOOLS="rtk read-once"
KIT_DIR=""
BOOTSTRAP_DIR=""
PROJECT_DIR=""
WITHOUT=""
ONLY=""
BLOCK_START="<!-- claude-standards:start -->"
BLOCK_END="<!-- claude-standards:end -->"
MARKETPLACES="anthropics/claude-plugins-official claude-plugins-official
wshobson/agents claude-code-workflows
juliusbrussee/caveman caveman
MemPalace/mempalace mempalace
affaan-m/ecc ecc
forrestchang/andrej-karpathy-skills karpathy-skills
nextlevelbuilder/ui-ux-pro-max-skill ui-ux-pro-max-skill
pbakaus/impeccable impeccable"

INIT_PROMPT="Explore this repository and write project notes in CLAUDE.md, the way /init does.
- Keep it lean. Include only what cannot be learned by reading the code: a short architecture sketch (where things live), non-obvious conventions, the build, test, and deploy commands people run often, and known gotchas.
- Do not include a file listing, a directory tree, or anything git history already explains. Do not repeat commands already listed in the managed block.
- Do not change anything between <!-- claude-standards:start --> and <!-- claude-standards:end -->. Put your notes above that block.
- If CLAUDE.md already has notes outside the block, keep them, correct anything that is wrong, and fill gaps.
- Follow the documentation rules: plain English, short sentences, no emojis, no em dashes, no horizontal rules.
Then add to .claudeignore every generated, vendored, build output, cache, large data, or binary path in this project that is not already listed, one pattern per line. Do not remove existing lines.
Only modify CLAUDE.md and .claudeignore. Do not create plan.md, todo.md, or any other file. Do not run builds, installs, or tests."

STACKS=""
COMMANDS=""
ALLOW=""
IGNORE=""
DENY=""
INSTALLED=""
FRONTEND=0
INTERACTIVE=0
RTK_ON=0
READ_ONCE_ON=0
READ_ONCE_URL="https://raw.githubusercontent.com/Bande-a-Bonnot/Boucle-framework/main/tools/read-once"
READ_ONCE_CACHE_LINE='CACHE_DIR="\${HOME}/.claude/read-once"'

# Print a progress line.
log() { printf '==> %s\n' "$*"; }

# Print a warning to stderr without stopping the script.
warn() { printf 'WARNING: %s\n' "$*" >&2; }

# Print an error and stop.
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

# Append a line to a newline-separated list variable, skipping duplicates.
# $1 is the variable name, $2 the value.
add() {
  local current="${!1}"
  if ! grep -Fxq -- "$2" <<<"$current"; then
    printf -v "$1" '%s%s\n' "$current" "$2"
  fi
}

# Record a project command: list it in CLAUDE.md and pre-approve it.
# $1 is the command line exactly as it should be run.
add_command() {
  add COMMANDS "$1"
  add ALLOW "Bash($1:*)"
}

# Record a generated or vendored path. Soft entries only go to .claudeignore;
# hard entries are also blocked from the Read tool. $1 pattern, $2 soft|hard.
add_ignore() {
  add IGNORE "$1"
  if [[ "$2" == hard ]]; then
    case "$1" in
      */) add DENY "Read(**/$1**)" ;;
      *) add DENY "Read(**/$1)" ;;
    esac
  fi
}

# Print every name that --without accepts: plugin short names and tools.
optional_names() {
  printf '%s\n' "$PLUGINS" | cut -d@ -f1
  printf '%s\n' $TOOLS
}

# Return success when the plugin or tool should be installed: it is listed in
# --only, or --only is unset and it is not listed in --without.
# $1 is a plugin short name or tool name.
enabled() {
  if [[ -n "$ONLY" ]]; then
    grep -Fxq -- "$1" <<<"$(tr ',' '\n' <<<"$ONLY")"
  else
    ! grep -Fxq -- "$1" <<<"$(tr ',' '\n' <<<"$WITHOUT")"
  fi
}

# Parse the command line into PROJECT_DIR, ONLY, and WITHOUT, and reject
# unknown options or names so a typo cannot silently install the wrong set.
parse_args() {
  local project="$PWD" name valid
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --without) [[ $# -ge 2 ]] || die "--without needs a value. $USAGE"; WITHOUT="$2"; shift 2 ;;
      --without=*) WITHOUT="${1#*=}"; shift ;;
      --only) [[ $# -ge 2 ]] || die "--only needs a value. $USAGE"; ONLY="$2"; shift 2 ;;
      --only=*) ONLY="${1#*=}"; shift ;;
      --list) optional_names; exit 0 ;;
      -h|--help) printf '%s\n' "$USAGE"; exit 0 ;;
      -*) die "Unknown option $1. $USAGE" ;;
      *) project="$1"; shift ;;
    esac
  done
  [[ -z "$ONLY" || -z "$WITHOUT" ]] || die "Use --only or --without, not both."
  valid=$(optional_names)
  for name in $(tr ',' ' ' <<<"$ONLY$WITHOUT"); do
    grep -Fxq -- "$name" <<<"$valid" || die "Unknown name '$name'. Run with --list to see valid names."
  done
  PROJECT_DIR=$(cd "$project" 2>/dev/null && pwd) || die "Project directory not found: $project"
  CLAUDE_DIR="$PROJECT_DIR/.claude"
  SETTINGS="$CLAUDE_DIR/settings.json"
  MANIFEST="$CLAUDE_DIR/standards-manifest.json"
  HOOKS_DIR="$CLAUDE_DIR/hooks/standards"
}

# Use the kit next to this script, or download it from GitHub into a temporary
# directory when the script was piped in with curl or copied on its own.
locate_kit() {
  local source="${BASH_SOURCE[0]:-}"
  if [[ -n "$source" && -f "$source" ]]; then
    KIT_DIR=$(cd "$(dirname "$source")" && pwd)
    if [[ -d "$KIT_DIR/kit/rules" ]]; then
      return 0
    fi
  fi
  log "Downloading the kit from $REPO_URL (main branch)"
  BOOTSTRAP_DIR=$(mktemp -d)
  trap 'rm -rf "$BOOTSTRAP_DIR"' EXIT
  curl -fsSL "$REPO_TARBALL" | tar -xz -C "$BOOTSTRAP_DIR" --strip-components=1 \
    || die "Could not download $REPO_TARBALL"
  KIT_DIR="$BOOTSTRAP_DIR"
  [[ -d "$KIT_DIR/kit/rules" && -d "$KIT_DIR/kit/hooks" ]] \
    || die "The download from $REPO_URL has no kit/ directory."
}

# Stop early when the target cannot safely hold a project .claude directory.
# The home directory is excluded because ~/.claude is the user config.
check_target() {
  [[ "$(id -u)" -ne 0 ]] || die "Do not run this installer with sudo or as root."
  [[ "$PROJECT_DIR" != "$HOME" && "$PROJECT_DIR" != "/" ]] \
    || die "Run this inside a project directory, not $PROJECT_DIR."
  [[ -w "$PROJECT_DIR" ]] || die "No write permission for $PROJECT_DIR."
  check_json "$PROJECT_DIR/.claude/settings.json"
  check_json "$PROJECT_DIR/.claude/standards-manifest.json"
}

# Stop with a clear message when an existing JSON file cannot be parsed, so
# the merge never fails halfway. A missing file is fine. $1 is the path.
check_json() {
  if [[ -f "$1" ]] && ! jq -e . "$1" >/dev/null 2>&1; then
    die "$1 is not valid JSON (comments are not allowed). Fix it, then run this again."
  fi
}

# Install a Homebrew formula when its command is missing. Returns failure
# instead of stopping, so the caller decides whether the tool is required.
# $1 is the command name, $2 the formula (defaults to the command name).
brew_install() {
  command -v "$1" >/dev/null && return 0
  log "Installing $1"
  brew install "${2:-$1}" || { warn "Could not install $1 with Homebrew."; return 1; }
}

# Put an installed Homebrew on PATH for this run. Returns failure when
# Homebrew is not installed in either standard location.
load_brew_env() {
  local brew_bin
  for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x "$brew_bin" ]]; then
      eval "$("$brew_bin" shellenv)"
      return 0
    fi
  done
  return 1
}

# Make sure the machine can run the kit: macOS 13 or later, Homebrew, and the
# Xcode Command Line Tools (git, python3). Installs what is missing.
install_prerequisites() {
  log "Checking prerequisites"
  [[ "$(uname -s)" == Darwin ]] || die "This installer supports macOS only."
  local version
  version=$(sw_vers -productVersion)
  [[ "${version%%.*}" -ge 13 ]] || die "Claude Code needs macOS 13 or later. This Mac runs $version."
  if ! command -v brew >/dev/null && ! load_brew_env; then
    [[ $INTERACTIVE -eq 1 ]] || die "Homebrew is missing and needs your password to install. Run this installer in a terminal."
    log "Installing Homebrew (it asks for your password)"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    load_brew_env || die "Homebrew installed but was not found. Open a new terminal and run this again."
    if ! grep -qs 'brew shellenv' "$HOME/.zprofile"; then
      printf '\neval "$(%s shellenv)"\n' "$(command -v brew)" >>"$HOME/.zprofile"
    fi
  fi
  if ! xcode-select -p >/dev/null 2>&1; then
    xcode-select --install || true
    die "Finish installing the Xcode Command Line Tools in the dialog, then run this installer again."
  fi
}

# Install the command line tools the hooks and plugins depend on.
# Each tool is installed only when it is missing.
install_tools() {
  log "Checking command line tools"
  local tool
  brew_install jq || die "jq is required."
  for tool in node uv shellcheck; do
    brew_install "$tool" || true
  done
  if enabled code-review; then brew_install gh || true; fi
  if enabled rtk && brew_install rtk && ! rtk gain >/dev/null 2>&1; then
    warn "The rtk on PATH is not rtk-ai/rtk. Run: brew uninstall rtk && brew install rtk"
  fi
  export PATH="$HOME/.local/bin:$PATH"
  if command -v uv >/dev/null; then
    uv tool update-shell >/dev/null 2>&1 || true
  fi
  if ! command -v claude >/dev/null; then
    log "Installing Claude Code"
    curl -fsSL https://claude.ai/install.sh | bash || die "Claude Code install failed. Check your network and run this again."
  fi
  command -v claude >/dev/null || die "claude is not on PATH. Open a new terminal and run this again."
  if ! claude auth status >/dev/null 2>&1; then
    if [[ $INTERACTIVE -eq 1 ]]; then
      log "Sign in to Claude Code"
      claude auth login || warn "Not signed in. Init will be skipped. Sign in later with: claude auth login"
    else
      warn "Claude Code is not signed in and there is no terminal to sign in. Init will be skipped. Run: claude auth login"
    fi
  fi
  if enabled mempalace && ! command -v mempalace-mcp >/dev/null; then
    if command -v uv >/dev/null; then
      log "Installing MemPalace"
      uv tool install mempalace || warn "MemPalace install failed. The mempalace plugin will not work until it is installed."
    else
      warn "uv is missing, so MemPalace was not installed."
    fi
  fi
  if enabled code-review && ! gh auth status >/dev/null 2>&1; then
    warn "GitHub CLI is not logged in. The code-review plugin needs: gh auth login"
  fi
}

# Delete files this kit installed earlier and forget them in the manifest.
# Files the kit did not install are left alone. Arguments are project-relative.
drop_files() {
  local file tmp
  for file in "$@"; do
    if jq -e --arg f "$file" '(.files // []) | index([$f])' "$MANIFEST" >/dev/null 2>&1; then
      rm -f "$PROJECT_DIR/$file"
      tmp=$(mktemp)
      jq --arg f "$file" '.files -= [$f]' "$MANIFEST" >"$tmp"
      cat "$tmp" >"$MANIFEST"
      rm -f "$tmp"
    fi
  done
}

# Set up rtk for this project only: its awareness note becomes a project rule
# and its hook goes into the project settings (see merge_settings). The note
# is generated with a throwaway HOME so ~/.claude is never touched.
install_rtk() {
  RTK_ON=0
  if ! enabled rtk; then
    drop_files ".claude/rules/rtk.md"
    return 0
  fi
  if ! command -v rtk >/dev/null; then
    warn "rtk is not installed, so it was skipped."
    return 0
  fi
  log "Setting up rtk for this project"
  local scratch
  scratch=$(mktemp -d)
  if HOME="$scratch" rtk init -g --auto-patch </dev/null >/dev/null 2>&1 && [[ -s "$scratch/.claude/RTK.md" ]]; then
    install_file "$scratch/.claude/RTK.md" ".claude/rules/rtk.md"
    RTK_ON=1
  else
    warn "rtk init failed, so rtk was skipped."
  fi
  rm -rf "$scratch"
}

# Set up read-once for this project only: its hooks are copied into
# .claude/hooks/read-once and its cache is kept in .claude/read-once-cache.
install_read_once() {
  READ_ONCE_ON=0
  if ! enabled read-once; then
    drop_files ".claude/hooks/read-once/hook.sh" ".claude/hooks/read-once/compact.sh"
    rm -rf "$CLAUDE_DIR/read-once-cache"
    rmdir "$CLAUDE_DIR/hooks/read-once" 2>/dev/null || true
    return 0
  fi
  log "Setting up read-once for this project"
  local scratch name
  scratch=$(mktemp -d)
  for name in hook.sh compact.sh; do
    if ! curl -fsSL "$READ_ONCE_URL/$name" -o "$scratch/$name" \
        || ! grep -q "$READ_ONCE_CACHE_LINE" "$scratch/$name"; then
      warn "Could not download a compatible read-once $name, so read-once was skipped."
      rm -rf "$scratch"
      return 0
    fi
    sed -i '' "s|$READ_ONCE_CACHE_LINE|CACHE_DIR=\"\${READ_ONCE_CACHE_DIR:-\${HOME}/.claude/read-once}\"|" "$scratch/$name"
  done
  for name in hook.sh compact.sh; do
    install_file "$scratch/$name" ".claude/hooks/read-once/$name"
  done
  rm -rf "$scratch"
  chmod +x "$CLAUDE_DIR/hooks/read-once/"*.sh
  mkdir -p "$CLAUDE_DIR/read-once-cache"
  printf '*\n' >"$CLAUDE_DIR/read-once-cache/.gitignore"
  READ_ONCE_ON=1
}

# Detect the languages and tools in the project and record the matching
# commands, ignore patterns, and frontend flag.
detect_stack() {
  log "Detecting the project stack in $PROJECT_DIR"
  cd "$PROJECT_DIR"
  add_command "git status"
  add_command "git diff"
  add_command "git log"
  add_command "git show"
  add_ignore "*.lock" soft
  add_ignore "*.log" soft
  add_ignore ".DS_Store" soft
  add_ignore "*.min.js" hard
  add_ignore "*.min.css" hard
  add_ignore "*.map" hard

  if [[ -f package.json ]]; then
    local pm=npm script
    if [[ -f pnpm-lock.yaml ]]; then pm=pnpm; fi
    if [[ -f yarn.lock ]]; then pm=yarn; fi
    if [[ -f bun.lockb || -f bun.lock ]]; then pm=bun; fi
    add STACKS "Node ($pm)"
    for script in test lint typecheck type-check check build format; do
      if jq -e --arg s "$script" '.scripts[$s] // empty' package.json >/dev/null 2>&1; then
        add_command "$pm run $script"
      fi
    done
    if jq -e '[(.dependencies // {}), (.devDependencies // {})] | add | keys[]
        | select(test("^(react|react-dom|react-native|vue|svelte|next|nuxt|@angular/core|solid-js|astro|@sveltejs/kit)$"))' \
        package.json >/dev/null 2>&1; then
      FRONTEND=1
    fi
    add_ignore "node_modules/" hard
    add_ignore "dist/" hard
    add_ignore "build/" hard
    add_ignore ".next/" hard
    add_ignore ".nuxt/" hard
    add_ignore ".svelte-kit/" hard
    add_ignore ".turbo/" hard
    add_ignore ".parcel-cache/" hard
    add_ignore "storybook-static/" hard
    add_ignore "coverage/" hard
    add_ignore "package-lock.json" soft
    add_ignore "pnpm-lock.yaml" soft
    add_ignore "bun.lockb" soft
  fi

  if [[ -f pyproject.toml || -f setup.py || -f Pipfile ]] || ls requirements*.txt >/dev/null 2>&1; then
    local run="" deps
    if [[ -f uv.lock ]]; then run="uv run "; fi
    if [[ -f poetry.lock ]]; then run="poetry run "; fi
    add STACKS "Python${run:+ (${run% run })}"
    deps=$(cat pyproject.toml setup.cfg requirements*.txt Pipfile 2>/dev/null || true)
    if grep -qi 'pytest' <<<"$deps" || [[ -d tests ]]; then add_command "${run}pytest"; fi
    if grep -qi 'ruff' <<<"$deps"; then add_command "${run}ruff check ."; fi
    if grep -qi 'mypy' <<<"$deps"; then add_command "${run}mypy ."; fi
    add_ignore "__pycache__/" hard
    add_ignore ".venv/" hard
    add_ignore "venv/" hard
    add_ignore ".pytest_cache/" hard
    add_ignore ".mypy_cache/" hard
    add_ignore ".ruff_cache/" hard
    add_ignore "*.egg-info/" hard
    add_ignore "*.pyc" hard
    add_ignore ".tox/" hard
    add_ignore "htmlcov/" hard
    add_ignore ".ipynb_checkpoints/" hard
    add_ignore "dist/" hard
    add_ignore "build/" hard
  fi

  if [[ -f go.mod ]]; then
    add STACKS "Go"
    add_command "go build ./..."
    add_command "go test ./..."
    add_command "go vet ./..."
    add_ignore "vendor/" hard
  fi

  if [[ -f Cargo.toml ]]; then
    add STACKS "Rust"
    add_command "cargo build"
    add_command "cargo test"
    add_command "cargo clippy"
    add_command "cargo fmt --check"
    add_ignore "target/" hard
  fi

  if [[ -f pom.xml ]]; then
    local mvn=mvn
    if [[ -x mvnw ]]; then mvn=./mvnw; fi
    add STACKS "Java (Maven)"
    add_command "$mvn test"
    add_ignore "target/" hard
    add_ignore "*.class" hard
    add_ignore "*.jar" soft
  fi

  if [[ -f build.gradle || -f build.gradle.kts ]]; then
    local gradle=gradle
    if [[ -x gradlew ]]; then gradle=./gradlew; fi
    add STACKS "JVM (Gradle)"
    add_command "$gradle test"
    add_ignore "build/" hard
    add_ignore ".gradle/" hard
    add_ignore "*.class" hard
    add_ignore "*.jar" soft
  fi

  if [[ -n "$(find . -maxdepth 3 -name '*.tf' -not -path '*/.terraform/*' -print -quit)" ]]; then
    add STACKS "Terraform"
    add_command "terraform fmt -check -recursive"
    add_command "terraform validate"
    add_ignore ".terraform/" hard
    add_ignore "*.tfstate" hard
    add_ignore "*.tfstate.backup" hard
    add_ignore ".terraform.lock.hcl" soft
  fi

  if [[ -f cdk.json ]]; then
    add STACKS "AWS CDK"
    add_command "npx cdk synth"
    add_command "npx cdk diff"
    add_ignore "cdk.out/" hard
  fi

  if [[ -f Makefile ]]; then
    local target
    for target in test lint check; do
      if grep -Eq "^$target:" Makefile; then add_command "make $target"; fi
    done
  fi

  if command -v shellcheck >/dev/null \
      && [[ -n "$(find . -maxdepth 3 -name '*.sh' -not -path './node_modules/*' -print -quit)" ]]; then
    add_command "shellcheck"
  fi

  if [[ -z "$STACKS" ]]; then add STACKS "No build system detected"; fi
  if [[ $FRONTEND -eq 1 ]]; then add STACKS "Frontend framework"; fi
  cd - >/dev/null
}

# Copy one kit file into the project and record it for uninstall.sh.
# A file that exists but was not installed by this kit is left alone.
# $1 source path, $2 destination path relative to the project.
install_file() {
  local destination="$PROJECT_DIR/$2"
  if [[ -e "$destination" ]] && ! cmp -s "$1" "$destination" \
      && ! jq -e --arg f "$2" '(.files // []) | index([$f])' "$MANIFEST" >/dev/null 2>&1; then
    warn "Skipping $2: it already exists and was not installed by this kit."
    return 0
  fi
  mkdir -p "$(dirname "$destination")"
  cp "$1" "$destination"
  add INSTALLED "$2"
}

# Install the standards as Claude Code components: rules that load every
# session, hooks that enforce them, reviewer agents, and workflow skills.
install_standards() {
  log "Installing standards rules, hooks, agents, and skills"
  local file skill
  mkdir -p "$CLAUDE_DIR"
  [[ -f "$MANIFEST" ]] || echo '{}' >"$MANIFEST"
  for file in "$KIT_DIR"/kit/rules/*.md; do
    install_file "$file" ".claude/rules/standards-$(basename "$file")"
  done
  for file in "$KIT_DIR"/kit/hooks/*; do
    [[ -f "$file" ]] || continue
    install_file "$file" ".claude/hooks/standards/$(basename "$file")"
  done
  find "$HOOKS_DIR" -type f \( -name '*.sh' -o -name '*.py' \) -exec chmod +x {} +
  for file in "$KIT_DIR"/kit/agents/*.md; do
    install_file "$file" ".claude/agents/$(basename "$file")"
  done
  for skill in "$KIT_DIR"/kit/skills/*/; do
    install_file "$skill/SKILL.md" ".claude/skills/$(basename "$skill")/SKILL.md"
  done
}

# Turn a newline-separated list into a JSON array.
json_array() {
  printf '%s' "$1" | jq -R -s 'split("\n") | map(select(length > 0))'
}

# Merge hooks, permissions, and attribution into .claude/settings.json and
# record what was added in the manifest so uninstall.sh removes only that.
merge_settings() {
  log "Updating $SETTINGS"
  [[ -f "$SETTINGS" ]] || echo '{}' >"$SETTINGS"
  [[ -f "$MANIFEST" ]] || echo '{}' >"$MANIFEST"
  local hooks tmp
  hooks=$(jq -n --arg dir '"$CLAUDE_PROJECT_DIR"/.claude/hooks/standards' \
    --arg ro '"$CLAUDE_PROJECT_DIR"/.claude/hooks/read-once' \
    --arg cache 'READ_ONCE_CACHE_DIR="$CLAUDE_PROJECT_DIR"/.claude/read-once-cache' \
    --argjson rtk "$RTK_ON" --argjson readonce "$READ_ONCE_ON" '{
    PreToolUse: [
      {matcher: "Bash", hooks: [{type: "command", command: "\($dir)/guard-bash.sh"}]},
      {matcher: "Write|Edit|MultiEdit|NotebookEdit", hooks: [{type: "command", command: "python3 -I -B \($dir)/plan-gate.py"}]}
    ],
    PostToolUse: [
      {matcher: "Write|Edit|MultiEdit", hooks: [
        {type: "command", command: "python3 -I -B \($dir)/check-code.py"},
        {type: "command", command: "python3 -I -B \($dir)/check-markdown.py"}
      ]},
      {matcher: "Bash", hooks: [{type: "command", command: "python3 -I -B \($dir)/track-bash.py"}]}
    ],
    Stop: [{hooks: [{type: "command", command: "python3 -I -B \($dir)/stop-check.py"}]}],
    UserPromptSubmit: [{hooks: [{type: "command", command: "\($dir)/remind.sh prompt"}]}],
    SessionStart: [{matcher: "compact", hooks: [{type: "command", command: "\($dir)/remind.sh full"}]}]
  }
  | if $rtk == 1 then .PreToolUse += [{matcher: "Bash", hooks: [{type: "command", command: "rtk hook claude"}]}] else . end
  | if $readonce == 1 then
      .PreToolUse += [{matcher: "Read", hooks: [{type: "command", command: "\($cache) \($ro)/hook.sh"}]}]
      | .PostCompact = [{matcher: "", hooks: [{type: "command", command: "\($cache) \($ro)/compact.sh"}]}]
    else . end')
  tmp=$(mktemp)
  jq -n \
    --slurpfile settings "$SETTINGS" \
    --slurpfile manifest "$MANIFEST" \
    --argjson hooks "$hooks" \
    --argjson allow "$(json_array "$ALLOW")" \
    --argjson deny "$(json_array "$DENY")" \
    --argjson files "$(json_array "$INSTALLED")" \
    --argjson rtk "$RTK_ON" --argjson readonce "$READ_ONCE_ON" '
    def missing($have): map(select(. as $x | ($have | index([$x])) | not));
    def kit_hook: contains("/.claude/hooks/standards/") or contains("/.claude/hooks/read-once/") or . == "rtk hook claude";
    def union($new): reduce $new[] as $x (.; if index([$x]) then . else . + [$x] end);
    $settings[0] as $s | $manifest[0] as $m |
    ($allow | missing($s.permissions.allow // [])) as $new_allow |
    ($deny | missing($s.permissions.deny // [])) as $new_deny |
    {
      settings: ($s
        | .hooks = ((.hooks // {}) | map_values(map(select(any(.hooks[]?; (.command // "") | kit_hook) | not))))
        | .hooks = reduce ($hooks | to_entries[]) as $e (.hooks; .[$e.key] = ((.[$e.key] // []) + $e.value))
        | .hooks |= with_entries(select(.value != []))
        | .permissions.allow = ((.permissions.allow // []) + $new_allow)
        | .permissions.deny = ((.permissions.deny // []) + $new_deny)
        | if .attribution == null then .attribution = {commit: "", pr: ""} else . end),
      manifest: ($m
        | .allow = ((.allow // []) | union($new_allow))
        | .deny = ((.deny // []) | union($new_deny))
        | .attribution = (.attribution // ($s.attribution == null))
        | .files = ((.files // []) | union($files))
        | .tools = ([if $rtk == 1 then "rtk" else empty end, if $readonce == 1 then "read-once" else empty end]))
    }' >"$tmp"
  jq '.settings' "$tmp" >"$SETTINGS"
  jq '.manifest' "$tmp" >"$MANIFEST"
  rm -f "$tmp"
}

# Replace the managed block in a file, creating the file when needed.
# $1 file, $2 start marker, $3 end marker, $4 block body.
write_block() {
  local file="$1" tmp
  tmp=$(mktemp)
  if [[ -f "$file" ]]; then
    awk -v s="$2" -v e="$3" '
      $0 == s {skip = 1; next}
      $0 == e {skip = 0; next}
      skip {next}
      /^$/ {blank++; next}
      {for (; blank > 0; blank--) print ""; print}' "$file" >"$tmp"
  fi
  if [[ -s "$tmp" ]]; then
    printf '\n' >>"$tmp"
  fi
  printf '%s\n%s%s\n' "$2" "$4" "$3" >>"$tmp"
  cat "$tmp" >"$file"
  rm -f "$tmp"
}

# Write the managed block of CLAUDE.md from the detected stack.
# Content outside the markers, including the init notes, is left untouched.
write_claude_md() {
  log "Updating the managed block in CLAUDE.md"
  local commands body
  commands=$(printf '%s' "$COMMANDS" | grep -v '^git ' | sed 's/.*/- `&`/' || true)
  body="## Project setup

Stack: $(printf '%s' "$STACKS" | paste -sd ',' - | sed 's/,/, /g').

Standards in \`.claude/rules/standards-*.md\` apply to every task in this project.

## Commands

${commands:-- No test or lint commands detected. Add them here.}
"
  write_block "$PROJECT_DIR/CLAUDE.md" "$BLOCK_START" "$BLOCK_END" "$body"
}

# Add the detected ignore patterns to .claudeignore. Existing lines are kept
# and nothing is duplicated. uninstall.sh leaves this file in place.
update_claudeignore() {
  log "Updating .claudeignore"
  local file="$PROJECT_DIR/.claudeignore" tmp pattern
  touch "$file"
  tmp=$(mktemp)
  grep -Fxv -e "# claude-standards:start" -e "# claude-standards:end" "$file" >"$tmp" || true
  while IFS= read -r pattern; do
    [[ -n "$pattern" ]] || continue
    grep -Fxq -- "$pattern" "$tmp" || printf '%s\n' "$pattern" >>"$tmp"
  done <<<"$IGNORE"
  cat "$tmp" >"$file"
  rm -f "$tmp"
}

# Return success when the project has no files yet besides Claude config.
# New projects get their CLAUDE.md notes as decisions are made, not from init.
is_new_project() {
  [[ -z "$(find "$PROJECT_DIR" -mindepth 1 \( -name .git -o -name .claude -o -name CLAUDE.md \
    -o -name .claudeignore -o -name .DS_Store \) -prune -o -type f -print -quit)" ]]
}

# Have Claude explore an existing project the way /init does, write lean notes
# in CLAUDE.md, and add project-specific generated paths to .claudeignore.
run_init() {
  if is_new_project; then
    log "New project detected. Skipping init."
    return 0
  fi
  if ! claude auth status >/dev/null 2>&1; then
    warn "Skipping init because Claude Code is not signed in. Run: claude auth login, then /init in the project."
    return 0
  fi
  log "Running init: Claude is exploring the project (this can take a few minutes)"
  cd "$PROJECT_DIR"
  if ! claude -p "$INIT_PROMPT" --permission-mode acceptEdits \
      --allowedTools "Read" "Glob" "Grep" "Edit" "Write" "Bash(git ls-files:*)" "Bash(ls:*)"; then
    warn "init did not finish. Run claude in the project and type /init."
  fi
  cd - >/dev/null
  write_claude_md
}

# Return the plugin ids to install, as chosen with --only or --without.
selected_plugins() {
  local plugin
  while IFS= read -r plugin; do
    if enabled "${plugin%%@*}"; then
      printf '%s\n' "$plugin"
    fi
  done <<<"$PLUGINS"
}

# Uninstall plugins this kit installed earlier that are now excluded by
# --only or --without, and drop them from the manifest.
remove_excluded_plugins() {
  local plugin removed="" tmp
  while IFS= read -r plugin; do
    [[ -n "$plugin" ]] || continue
    if ! enabled "${plugin%%@*}"; then
      log "Removing $plugin (not selected)"
      (cd "$PROJECT_DIR" && claude plugin uninstall "$plugin" --scope project) || warn "Could not uninstall $plugin"
      removed="$removed$plugin"$'\n'
    fi
  done < <(jq -r '.plugins // [] | .[]' "$MANIFEST")
  tmp=$(mktemp)
  jq --argjson r "$(json_array "$removed")" '.plugins = ((.plugins // []) - $r)' "$MANIFEST" >"$tmp"
  cat "$tmp" >"$MANIFEST"
  rm -f "$tmp"
}

# Declare the marketplaces the selected plugins come from in the project
# settings, then install the plugins at project scope, recording each one
# for uninstall.sh. Nothing is declared in the user settings.
install_plugins() {
  log "Installing plugins for this project"
  remove_excluded_plugins
  local repo name plugin declared plugins installed="" added="" tmp
  plugins=$(selected_plugins)
  cd "$PROJECT_DIR"
  declared=$(jq -r '.extraKnownMarketplaces // {} | keys[]' "$SETTINGS" 2>/dev/null || true)
  while read -r repo name; do
    if ! grep -q -- "@$name\$" <<<"$plugins"; then continue; fi
    if grep -Fxq -- "$name" <<<"$declared"; then continue; fi
    log "Adding marketplace $name"
    if claude plugin marketplace add "$repo" --scope project >/dev/null; then
      added="$added$name"$'\n'
    else
      warn "Could not add marketplace $repo"
    fi
  done <<<"$MARKETPLACES"
  while IFS= read -r plugin; do
    [[ -n "$plugin" ]] || continue
    if claude plugin install "$plugin" --scope project; then
      installed="$installed$plugin"$'\n'
    else
      warn "Failed to install $plugin"
    fi
  done <<<"$plugins"
  cd - >/dev/null
  tmp=$(mktemp)
  jq --argjson p "$(json_array "$installed")" --argjson m "$(json_array "$added")" \
    '.plugins = (((.plugins // []) + $p) | unique) | .marketplaces = (((.marketplaces // []) + $m) | unique)' \
    "$MANIFEST" >"$tmp"
  cat "$tmp" >"$MANIFEST"
  rm -f "$tmp"
}

# Run every step in order and print what to do next.
main() {
  parse_args "$@"
  if [[ ! -t 0 ]] && { : </dev/tty; } 2>/dev/null; then
    exec </dev/tty
  fi
  if [[ -t 0 ]]; then INTERACTIVE=1; fi
  locate_kit
  check_target
  install_prerequisites
  install_tools
  detect_stack
  install_standards
  install_rtk
  install_read_once
  merge_settings
  update_claudeignore
  write_claude_md
  run_init
  install_plugins
  log "Done. Detected: $(printf '%s' "$STACKS" | paste -sd ',' - | sed 's/,/, /g')"
  cat <<EOF

Next steps:
  1. Restart Claude Code in $PROJECT_DIR.
  2. Read CLAUDE.md and .claudeignore and correct anything wrong.
  3. Optional: index the project for MemPalace with: mempalace init "$PROJECT_DIR"
     Turn a plugin off later with: claude plugin disable <name>@<marketplace> --scope project
  4. Review and commit .claude/, CLAUDE.md, and .claudeignore if the team should share them.
EOF
}

main "$@"; exit
