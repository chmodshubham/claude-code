# Engineering Standards

## 1. Objective

Produce production-ready code that is correct, secure, maintainable, readable, and consistent with the existing project from the beginning.

**Prioritize correctness and long-term maintainability over speed of implementation.**

Before implementing a solution:

- Understand the problem statement and expected behavior thoroughly.
- Inspect the existing codebase, architecture, conventions, and dependencies.
- Identify the root cause of the problem rather than applying superficial fixes.
- Evaluate possible solutions and select the simplest correct approach.
- Preserve existing behavior unless a change is explicitly required.

Do not make assumptions when the available information is insufficient. Investigate the codebase or ask for clarification when necessary.

## 2. Core Engineering Principles

- Prefer simple, readable, and explicit implementations over clever or unnecessarily complex solutions.
- Reuse existing code, utilities, abstractions, and dependencies whenever appropriate.
- Avoid unnecessary files, wrappers, abstractions, layers, and directories.
- Keep related functionality together and separate unrelated responsibilities.
- Eliminate duplicated logic when doing so improves maintainability.
- Remove dead code when it is safe and relevant to the task.
- Keep functions focused on a single responsibility.
- Avoid temporary workarounds when a correct, maintainable solution is achievable.
- Follow established project architecture and conventions unless there is a clear technical reason to improve them.
- Minimize unrelated changes and preserve backward compatibility wherever possible.

Every implementation decision should prioritize correctness, clarity, security, and maintainability.

## 3. Mandatory Planning and Task Tracking

Before modifying any project, create or update the following documents in the appropriate existing location.

### 3.1 `plan.md`

Document the implementation plan before making code changes. Include:

- **Problem statement:** What needs to be solved and what the expected behavior should be.
- **Current implementation:** Relevant existing components, architecture, and behavior.
- **Root cause:** The underlying reason for the problem, supported by code inspection or other evidence.
- **Proposed solution:** The selected approach and why it is appropriate.
- **Affected components:** Files, modules, interfaces, dependencies, and configurations likely to change.
- **Compatibility considerations:** Existing behavior and interfaces that must be preserved.
- **Validation strategy:** Tests, checks, and other evidence required to verify correctness.
- **Risks and dependencies:** Relevant limitations, assumptions, and potential side effects.

Keep the plan precise and actionable. Update it if the investigation reveals that the original approach is incorrect or incomplete.

### 3.2 `todo.md`

Create a step-by-step task checklist derived from `plan.md`.

- Break the implementation into clear, verifiable tasks.
- Arrange tasks in a logical execution order.
- Include implementation, testing, documentation, and validation activities where applicable.
- Mark a task complete only after the corresponding work has been performed and verified.
- Add newly discovered issues to the end of the document without silently discarding existing tasks.
- Record unresolved issues, blockers, and deferred work explicitly.
- Keep the checklist synchronized with the actual implementation.

Do not mark work complete merely because the code has been written. Completion requires the applicable verification.

### 3.3 Document Management

Before creating planning documents or other files, check whether appropriate files already exist.

- Update existing documents rather than creating duplicates.
- Place documents in the project's established documentation or task-tracking location.
- Avoid introducing new directories solely to hold a small number of files unless the project structure warrants it.
- Maintain `plan.md` and `todo.md` throughout the task, not just at the beginning.

## 4. Repository Inspection and Project Organization

Before implementing changes, inspect the relevant repository structure, source files, configuration, tests, documentation, and existing implementation patterns.

Organize the project according to clear responsibilities:

- Business logic and core functionality
- Configuration and environment-specific settings
- Shared utilities and reusable components
- Automated tests and test fixtures
- Documentation and development resources

Follow these rules:

- Group related modules together.
- Separate unrelated concerns without overengineering.
- Keep files reasonably sized and focused.
- Use intuitive, consistent directory structures.
- Place new files in their most appropriate existing locations.
- Extend existing modules when doing so preserves clear responsibilities.
- Introduce new modules only when separation provides a meaningful architectural benefit.

Maintain consistency across the entire repository. Do not create a parallel structure when an established pattern already exists.

## 5. Coding Style and Consistency

Follow the conventions already established by the project, language, framework, and tooling.

Maintain consistent:

- Directory and file naming
- Function, class, and variable naming
- Formatting and indentation
- Import organization
- Logging conventions
- Error-handling patterns
- Configuration management
- Documentation and comments
- Testing structure and naming

Do not introduce a different coding style within an existing module without a compelling reason.

Use existing formatters, linters, static-analysis tools, and project configuration as the source of truth for style enforcement.

## 6. Naming Conventions

Use descriptive names that communicate intent and responsibility.

- Follow the naming convention already used by the project.
- Use `snake_case` or `camelCase` as appropriate for the language and existing codebase.
- Use consistent naming within the same language and module.
- Avoid ambiguous names and unnecessary abbreviations.
- Use established technical abbreviations when they are widely understood.
- Prefer names that explain purpose rather than implementation details.

Names should make the code easier to understand without requiring additional comments.

## 7. Configuration Management

- Centralize configuration according to the project's existing architecture.
- Avoid duplicating configurable values across multiple files.
- Never hardcode environment-specific values, credentials, tokens, or secrets.
- Use the appropriate configuration files, environment variables, or secret-management mechanisms.
- Keep configuration files declarative and free of executable logic whenever practical.
- Validate required configuration during initialization.
- Provide clear error messages for missing or invalid configuration.
- Define sensible defaults only when they are appropriate and safe.

All configurable values must follow the repository's established configuration conventions.

## 8. Function and Module Design

Functions and modules must have clear responsibilities and predictable behavior.

- Give each function one primary responsibility.
- Use descriptive names that reflect the function's purpose.
- Keep functions reasonably small and easy to follow.
- Make inputs, outputs, and side effects explicit.
- Avoid hidden state changes and unexpected side effects.
- Extract duplicated logic into reusable helpers when doing so improves clarity.
- Avoid premature abstraction and unnecessary indirection.
- Keep related logic together.
- Handle invalid inputs and exceptional conditions explicitly.

Introduce abstractions when they reduce complexity or establish a useful, reusable boundary—not merely to increase the number of modules or classes.

## 9. Comments and Documentation

Write self-explanatory code and use comments to clarify intent that is not obvious from the implementation.

### 9.1 Function Documentation

**Every function must have a short descriptive comment or docstring immediately before its definition.** As a general guideline, use two to three lines.

The description should explain:

- What the function does.
- Its purpose or responsibility.
- Any important behavior or constraints that are not obvious from its signature.

Follow the documentation format and placement conventions of the language and repository.

### 9.2 Comment Quality

Comments must:

- Be concise and relevant.
- Explain functionality, intent, invariants, or non-obvious decisions.
- Remain accurate as the implementation evolves.
- Appear close to the code they describe.

Avoid:

- Comments that merely repeat the code.
- Unnecessary inline comments.
- Comments describing personal preferences or the author's needs.
- Comments explaining only which bug was fixed or what issue prompted a change.
- Temporary, speculative, or outdated comments.

Do not add comments solely to explain the development process. Comments should help future maintainers understand the code itself.

## 10. Error Handling and Input Validation

Handle errors explicitly and consistently.

- Validate external inputs and arguments.
- Validate configuration and required dependencies.
- Detect missing files, resources, permissions, and prerequisites where relevant.
- Fail early when execution cannot proceed safely or correctly.
- Return meaningful error messages and appropriate exit codes.
- Preserve useful error context when propagating exceptions.
- Handle recoverable failures according to the project's established conventions.
- Ensure resources are released correctly when errors occur.

Never silently ignore failures, swallow exceptions without justification, or report success when an operation has failed.

Avoid redundant validation when the same guarantee is already enforced by a trusted boundary and additional checks provide no meaningful benefit.

## 11. Security Requirements

Security must not be weakened to simplify implementation or accelerate delivery.

Always:

- Validate and appropriately constrain untrusted input.
- Use safe APIs and parameterized operations where available.
- Quote shell variables and handle special characters correctly.
- Prevent command injection, path traversal, and other relevant injection vulnerabilities.
- Protect credentials, tokens, keys, and other sensitive information.
- Avoid logging secrets or sensitive data.
- Apply least-privilege principles.
- Handle temporary files, permissions, and filesystem operations safely.
- Use established cryptographic libraries and secure configurations.
- Follow the project's dependency-management and vulnerability-handling practices.

Consider relevant security implications when changing interfaces, authentication, authorization, serialization, file handling, network operations, or cryptographic functionality.

Do not introduce insecure defaults, disable security checks to make tests pass, or suppress security warnings without a justified and documented decision.

## 12. Performance and Resource Management

Avoid unnecessary resource consumption and duplicated work.

- Minimize unnecessary subprocess creation.
- Avoid repeated parsing, computation, and filesystem operations.
- Reuse computed results when doing so is correct and beneficial.
- Manage memory, file handles, connections, and other resources appropriately.
- Avoid unnecessary dependencies and expensive initialization.
- Consider algorithmic complexity and expected input sizes.
- Prefer straightforward implementations unless performance requirements justify additional complexity.

Optimize when there is a demonstrated or reasonably established benefit. Do not sacrifice correctness, security, or readability for speculative performance improvements.

## 13. Testing and Validation

Validation is a mandatory part of implementation, not an optional final step.

Before considering a task complete:

1. Review the implementation against the problem statement and `plan.md`.
2. Verify that the root cause has been addressed.
3. Confirm that existing behavior is preserved except where changes are explicitly required.
4. Add or update tests following the project's existing testing conventions.
5. Cover relevant normal cases, edge cases, invalid inputs, and failure conditions.
6. Run available automated tests.
7. Run applicable formatters, linters, type checkers, and static-analysis tools.
8. Review the final changes for unnecessary complexity, duplication, security issues, and unintended side effects.
9. Inspect the version-control diff to identify unrelated or accidental modifications.
10. Update `todo.md` with verified completion status and any outstanding issues.

Do not claim that a test or validation step succeeded unless it was actually executed and its result was checked.

If a validation step cannot be performed, record the reason and its impact. Distinguish clearly between verified results, unverified behavior, and known failures.

## 14. Handling Additional Issues

During implementation, investigate relevant problems discovered in the affected code or surrounding components.

- Do not ignore defects that could compromise correctness, security, reliability, or the requested outcome.
- Add newly discovered issues to the end of `todo.md`, including a concise description and, where practical, the affected component and priority.
- Resolve issues that are necessary for the current solution or that can be addressed safely within the task's scope.
- Avoid unrelated refactoring or uncontrolled expansion of the task.
- Track deferred issues explicitly, with a reason for deferral and any known impact.
- Never silently mark an unresolved issue as completed.

The goal is to deliver a correct solution while maintaining visibility into other known problems.

## 15. Efficient Execution and Reporting

Keep the development process efficient without compromising engineering quality.

### 15.1 Execution

- Inspect before modifying.
- Plan before implementing.
- Implement the selected solution rather than a temporary workaround.
- Validate continuously where practical.
- Keep changes focused and reviewable.
- Update task-tracking documents as work progresses.
- Avoid repeating investigations or checks without a reason.

### 15.2 Documentation and Terminal Output

Use `plan.md` and `todo.md` to maintain detailed implementation notes and task status.

Keep terminal output concise:

- Report the current action or significant result briefly.
- Summarize important findings rather than repeatedly printing lengthy explanations.
- Direct detailed plans, investigation results, and task breakdowns to the appropriate document.
- Include relevant command failures and validation outcomes.
- Avoid dumping large amounts of documentation into the terminal when the information belongs in a file.

Do not hide important errors or omit information necessary to understand the result.

### 15.3 Completion Report

At the end of the task, provide a concise summary containing:

- What was implemented.
- The main files or components changed.
- Tests and validation commands executed, with their actual outcomes.
- Any unresolved issues, blockers, or deferred tasks.
- The locations of `plan.md` and `todo.md`.

The report must accurately reflect the repository state. Do not claim full completion if required work or validation remains outstanding.

## 16. Definition of Done

A task is complete only when all applicable conditions are satisfied:

- [ ] The problem and expected behavior are understood.
- [ ] The implementation plan has been documented.
- [ ] The task checklist has been created or updated.
- [ ] The root cause has been addressed with a maintainable solution.
- [ ] Existing behavior is preserved unless a change was explicitly required.
- [ ] Code follows project conventions and architectural boundaries.
- [ ] Required documentation and comments are accurate.
- [ ] Relevant tests have been added or updated.
- [ ] Applicable tests, formatters, linters, and static checks have been executed.
- [ ] The implementation and final diff have been reviewed.
- [ ] Additional issues have been resolved or recorded as outstanding.
- [ ] `todo.md` reflects the verified status of all tasks.
- [ ] The final report accurately describes the changes and validation results.

## 17. Git and Commit Standards

- **Never commit without explicit authorization from the author.**
- Always use `git commit -s` to include the `Signed-off-by` trailer.
- Keep commit messages brief, descriptive, and consistent with the repository's existing commit history.
- Ensure the commit message accurately reflects the changes included in the commit.
- Review the staged changes before committing and include only files relevant to the intended commit.
- **Never add co-authors without explicit authorization from the author.** Adding `Co-authored-by` attribution for Claude or any other AI assistant is strictly prohibited unless explicitly requested.
- Never amend, rewrite, or alter existing commits without explicit authorization.
- After committing, verify the commit and report its hash, message, and summary.

**Final principle:** Understand the problem first, choose the simplest correct solution, implement it properly, verify the result, and document anything that remains unresolved. Speed is valuable only when it does not compromise correctness, security, or maintainability.
