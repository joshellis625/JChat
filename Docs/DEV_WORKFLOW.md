# JChat Development Workflow

## Daily Loop
1. Pick one scoped improvement or group of related improvements. Scan all files for "TODO" comments.
2. If it is a code change, create branch: `codex/<topic>`. If it is docs-only, work directly on `main`.
3. Implement and test locally. Commit freely as work progresses.
4. Request explicit approval before any push.
5. Push only after approval, then merge to `main` locally (no PR).
6. If it breaks, revert the merge commit or reset to last good tag.

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
