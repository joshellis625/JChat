# JChat Development Workflow

## Daily Loop
1. Pick one scoped improvement or group of related improvements. Scan all files for "TODO" comments.
2. If it is a code change, create branch: `codex/<topic>`. If it is docs-only, work directly on `main`.
3. Implement and test locally. Commit freely as work progresses.
4. Request explicit approval before any push.
5. Push only after approval, then merge to `main` locally (no PR).
6. If it breaks, revert the merge commit or reset to last good tag.
7. After merge, delete merged feature branches locally and on origin.

## AI Mode Selection
Choose the lightest mode that fits the task:

1. `Direct Codex`:
For quick, low-risk changes where you already know what you want.

2. `Codex Plan mode`:
For design choices, tradeoff decisions, or when requirements are fuzzy.
Use this before implementation to avoid rework.

3. `OpenSpec`:
For behavior/state/cost logic or changes you may need to explain, validate, or reverse later.
Use `/opsx:ff` when you want fast artifacts with minimal overhead.

If unsure, start with `Direct Codex` and only escalate when complexity appears.

## Multi-Agent Organization
If using multiple AI tools:
- Keep shared project truth in `CONTRIBUTING.md` and `Docs/`.
- Keep tool-specific instructions in that tool's folder (`.codex/`, `.claude/`, etc.).
- Avoid duplicate policy docs; use links back to canonical docs.

## Branch Cleanup
After a branch is merged and validated:
```bash
git branch -d codex/<topic>
git push origin --delete codex/<topic>
```

## Local Validation
Run before commit:
```bash
xcodebuildmcp doctor

./scripts/check-local.sh

# or run commands directly:
xcodebuild build -project JChat.xcodeproj -scheme JChat -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO
xcodebuild test -project JChat.xcodeproj -scheme JChat -destination 'platform=macOS' -only-testing:JChatTests CODE_SIGNING_ALLOWED=NO
```

## UI Regression Checklist
Use the canonical checklist:
- `/Users/josh/Projects/JChat/Docs/REGRESSION_CHECKLIST.md`

## CI Philosophy
CI is currently **disabled by choice** for this solo project.
