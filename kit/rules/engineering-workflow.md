# Engineering Workflow

Correctness and long-term maintainability come before speed. These steps are mandatory for every change to this project.

## Before changing anything

1. Understand the problem and the expected behavior. If information is missing, investigate the code or ask the user. Never assume.
2. Inspect the relevant structure, source files, configuration, tests, docs, and existing patterns.
3. Find the root cause with evidence from the code. Do not apply a surface fix.
4. Compare possible solutions and pick the simplest correct one. Preserve existing behavior unless the user asked for a change.
5. Create or update `plan.md` and `todo.md` with the `plan-task` skill. A hook blocks file edits until both are updated in this session.

## plan.md

Must contain these sections: Problem statement, Current implementation, Root cause (with evidence), Proposed solution (and why), Affected components, Compatibility considerations, Validation strategy, Risks and dependencies. Keep it precise. Update it when the investigation shows the approach was wrong or incomplete.

## todo.md

- A step-by-step checklist derived from `plan.md`, in execution order, covering implementation, tests, docs, and validation.
- Mark an item done only after the work is done and verified. Written code is not done code.
- Append newly found issues at the end with a short description, affected component, and priority. Never delete existing items silently.
- Record blockers, unresolved issues, and deferred work with the reason and impact.
- Keep it in sync with the real state at all times. A hook blocks stopping if code changed after the last `todo.md` update.

## Document placement

Check for existing `plan.md`, `todo.md`, and docs before creating files. Update existing files instead of duplicating them. Use the project's existing docs or task location. Do not create a directory just to hold a few files.

## Validation

Validation is part of the work, not a final extra. Before calling a task complete:

1. Check the change against the problem statement and `plan.md`, and confirm the root cause is fixed.
2. Confirm existing behavior is preserved unless the user asked for a change.
3. Add or update tests that follow the project's test conventions. Cover normal cases, edge cases, invalid input, and failures.
4. Run the tests, formatters, linters, type checkers, and static analysis the project has. A hook blocks stopping if code changed after the last validation run.
5. Run the `standards-reviewer` agent on the diff and fix what it reports.
6. Read `git diff` and remove unrelated or accidental changes.
7. Update `todo.md` with the verified status and anything still open.

Never say a check passed unless you ran it and read the result. If a check cannot run, record why and what that means. Keep verified results, unverified behavior, and known failures clearly separate.

## Additional issues

Investigate problems you find in the affected code. Fix the ones that the solution needs or that are safe and in scope. Add every other one to the end of `todo.md` with a reason for deferring it. Do not expand the task with unrelated refactoring. Never mark an unresolved issue done.

## Execution and output

- Inspect before modifying, plan before implementing, validate as you go. Do not repeat investigations without a reason.
- Keep changes small, focused, and reviewable.
- Keep terminal output short: the current action, key results, failures, and validation outcomes. Put detailed plans, findings, and task breakdowns in `plan.md` and `todo.md`, not in the terminal. Never hide errors.

## Completion report

End every task with a short report. A hook checks it for the plan.md and todo.md locations.

- What was implemented.
- The main files or components changed.
- The validation commands run and their actual results.
- Unresolved issues, blockers, and deferred tasks.
- Where `plan.md` and `todo.md` are.

Do not claim full completion while required work or validation is still open. The `finish-task` skill runs the full Definition of Done.

## Definition of Done

All that apply must be true: problem understood; plan documented; checklist updated; root cause fixed with a maintainable solution; existing behavior preserved; project conventions followed; docs and comments accurate; tests added or updated; tests, formatters, linters, and static checks run; implementation and final diff reviewed; extra issues fixed or recorded; `todo.md` shows verified status; final report accurate.

## Git

- Never commit unless the author explicitly asks in this conversation. The `commit` skill is the procedure.
- Always use `git commit -s`. Never add a `Co-authored-by` trailer for Claude or anyone else unless the author explicitly asks.
- Keep commit messages short, descriptive, and in the style of the existing history. The message must match the staged changes.
- Review staged changes and stage only files that belong to the commit.
- Never amend, rebase, or rewrite commits without explicit authorization.
- After committing, verify the commit and report its hash, message, and summary.
