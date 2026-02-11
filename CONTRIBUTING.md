# Contributing to JChat

This project is a solo hobby app, but we use professional workflow standards so the codebase stays maintainable over time.

## Branching Rules
- `main` is stable.
- Code changes start on a feature branch: `codex/<short-topic>`.
- Documentation-only changes are made directly on `main`.
- Do not push any branch or `main` without explicit approval.

## Commit Style
Use clear conventional commit prefixes:
- `feat:` new behavior
- `fix:` bug fix
- `refactor:` internal cleanup with no behavior change
- `docs:` documentation changes
- `chore:` project/tooling maintenance

## Definition of Done
Before pushing:
1. Build and tests pass locally.
2. UI changes include a manual UX check.
3. Any changed behavior is documented.
4. Risks and follow-up work are recorded in notes/changelog.

## Recommended Solo Workflow
1. For code changes, create branch: `git checkout -b codex/<topic>`. For docs-only changes, work on `main`.
2. Implement one scoped change or small related group of changes.
3. Run local checks.
4. Commit freely with clear messages.
5. Request explicit approval before any push.
6. Push only after approval, then merge locally when ready.

## CI/CD Scope for Now
- CI is disabled by choice for this solo workflow.
- Local validation is the quality gate.
- No PR flow is used.
