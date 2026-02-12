# JChat Development Workflow

## Daily Loop
1. Pick one scoped improvement (or one tightly related set).
2. If it is code, create `codex/<topic>` branch. If docs-only, you may work on `main`.
3. Implement and test locally.
4. Request explicit approval before any push.
5. Push only after approval, then merge locally (no PR flow).
6. If needed, revert with a normal commit-based rollback.
7. Delete merged feature branches locally and on origin.

## AI Mode Selection
- `Direct Codex`: quick, low-risk implementation.
- `Codex Plan mode`: when tradeoffs/options must be compared first.
- `OpenSpec`: when behavior/state/cost logic needs explicit change history.

If unsure, start direct and escalate only if complexity grows.

## Local Validation Standard
Fast iteration default (use this on most edit cycles):
```bash
xcodebuildmcp macos build --project-path /Users/josh/Projects/JChat/JChat.xcodeproj --scheme JChat --configuration Debug --output text
```

Launch/stop check (when UI behavior changed):
```bash
xcodebuildmcp macos build-and-run --project-path /Users/josh/Projects/JChat/JChat.xcodeproj --scheme JChat --configuration Debug --output text
xcodebuildmcp macos stop --app-name JChat --output text
```

Full suite check (run before push for risky behavior changes):
```bash
xcodebuildmcp macos test --project-path /Users/josh/Projects/JChat/JChat.xcodeproj --scheme JChat --configuration Debug --output text
```

Rules:
- Prefer XcodeBuildMCP macOS workflows. Do not use simulator-target validation in the default loop.
- If an MCP client does not expose a needed wrapper tool, run the equivalent `xcodebuildmcp ...` command directly in terminal.

## V2 Regression Gate
Before merge/push, run through:
- `/Users/josh/Projects/JChat/Docs/REGRESSION_CHECKLIST.md`

## Multi-Agent Organization
- Shared project truth: `Docs/` + `CONTRIBUTING.md`
- Tool-specific instructions: tool folders (`.codex/`, `.claude/`, etc.)
- Avoid duplicate policy docs; link to canonical docs.

## Branch Cleanup
```bash
git branch -d codex/<topic>
git push origin --delete codex/<topic>
```

## CI Philosophy
CI is intentionally disabled for this solo workflow. Local validation is the release gate.
