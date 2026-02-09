# JChat AGENTS Notes

Read `/Users/josh/Projects/JChat/JChat/Documentation/PROJECT_GUIDE.md` first.

## Critical Implementation Notes
- Main target uses explicit PBX file references. When adding Swift files, update PBX sections manually.
- API key is stored in Keychain only (`com.josh.jchat` / `openrouter-api-key`).
- Parameter precedence is chat override -> global fallback.
- Character stores identity/system prompt, not per-parameter overrides.
- Avoid purple in UI due to accessibility constraints.

## Workflow Contract
- Branch from `main` using `codex/<topic>`.
- Open a PR for every change.
- Ensure CI passes before merge.

## Legacy Context
Historical snapshots are in `/Users/josh/Projects/JChat/JChat/Documentation/archive/`.
