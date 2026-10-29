# Engineering Code Standards

Every implementation decision favors correctness, clarity, security, and maintainability.

## Design

- Prefer simple, readable, explicit code over clever code.
- Reuse existing code, utilities, abstractions, and dependencies before adding new ones.
- Do not add unnecessary files, wrappers, layers, abstractions, or directories.
- Keep related code together and unrelated responsibilities apart, without overengineering.
- Remove duplicated logic when that improves maintainability. Remove dead code when it is safe and relevant to the task.
- Do not ship temporary workarounds when a correct, maintainable fix is achievable.
- Follow the existing architecture unless there is a clear technical reason to improve it. Keep unrelated changes out. Preserve backward compatibility where possible.

## Project organization

- Separate business logic, configuration, shared utilities, tests and fixtures, and docs.
- Put new files in the most fitting existing location. Extend an existing module when its responsibility stays clear. Add a new module only for a real architectural benefit.
- Keep files reasonably sized. Never create a parallel structure next to an established pattern.

## Style and naming

- Match the project's existing conventions for file and directory names, identifiers, formatting, imports, logging, error handling, configuration, comments, and tests. Do not introduce a different style inside an existing module.
- The project's formatters, linters, and static analysis config are the source of truth for style.
- Use descriptive names that state purpose, not implementation. Use `snake_case` or `camelCase` as the language and codebase already do. Avoid ambiguous names and unneeded abbreviations; widely known technical abbreviations are fine.

## Configuration

- Centralize configuration the way the project already does. Do not duplicate configurable values across files.
- Never hardcode environment-specific values, credentials, tokens, or secrets. Use config files, environment variables, or the secret manager. A hook rejects secrets in written code.
- Keep config declarative. Validate required config at startup with clear error messages. Add defaults only when they are safe.

## Functions and modules

- One primary responsibility per function, with a name that states it. Keep functions small.
- Make inputs, outputs, and side effects explicit. No hidden state changes.
- Extract duplicated logic into helpers when it improves clarity. Avoid premature abstraction and indirection.
- Handle invalid input and exceptional conditions explicitly.

## Comments

- Every function gets a short comment or docstring, usually two or three lines, directly before its definition (or as the docstring where the language uses one). It says what the function does, its purpose, and any behavior or constraint not obvious from the signature. A hook rejects new functions without one.
- Comments explain intent, invariants, and non-obvious decisions. Keep them short, accurate, and next to the code.
- Never write comments that repeat the code, explain which bug was fixed or what prompted a change, describe the author's preferences, or narrate the development process. No temporary, speculative, or stale comments. A hook flags bug-fix comments.

## Errors and validation

- Validate external input, arguments, configuration, dependencies, files, resources, and permissions.
- Fail early when execution cannot continue safely. Return meaningful messages and correct exit codes. Keep error context when re-raising.
- Release resources on error. Never swallow exceptions or report success after a failure.
- Do not repeat validation that a trusted boundary already guarantees.

## Security

- Never weaken security to simplify or speed up delivery.
- Validate and constrain untrusted input. Use safe APIs and parameterized operations.
- Quote shell variables and handle special characters. A hook runs shellcheck on shell scripts.
- Prevent command injection, path traversal, and other injection flaws.
- Protect and never log secrets or sensitive data. Apply least privilege.
- Handle temporary files, permissions, and filesystem operations safely. Use established crypto libraries and secure settings.
- Follow the project's dependency and vulnerability practices.
- Think through security when changing interfaces, auth, serialization, file handling, networking, or crypto.
- Never add insecure defaults, disable security checks to pass tests, or silence security warnings without a documented reason.

## Performance

- Avoid unnecessary subprocesses, repeated parsing, repeated computation, and repeated filesystem work. Reuse results when correct.
- Manage memory, file handles, and connections. Avoid needless dependencies and expensive initialization.
- Consider algorithmic complexity and expected input size.
- Optimize only for a demonstrated or well-established benefit. Never trade correctness, security, or readability for speculative speed.
