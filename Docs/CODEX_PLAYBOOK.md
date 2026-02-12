# JChat Codex Playbook

Use this to work with Codex efficiently on the current V2 rebuild.

## Prompt Pattern (Best Results)
Include:
1. Goal
2. Constraints
3. Files likely involved
4. Acceptance criteria
5. Expected output format

Example:
"Fix long-chat scroll freezes in `/Users/josh/Projects/JChat/JChat/V2/UI/V2ShellViews.swift` and `/Users/josh/Projects/JChat/JChat/Core/Conversation/ConversationStore.swift`. Keep V2 visual style and preserve streaming UX. Provide exact files changed and test command used."

## High-Value Task Types
- Freeze/performance triage
- Streaming reliability improvements
- V2 UI simplification/polish
- Refactors with behavior parity
- Documentation sync

## After Any Change, Ask
- "What could still break?"
- "What tests should be added next?"
- "What should be a separate branch next time?"

## XcodeBuildMCP Workflow (Preferred)
When available, ask Codex to:
1. Use macOS `XcodeBuildMCP` workflows first (`build`, then `build-and-run` + `stop` when needed).
2. Run focused UI checks for V2 views.
3. Iterate with screenshot-backed feedback.

Prompt example:
"Use `XcodeBuildMCP` to validate `/Users/josh/Projects/JChat/JChat/V2/UI/V2ShellViews.swift`, then reduce layout nesting and verify no long-chat freeze regressions."

Quick sanity commands:
```bash
xcodebuildmcp --help
xcodebuildmcp tools
xcodebuildmcp doctor
```

Fast validation commands:
```bash
xcodebuildmcp macos build --project-path /Users/josh/Projects/JChat/JChat.xcodeproj --scheme JChat --configuration Debug --output text
xcodebuildmcp macos build-and-run --project-path /Users/josh/Projects/JChat/JChat.xcodeproj --scheme JChat --configuration Debug --output text
xcodebuildmcp macos stop --app-name JChat --output text
```

Full suite command (use at checkpoints / pre-push):
```bash
xcodebuildmcp macos test --project-path /Users/josh/Projects/JChat/JChat.xcodeproj --scheme JChat --configuration Debug --output text
```

## Guardrails
- Don’t batch unrelated work in one branch.
- Don’t skip local validation before claiming done: build is the default loop; run full tests for higher-risk changes.
- Don’t reintroduce heavy UI layering while stability issues are active.
- No PR/CI flow for this project.
- Push only with explicit approval.
