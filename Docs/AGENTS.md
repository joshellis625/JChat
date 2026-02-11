# JChat AGENTS Notes

Read `/Users/josh/Projects/JChat/Docs/PROJECT_GUIDE.md` first.

## Critical Implementation Notes
- Main target uses explicit PBX file references. When adding Swift files, update PBX sections manually.
- API key is stored in Keychain only (`com.josh.jchat` / `openrouter-api-key`).
- Parameter precedence is chat override -> global fallback.
- Character stores identity/system prompt, not per-parameter overrides.
- Follow accessibility guidelines in `/Users/josh/Projects/JChat/Docs/PROJECT_GUIDE.md`.
- Prefer `XcodeBuildMCP` workflows (build/test/preview render) when available; setup and details are documented in `/Users/josh/Projects/JChat/Docs/PROJECT_GUIDE.md`.

## Workflow Contract
- Use `codex/<topic>` branches for code changes.
- Documentation-only changes are made directly on `main`.
- Commit freely on the branch.
- Run local validation before merging to main.
- No PRs, no CI.
- Push only with explicit approval.
- After merge, delete merged feature branches locally and on origin.

## Legacy Context
Historical snapshots are in `/Users/josh/Projects/JChat/Docs/archive/`.
