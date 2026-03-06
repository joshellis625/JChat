# Contributing

Solo hobby project. Professional workflow standards keep it maintainable over time.

---

## Branching

- `main` is stable
- All code changes start on a typed branch:
  - `feature/<topic>` — new functionality
  - `fix/<topic>` — bug fixes
  - `chore/<topic>` — cleanup or refactoring with no behavior change
  - `docs/<topic>` — documentation only (can go directly to `main`)
- Never push to any branch without explicit approval

---

## Commit Style

[Conventional Commits](https://www.conventionalcommits.org/):

| Prefix | Use |
|--------|-----|
| `feat:` | New behavior |
| `fix:` | Bug fix |
| `refactor:` | Internal cleanup, no behavior change |
| `docs:` | Documentation only |
| `chore:` | Project or tooling maintenance |

---

## Definition of Done

Before pushing:

1. Local macOS build passes
2. Full test suite passes for risky changes (streaming, persistence, networking, usage accounting)
3. UI changes include a manual UX check
4. Changed behavior is documented
5. `Docs/CHANGELOG_INTERNAL.md` is updated

---

## Solo Workflow

1. Create branch: `git checkout -b feature/<topic>` (or appropriate prefix)
2. Implement one scoped change or small group of related changes
3. Run local checks (see `Docs/PROJECT_GUIDE.md` for commands)
4. Commit with a clear message
5. Request explicit approval before pushing
6. Push after approval, then merge locally
7. Delete merged branch locally and on origin:

```bash
git branch -d feature/<topic>
git push origin --delete feature/<topic>
```

---

## CI/CD

No CI. Local validation is the quality gate. No PR flow.

Validation commands: `Docs/PROJECT_GUIDE.md`
