# Contributing to JChat

This project is a solo hobby app, but we use professional workflow standards so the codebase stays maintainable over time.

## Branching Rules
- `main` is stable.
- All work starts on a feature branch: `codex/<short-topic>`.
- Do not commit directly to `main` unless there is an explicit emergency reason.

## Pull Request Rules
- Open a PR for every branch, even when working solo.
- Keep PRs small and focused on one clear outcome.
- Use the PR template and fill every section.

## Commit Style
Use clear conventional commit prefixes:
- `feat:` new behavior
- `fix:` bug fix
- `refactor:` internal cleanup with no behavior change
- `docs:` documentation changes
- `chore:` project/tooling maintenance

## Definition of Done
Before merging:
1. Build and tests pass locally.
2. CI checks pass (currently build-focused due GitHub runner OS limits).
3. UI changes include a manual UX check.
4. Any changed behavior is documented.
5. Risks and follow-up work are recorded in the PR.

## Recommended Solo Workflow
1. Create branch: `git checkout -b codex/<topic>`
2. Implement one scoped change.
3. Run local checks.
4. Commit with clear message.
5. Open PR and review your own diff.
6. Merge only after checks pass.

## CI/CD Scope for Now
- CI is required.
- We currently run minimal safety checks (build in GitHub Actions; tests run locally in Xcode on macOS 26).
- Full CD/release automation is intentionally deferred.
