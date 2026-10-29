# Documentation Standards

## Objective

Write documentation that is simple, accurate, and easy to follow.

Write for someone using the project for the first time.

## Writing Style

Use:

- plain English
- short sentences
- active voice
- professional tone
- human-written language

Keep documentation concise and remove unnecessary verbosity.

Avoid:

- unnecessary explanations
- marketing language
- AI-style wording
- repetitive text
- long paragraphs

## Document Structure

Keep Markdown documents in the following order whenever applicable:

1. Brief Overview
2. Prerequisites
3. Deployment
4. Configuration
5. Cleanup or Undeployment

Use GitHub callouts wherever additional context is required.
Do not include the project directory structure.

## Content

Focus on practical usage instead of implementation details.

Prioritize:

- installation
- deployment
- configuration
- execution
- troubleshooting
- cleanup

Explain how to use the project unless implementation details are necessary.

Keep instructions complete. Do not skip required steps, even if they seem obvious.

## Commands

Write commands in the exact order they should be executed.

For each step:

- specify the directory where the command should be run
- include every required directory change
- do not assume the current working directory
- do not omit intermediate commands

Group related commands together in fenced code blocks.

## Comments

Write self-explanatory code whenever possible.

Comments should:

- be one line
- appear above the relevant command
- describe the command's purpose and intent
- remain valid even if bugs or implementation details change

Do not write comments that explain the issue being fixed.

Avoid inline comments unless absolutely necessary.

## Tables

Use Markdown tables whenever they improve readability, such as for:

- configuration options
- environment variables
- command summaries
- file locations
- port mappings

Avoid tables when simple lists are easier to read.

## Formatting

Do not use:

- emojis
- icons
- decorative symbols
- horizontal rules (`---`)
- em dashes (`—`)

Use Markdown headings to organize content.

Use fenced code blocks for commands and examples.

## Admonitions

Use GitHub Markdown callouts.

Examples:

> [!NOTE]
> Additional information.

> [!IMPORTANT]
> Required information.

> [!WARNING]
> Potential issue.

Prefer callouts over custom note formats.

## Maintenance

Whenever functionality changes:

- update the documentation
- remove obsolete instructions
- remove references to deleted files
- keep examples synchronized with the implementation

Documentation should always match the current codebase.
