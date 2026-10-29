---
name: finish-task
description: Run the Definition of Done before declaring a task complete. Use when implementation is finished and before giving the final report.
---

# Finish a task

Work through every step. Do not skip a step because it seems fine.

1. Re-read `plan.md`. Confirm the change solves the problem statement and the root cause, and that existing behavior is preserved except where a change was requested.
2. Confirm tests were added or updated for normal cases, edge cases, invalid input, and failures, following the project's test conventions.
3. Run every test, formatter, linter, type checker, and static analysis command the project has (see the Commands section of CLAUDE.md). Read each result. Fix failures and rerun.
4. Run the `standards-reviewer` agent. Fix every violation it reports, then rerun step 3 if code changed.
5. If any Markdown doc changed, or the behavior that a doc describes changed, update the docs and run the `docs-reviewer` agent. Fix what it reports.
6. Read the full diff and remove unrelated or accidental changes:

   ```bash
   git status
   git diff
   ```

7. Update `todo.md`: tick only verified items, and list open issues, blockers, and deferred work with reasons.
8. Give the completion report:
   - What was implemented.
   - Main files or components changed.
   - Validation commands run, with their actual results.
   - Unresolved issues, blockers, and deferred tasks.
   - Paths of `plan.md` and `todo.md`.

If any required step could not be done, say so plainly in the report and do not call the task complete.
