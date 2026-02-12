# JChat AGENTS Notes

Read `/Users/josh/Projects/JChat/Docs/PROJECT_GUIDE.md` first.

## Current Truth
- V2 UI is the default app surface.
- `ConversationStore` is the primary conversation state owner.
- OpenRouter calls should flow through the unified `ModelCallRequest` pipeline.
- Stability-first decisions are preferred over feature expansion.

## Critical Implementation Notes
- Main target uses Xcode filesystem-synced groups. Adding/removing source files on disk updates target sources automatically.
- API key is stored in Keychain only (`com.josh.jchat` / `openrouter-api-key`).
- Parameter precedence is chat override -> global fallback.
- Character stores identity/system prompt, not per-parameter overrides.
- Markdown rendering is intentionally disabled right now (plain text transcript rendering in V2 rows).
- Prefer `XcodeBuildMCP` workflows when available.

## Active UI Files
- `/Users/josh/Projects/JChat/JChat/Views/ContentView.swift`
- `/Users/josh/Projects/JChat/JChat/V2/UI/V2ShellViews.swift`
- `/Users/josh/Projects/JChat/JChat/V2/Design/V2Design.swift`

## Active Conversation Core Files
- `/Users/josh/Projects/JChat/JChat/Core/Conversation/ConversationStore.swift`
- `/Users/josh/Projects/JChat/JChat/Core/Conversation/ChatEngine.swift`
- `/Users/josh/Projects/JChat/JChat/Core/Conversation/ChatRepository.swift`
- `/Users/josh/Projects/JChat/JChat/Services/OpenRouterService.swift`

## Workflow Contract
- Use `codex/<topic>` branches for code changes.
- Documentation-only changes can be made directly on `main`.
- Run local validation before merge.
- No PR and no CI flow.
- Push only with explicit approval.

## Historical Context
Historical snapshots live in `/Users/josh/Projects/JChat/Docs/archive/` and are not current behavior docs.
