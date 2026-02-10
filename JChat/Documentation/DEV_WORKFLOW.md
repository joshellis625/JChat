# JChat Development Workflow

## Daily Loop
1. Pick one scoped improvement.
2. Create branch: `codex/<topic>`.
3. Implement and test locally.
4. Merge to main (no PR).
5. If it breaks, revert the merge commit or reset to last good tag.

## Local Validation
Run before commit:
```bash
./scripts/check-local.sh

# or run commands directly:
xcodebuild build -project JChat.xcodeproj -scheme JChat -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO
xcodebuild test -project JChat.xcodeproj -scheme JChat -destination 'platform=macOS' -only-testing:JChatTests CODE_SIGNING_ALLOWED=NO
```

## UI Regression Checklist
Use the canonical checklist:
- `/Users/josh/Projects/JChat/JChat/Documentation/REGRESSION_CHECKLIST.md`

## CI Philosophy
CI is currently **disabled by choice** for this solo project.
