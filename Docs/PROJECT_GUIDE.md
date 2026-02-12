# JChat Project Guide (Canonical)

This is the source of truth for the current app architecture and development rules.

## Product Overview
JChat is a native SwiftUI chat app that uses OpenRouter as its model provider.

Current app direction:
- V2 conversation UI is the default experience.
- Stability and responsiveness are prioritized over feature breadth.
- macOS is the primary daily target right now, with iOS support preserved in architecture decisions.

## Current Runtime Architecture (V2)

### UI Layer
- `NavigationSplitView` shell with:
  - `V2SidebarView` (chat list)
  - `V2ConversationPane` (header, transcript, composer)
- Files:
  - `/Users/josh/Projects/JChat/JChat/Views/ContentView.swift`
  - `/Users/josh/Projects/JChat/JChat/V2/UI/V2ShellViews.swift`
  - `/Users/josh/Projects/JChat/JChat/V2/Design/V2Design.swift`

### Conversation State Layer
- `ConversationStore` is the primary V2 chat state owner.
- Responsibilities:
  - selected chat
  - send/regenerate/delete flows
  - streaming lifecycle
  - error mapping to user-facing messages
- Files:
  - `/Users/josh/Projects/JChat/JChat/Core/Conversation/ConversationStore.swift`
  - `/Users/josh/Projects/JChat/JChat/Core/Conversation/MessageRowViewData.swift`
  - `/Users/josh/Projects/JChat/JChat/Core/Conversation/StreamTextAccumulator.swift`

### Repository Layer
- `ChatRepositoryProtocol` + `SwiftDataChatRepository`.
- Encapsulates persistence operations and keeps view/store code cleaner.
- File:
  - `/Users/josh/Projects/JChat/JChat/Core/Conversation/ChatRepository.swift`

### Chat Engine Layer
- `ChatEngineProtocol` + `OpenRouterChatEngine`.
- Bridges app conversation flows to OpenRouter streaming events.
- File:
  - `/Users/josh/Projects/JChat/JChat/Core/Conversation/ChatEngine.swift`

### OpenRouter Service Layer
- `OpenRouterService` actor with a unified `ModelCallRequest` path for send + stream.
- Includes:
  - SSE parsing hardening
  - retry/backoff policy with jitter
  - `Retry-After` support
  - improved transport/status error mapping
- File:
  - `/Users/josh/Projects/JChat/JChat/Services/OpenRouterService.swift`

## Data Model
SwiftData models:
- `Chat`
- `Message`
- `AppSettings`
- `Character`
- `CachedModel`

Model file:
- `/Users/josh/Projects/JChat/JChat/Chat.swift`

## Key Behavioral Rules
- Parameter precedence: chat override -> global settings fallback.
- Character stores identity/system prompt/preferred model only.
- API key is Keychain-only (`com.josh.jchat` / `openrouter-api-key`).
- Message delete/regenerate never “refunds” usage totals (non-refundable generation accounting model).

## V2 Stability Rules (Current)
- Transcript rendering is capped to recent messages in stability mode.
- Very long single-message text is truncated for render stability.
- Streaming text updates are coalesced before UI updates.
- During streaming, assistant content is kept in lightweight in-memory state and persisted at end (not on every chunk).
- Auto-scroll follows active streaming and initial open behavior.

## Current UX Intent
- ChatGPT-style conversation focus.
- Clean, reduced visual layering.
- System-material surfaces over loud gradients.
- Stable typing and scrolling under long-chat stress.

## Markdown Rendering Status
Markdown is intentionally disabled in stabilization mode:
- V2 transcript rows render plain text directly in `V2MessageRow`.
- File:
  - `/Users/josh/Projects/JChat/JChat/V2/UI/V2ShellViews.swift`

## Build and Test
Preferred command (current local standard):
```bash
xcodebuild test -project /Users/josh/Projects/JChat/JChat.xcodeproj -scheme JChat -destination 'platform=macOS,arch=arm64' -derivedDataPath /Users/josh/Projects/JChat/DerivedData
```

Optional MCP-first workflow when available:
```bash
xcodebuildmcp doctor
xcodebuildmcp tools
```

## Engineering Workflow Standards
- Code changes: use `codex/<topic>` branch.
- Docs-only changes: direct to `main` is allowed.
- No PR flow and no CI gate for this project.
- Push only with explicit approval.

## Related Docs
- `/Users/josh/Projects/JChat/Docs/FoundationRebuildPlan.md`
- `/Users/josh/Projects/JChat/Docs/ROADMAP.md`
- `/Users/josh/Projects/JChat/Docs/REGRESSION_CHECKLIST.md`
- `/Users/josh/Projects/JChat/Docs/DEV_WORKFLOW.md`
- `/Users/josh/Projects/JChat/Docs/CHANGELOG_INTERNAL.md`
