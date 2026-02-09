# JChat Development Workflow

## Daily Loop
1. Pick one scoped improvement.
2. Create branch: `codex/<topic>`.
3. Implement and test locally.
4. Open PR with problem/approach/testing/rollback.
5. Merge after CI passes.

## Local Validation
Run before commit:
```bash
./scripts/check-local.sh

# or run commands directly:
xcodebuild build -project JChat.xcodeproj -scheme JChat -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO
xcodebuild test -project JChat.xcodeproj -scheme JChat -destination 'platform=macOS' -only-testing:JChatTests CODE_SIGNING_ALLOWED=NO
```

## UI Regression Checklist
For chat flows, validate:
- Send message
- Stream response
- Stop stream
- Edit message
- Delete message
- Regenerate assistant message
- Default model guardrail when unset

## PR Quality Checklist
- Scope is focused
- Behavior change is documented
- Risk is described
- Follow-up items listed

## CI Philosophy
CI is a safety net and a learning loop, not overhead.
Start minimal. Expand only when needed.
CI is configured to run build + unit tests (`JChatTests`) on GitHub-hosted `macos-26` runners.
