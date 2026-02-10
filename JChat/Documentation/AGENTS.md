# JChat AGENTS Notes

Read `/Users/josh/Projects/JChat/JChat/Documentation/PROJECT_GUIDE.md` first.

## Critical Implementation Notes
- Main target uses explicit PBX file references. When adding Swift files, update PBX sections manually.
- API key is stored in Keychain only (`com.josh.jchat` / `openrouter-api-key`).
- Parameter precedence is chat override -> global fallback.
- Character stores identity/system prompt, not per-parameter overrides.
- Follow accessibility guidelines in `/Users/josh/Projects/JChat/JChat/Documentation/PROJECT_GUIDE.md`.
- Prefer Xcode MCP workflows (build/test/preview render) when available; setup and details are documented in `/Users/josh/Projects/JChat/JChat/Documentation/PROJECT_GUIDE.md`.

## Workflow Contract
- Branch from `main` using `codex/<topic>`.
- Commit freely on the branch.
- Run local validation before merging to main.
- No PRs, no CI.

## Legacy Context
Historical snapshots are in `/Users/josh/Projects/JChat/JChat/Documentation/archive/`.
