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
1. Build/test with `XcodeBuildMCP` (or fallback shell if scheme destination requires it).
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

## Guardrails
- Don’t batch unrelated work in one branch.
- Don’t skip local build/test before claiming done.
- Don’t reintroduce heavy UI layering while stability issues are active.
- No PR/CI flow for this project.
- Push only with explicit approval.
