---
name: plan-task
description: Create or update plan.md and todo.md before changing the project. Use at the start of every task that modifies files, and whenever the investigation changes the approach.
---

# Plan a task

## 1. Find existing files

Look for existing planning files before creating new ones:

```bash
find . -maxdepth 4 \( -iname plan.md -o -iname todo.md \) -not -path '*/node_modules/*' -not -path '*/.git/*'
```

If they exist, update them in place. If not, create them in the project's docs or task location, or at the root if there is none. Do not create a new directory for them.

## 2. Investigate first

Read the relevant code, config, tests, and docs. Find the root cause with evidence (file and line). If key information is missing, ask the user with AskUserQuestion before writing the plan.

## 3. Write plan.md

Use exactly these sections. Keep each one precise and actionable.

```markdown
# Plan: <task title>

## Problem statement
What must be solved and the expected behavior.

## Current implementation
Relevant components, architecture, and current behavior.

## Root cause
The underlying cause, with evidence (file:line, logs, test output).

## Proposed solution
The chosen approach and why it is the simplest correct one. Alternatives rejected and why.

## Affected components
Files, modules, interfaces, dependencies, and configuration likely to change.

## Compatibility considerations
Behavior and interfaces that must stay the same.

## Validation strategy
Tests to add or update, and the exact commands that prove correctness.

## Risks and dependencies
Limitations, assumptions, and possible side effects.
```

For a task that continues earlier work, add a dated section instead of overwriting history that is still relevant.

## 4. Write todo.md

```markdown
# Todo: <task title>

- [ ] <implementation step>
- [ ] Add or update tests for <cases>
- [ ] Run <test, lint, type check commands>
- [ ] Update docs: <files> (or: no doc change needed because <reason>)
- [ ] Review the diff with the standards-reviewer agent
- [ ] Final report

## Discovered issues
- [ ] <issue> | <component> | <priority> | <fix now or deferred: reason>
```

Order steps in execution order. Each step must be verifiable.

## 5. Keep them current

- Tick an item only after it is done and verified.
- Append new issues under Discovered issues. Never delete items silently.
- Update `plan.md` if the approach changes.
