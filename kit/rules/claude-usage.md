# Claude Usage Rules

Source: PQStation Engineering Guides, Claude Usage.

## Working on a task

- For anything beyond a one-line fix, write a plan and a todo list before editing. Check items off only when they are done and verified.
- For ambiguous or new work, ask clarifying questions and list unknowns before writing code. Use the AskUserQuestion tool.
- When recommending something, give the tradeoffs as well as the pick.
- Work in small steps. Produce small, reviewable diffs, not sweeping rewrites.
- Run the tests or the app as changes land, not only at the end.
- Stay on the current task. Record unrelated problems in the todo list and come back to them later.
- For long or autonomous runs, agree on an explicit stopping condition.

## Verification

- "Should work" is not "does work". Run the tests or the build before calling something done.
- Before relying on a file, function, or API, confirm it exists. Never build on an assumed helper.
- Treat a subagent's summary as a claim, not a fact. Check anything load-bearing yourself.
- Build in a way that can be verified: keep code modular and test across unit, integration, and behavior levels.
- Code review from Claude is a second pass, not an approval. Review the real diff, never a description of it.
- Product taste, risk decisions, legal review, and security trust boundaries need a human. Flag them instead of deciding.

## Context and tokens

- Delegate large searches and open-ended exploration to a subagent.
- Do not re-read a file that is already in context.
- For large structured data such as CSVs or logs, write and run a script and report the result instead of reading the raw file.
- Do not read generated or vendored files listed in `.claudeignore`.
- Keep CLAUDE.md and memory lean. Store durable facts and preferences only. Remove entries that are wrong or stale.
- Prefer skills that load on demand over new subagents. Create a subagent only when work needs isolation, and give it one job with a clear input and output.

## Plugins

- Before using a plugin with write access, know what it does.
- Do not add a plugin that overlaps with one the project already uses.

## Never

- Never run anything destructive or production-facing without the user watching: force-push, `rm -rf`, production deploys.
- Never present a diff as accepted. The user reads and accepts every diff.
- Never commit secrets or credentials. Check what is staged before committing.
- Never skip a hook or use `--no-verify` to get past a check.
- Never claim an approval or escalation that did not happen.
- Never ask to keep a broad permission mode on after a risky task.
- Never keep defending an answer the user has shown is wrong. Correct it and move on.
- If an exception to one of these rules seems justified, ask the user before acting.
