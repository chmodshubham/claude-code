# Claude Code Standards Kit

Sets up Claude Code in a project so Claude follows the engineering and documentation standards in [Engineering.md](Engineering.md) and [Documentation.md](Documentation.md). The installer adds rules, hooks, reviewer agents, skills, and plugins, adjusted to the project's language and tools. Everything Claude uses is set up inside the project's `.claude/` folder, so other projects on the Mac are not affected.

## Prerequisites

| Requirement            | Notes                                            |
| ---------------------- | ------------------------------------------------ |
| macOS 13 or later      | The installer supports macOS only                |
| Administrator password | Needed once if Homebrew is not installed         |
| Claude account         | Pro, Max, Team, Enterprise, or Anthropic Console |
| GitHub account         | Optional. Needed only for the code-review plugin |

The installer installs the programs it needs if they are missing: Homebrew, Xcode Command Line Tools, Claude Code, jq, Node.js, uv, shellcheck, the GitHub CLI, rtk, and MemPalace. These programs are installed on the Mac; their Claude Code setup stays in the project.

## Installation

### 1. Install Claude Code

Skip this step if `claude --version` already works. The installer also runs it for you.

```bash
# Install Claude Code
curl -fsSL https://claude.ai/install.sh | bash

# Load the new PATH in this terminal
exec zsh -l

# Sign in to your Claude account
claude auth login
```

### 2. Install the kit into your project

The kit is installed into one project at a time. The examples below use a project at `~/projects/my-app`. Replace `~/projects/my-app` with the folder of your own project, the folder that holds its code.

Use option A or option B. Both give the same result.

#### Option A: Run directly from GitHub (no download needed)

```bash
# Go to your project folder
cd ~/projects/my-app

# Download and run the installer in this folder
curl -fsSL https://raw.githubusercontent.com/chmodshubham/claude-code/main/install.sh | bash
```

#### Option B: Download the kit first, then run it

This keeps a copy of the kit at `~/claude-code`, separate from your project. Your project stays in its own folder.

```bash
# Download the kit to ~/claude-code (do this once)
git clone https://github.com/chmodshubham/claude-code.git ~/claude-code

# Go to your project folder
cd ~/projects/my-app

# Run the installer from the kit folder; it sets up the folder you are in
~/claude-code/install.sh
```

To update the kit later, run `git -C ~/claude-code pull`, then run the last two commands again.

> [!NOTE]
> The installer asks for your password if it installs Homebrew, and opens a browser sign-in if Claude Code is not signed in yet. On an existing project it then runs Claude once to write `CLAUDE.md`, which takes a few minutes.

### 3. Start Claude in the project

```bash
# Go to the project
cd ~/projects/my-app

# Start Claude Code
claude
```

Inside Claude, run `/hooks`, `/agents`, and `/skills` to confirm the kit loaded.

## Configuration

### Choose which plugins and tools to install

By default the installer installs every plugin and tool in the table below. To choose, add one of these options to the install command:

| Option            | Effect                                     |
| ----------------- | ------------------------------------------ |
| `--only NAMES`    | Install only the listed names              |
| `--without NAMES` | Install everything except the listed names |
| `--list`          | Print the names you can use                |

Separate names with commas and no spaces. Use `--only` or `--without`, not both. The rules, hooks, agents, and skills are always installed.

Install only caveman and rtk:

```bash
# Go to the project
cd ~/projects/my-app

# Install only the caveman plugin and the rtk tool
curl -fsSL https://raw.githubusercontent.com/chmodshubham/claude-code/main/install.sh | bash -s -- --only caveman,rtk
```

Install everything except caveman, ecc, and rtk:

```bash
# Go to the project
cd ~/projects/my-app

# Install everything except caveman, ecc, and rtk
curl -fsSL https://raw.githubusercontent.com/chmodshubham/claude-code/main/install.sh | bash -s -- --without caveman,ecc,rtk
```

From a clone, put the option after the script name, for example `~/claude-code/install.sh --only caveman,rtk`.

Running the installer again with a new choice removes plugins it installed earlier that are no longer selected.

| Name                       | Type   | What it does                                                 |
| -------------------------- | ------ | ------------------------------------------------------------ |
| `caveman`                  | Plugin | Shorter replies to save tokens                               |
| `mempalace`                | Plugin | Searchable memory of past sessions                           |
| `andrej-karpathy-skills`   | Plugin | Simple, surgical changes with stated assumptions             |
| `claude-code-setup`        | Plugin | Recommends hooks, skills, and MCP servers                    |
| `superpowers`              | Plugin | Brainstorm, plan, and test-driven implementation             |
| `ecc`                      | Plugin | Large set of agents and skills for review, TDD, and security |
| `code-simplifier`          | Plugin | Simplifies recently changed code                             |
| `code-refactoring`         | Plugin | Finds code smells and plans refactors                        |
| `codebase-cleanup`         | Plugin | Tech debt and dependency cleanup                             |
| `code-review`              | Plugin | Multi-agent pull request review                              |
| `code-documentation`       | Plugin | Generates API docs and guides                                |
| `documentation-generation` | Plugin | Mermaid diagrams and reference docs                          |
| `ui-ux-pro-max`            | Plugin | UI and UX patterns for frontend code                         |
| `impeccable`               | Plugin | Frontend UX and accessibility audits                         |
| `rtk`                      | Tool   | Compresses command output                                    |
| `read-once`                | Tool   | Stops repeated reads of unchanged files                      |

### Turn a plugin off or on later

Run from the project root:

```bash
# Go to the project
cd ~/projects/my-app

# Turn a plugin off for this project
claude plugin disable caveman@caveman --scope project

# Turn it back on
claude plugin enable caveman@caveman --scope project
```

Run `claude plugin list` to see each plugin's full `name@marketplace`.

To turn off rtk or read-once for this project, run the installer again without them:

```bash
# Go to the project
cd ~/projects/my-app

# Reinstall without rtk and read-once
curl -fsSL https://raw.githubusercontent.com/chmodshubham/claude-code/main/install.sh | bash -s -- --without rtk,read-once
```

### Turn off the planning gate for one session

The kit blocks file edits until `plan.md` and `todo.md` are updated in the session. To skip this for a quick fix:

```bash
# Start Claude without the planning gate
STANDARDS_PLAN_GATE=off claude
```

### What the kit installs

| Location                       | Contents                                                                         |
| ------------------------------ | -------------------------------------------------------------------------------- |
| `.claude/rules/standards-*.md` | Engineering, documentation, honesty, correctness, and Claude usage rules         |
| `.claude/hooks/standards/`     | Hooks that enforce the rules                                                     |
| `.claude/agents/`              | `standards-reviewer` and `docs-reviewer`                                         |
| `.claude/skills/`              | `plan-task`, `write-docs`, `finish-task`, and `commit` (run `/commit` to commit) |
| `.claude/rules/rtk.md`         | rtk instructions for Claude                                                      |
| `.claude/hooks/read-once/`     | read-once hooks                                                                  |
| `.claude/read-once-cache/`     | read-once cache, ignored by git                                                  |
| `.claude/settings.json`        | Hook wiring, permissions, and plugin list                                        |
| `CLAUDE.md`                    | Project notes and detected commands                                              |
| `.claudeignore`                | Generated and vendored paths for the project's languages                         |

> [!IMPORTANT]
> Commit `.claude/`, `CLAUDE.md`, and `.claudeignore` if your team should share the setup. Each teammate runs the installer once to get the plugins and tools.

## Cleanup

Remove the plugins, their marketplace entries, rtk, and read-once from a project. The rules, hooks, agents, skills, `CLAUDE.md`, and `.claudeignore` stay in place.

```bash
# Go to the project
cd ~/projects/my-app

# Remove the plugins, rtk, and read-once from this project
curl -fsSL https://raw.githubusercontent.com/chmodshubham/claude-code/main/uninstall.sh | bash
```

Also remove the programs the installer added to the Mac for them: the rtk program, MemPalace, and the third-party plugin marketplaces.

```bash
# Go to the project
cd ~/projects/my-app

# Remove the plugins and the programs
curl -fsSL https://raw.githubusercontent.com/chmodshubham/claude-code/main/uninstall.sh | bash -s -- --global
```

> [!WARNING]
> `--global` removes the third-party marketplaces and the rtk program, so other projects that use them stop working until you run the installer there again.

Homebrew, Claude Code, jq, Node.js, uv, shellcheck, and the GitHub CLI stay installed.
