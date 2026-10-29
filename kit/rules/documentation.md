# Documentation Standards

Apply these to every Markdown file you write: READMEs, guides, docs, plan.md, and todo.md. Use the `write-docs` skill for new docs. A hook rejects formatting violations.

## Reader and style

- Write for someone using the project for the first time.
- Use plain English, short sentences, active voice, and a professional, human tone.
- Be concise. No marketing language, AI-style wording, repetition, long paragraphs, or explanations the reader does not need.

## Structure

Order sections like this, using the ones that apply:

1. Overview (brief)
2. Prerequisites
3. Deployment
4. Configuration
5. Cleanup or Undeployment

Never include the project directory structure.

## Content

- Focus on practical use: installation, deployment, configuration, execution, troubleshooting, and cleanup. Explain implementation only when the reader needs it.
- Keep instructions complete. Never skip a required step, even an obvious one.

## Commands

- List commands in the exact order they must run.
- For each step, say which directory to run it in, include every `cd`, never assume the current directory, and never leave out an intermediate command.
- Group related commands in fenced code blocks.
- Put a one-line comment above a command to state its purpose. Write comments that stay true if bugs or implementation details change. Never explain the bug being fixed. Avoid inline comments.

## Tables

Use Markdown tables for configuration options, environment variables, command summaries, file locations, and port mappings. Use a list when a list is easier to read.

## Formatting

- Never use emojis, icons, decorative symbols, horizontal rules (`---`), or em dashes.
- Organize with Markdown headings. Put commands and examples in fenced code blocks.
- For extra context, use GitHub callouts, never custom formats such as `**Note:**`:

```markdown
> [!NOTE]
> Additional information.

> [!IMPORTANT]
> Required information.

> [!WARNING]
> Potential issue.
```

## Maintenance

When functionality changes, update the docs in the same task: remove obsolete instructions and references to deleted files, and keep examples in sync with the code. Docs must always match the current codebase.
