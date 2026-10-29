---
name: write-docs
description: Write or update project documentation such as a README, setup guide, or runbook following the project's documentation standards. Use whenever creating or substantially editing a Markdown doc.
---

# Write documentation

## 1. Check what exists

Find existing docs and update them rather than adding duplicates. Read the code, scripts, and config the doc describes so every command and value is real. Run commands where it is safe, to confirm they work.

## 2. Use this skeleton

Keep only the sections that apply, in this order:

````markdown
# <Project name>

<Two or three sentences: what it is and who it is for.>

## Prerequisites

| Tool | Version | Install |
|---|---|---|
| <tool> | <version> | `<command>` |

## Deployment

Run from the repository root:

```bash
# Install dependencies
cd <repo-root>
<command>

# Start the service
<command>
```

## Configuration

| Variable | Required | Default | Description |
|---|---|---|---|
| `<NAME>` | Yes | none | <what it controls> |

## Cleanup

```bash
# Remove deployed resources
cd <repo-root>
<command>
```
````

Add a Troubleshooting section before Cleanup only when there are known problems to describe.

## 3. Rules to apply while writing

- Plain English, short sentences, active voice. Write for a first-time user.
- Every command block states its directory and includes every `cd`. Commands appear in the order they must run. No steps skipped.
- One-line comment above each command, describing its purpose. No inline comments. Never explain a bug fix.
- Use tables for options, variables, command summaries, file locations, and ports.
- Use `> [!NOTE]`, `> [!IMPORTANT]`, `> [!WARNING]` callouts for extra context.
- Never use emojis, icons, decorative symbols, `---` rules, em dashes, or a directory tree.

## 4. Review

Run the `docs-reviewer` agent on the files you changed and fix everything it reports.
