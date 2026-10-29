---
name: commit
description: Commit the current work following the project's git standards. Only the author can start this.
disable-model-invocation: true
---

# Commit

The author started this skill, which is the explicit authorization to commit. It covers one commit only.

1. Review what will be committed:

   ```bash
   git status
   git diff --cached
   git diff
   ```

2. Stage only files that belong to this change. Never stage secrets, local config, build output, or unrelated edits. If the right file set is unclear, ask the author.
3. Read the style of recent messages:

   ```bash
   git log --oneline -15
   ```

4. Write a short, descriptive message in that style that matches exactly what is staged.
5. Commit with a sign-off and no other trailers:

   ```bash
   git commit -s -m "<message>"
   ```

   Never add `Co-authored-by`. Never use `--no-verify` or `--amend`. If a hook fails, fix the cause and commit again.
6. Verify and report:

   ```bash
   git log -1 --stat
   ```

   Report the commit hash, the message, and a one-line summary of the files changed.
