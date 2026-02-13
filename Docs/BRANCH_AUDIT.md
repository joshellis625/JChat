# Branch Audit: codex/v2-liquid-glass vs main

This document records what the `codex/v2-liquid-glass` branch contains relative to `main`.
It exists so future AI sessions and developers know exactly what changed and why.

## Summary

~50 files changed. This branch represents the full V2 rewrite:
- New V2 UI shell (V2ShellViews.swift, V2Design.swift)
- New Core/ architecture (ConversationStore, ChatEngine, ChatRepository, supporting types)
- New utility files (ModelNaming, AppCommandNotifications)
- Documentation overhaul (PROJECT_GUIDE.md, CHANGELOG_INTERNAL.md, CONTRIBUTING.md, CLAUDE.md)
- Test files updated

This is not a small feature branch — it is the V2 production app.

---

## Architecture Shift

| Old (main) | New (this branch) |
|---|---|
| `ChatViewModel` (@Observable) | `ConversationStore` (@Observable, @MainActor) |
| `ChatListView` | `V2SidebarView` |
| `ConversationView` | `V2ConversationPane` |
| `MessageBubble` | `V2MessageRow` |
| `MessageInputView` | `V2Composer` |
| `ChatToolbarView` | Header card inside `V2ConversationPane` |
| `textSizeMultiplier` (Double, 0.8–1.4×) | `textBaseSize` (CGFloat, 10–20pt) env key |
| Flat Views/ structure | Core/Conversation/ + V2/ + slim Views/ |

---

## New Files Added on This Branch

### V2 UI
- `JChat/V2/Design/V2Design.swift` — Design tokens: V2Palette, glassCard/surfaceCard modifiers
- `JChat/V2/UI/V2ShellViews.swift` — Complete V2 UI shell (670 lines): V2SidebarView, V2ConversationPane, V2MessageRow, V2Composer, AutoTitleLoadingTitleView

### Core Architecture
- `JChat/Core/Conversation/ConversationStore.swift` — Primary state store (replaces ChatViewModel)
- `JChat/Core/Conversation/ChatEngine.swift` — ChatEngineProtocol + OpenRouterChatEngine
- `JChat/Core/Conversation/ChatRepository.swift` — ChatRepositoryProtocol + SwiftDataChatRepository
- `JChat/Core/Conversation/ConversationFeatureFlags.swift` — 3 flags (useRebuiltConversationStore, flush settings)
- `JChat/Core/Conversation/MessageRowViewData.swift` — View-layer data struct for message rows
- `JChat/Core/Conversation/StreamTextAccumulator.swift` — SSE text buffer

### Utilities
- `JChat/Models/ModelNaming.swift` — Static display name resolution for model IDs
- `JChat/AppCommandNotifications.swift` — 6 notification types for keyboard shortcuts

---

## Modified Files

### App Entry / Shell
- `JChat/JChatApp.swift` — Updated schema registration
- `JChat/Views/ContentView.swift` — Now uses V2SidebarView + V2ConversationPane; TextBaseSizeKey env
- `JChat/Views/SettingsView.swift` — Updated defaults section

### Models & Services
- `JChat/Chat.swift` — Added character relationship, 16 override properties, overrideCount, addUsage/removeUsage
- `JChat/Models/AppSettings.swift` — Updated settings
- `JChat/Models/CachedModel.swift` — Updated pricing/variant handling
- `JChat/Services/OpenRouterService.swift` — Unified on ModelCallRequest, hardened SSE parsing, retry policy
- `JChat/Services/JChatError.swift` — Extended error types

### Components (still active)
- `JChat/Views/Components/InlineModelPicker.swift` — Overhauled (460pt popover, search, favorites, pricing)

### Documentation
- `CLAUDE.md`, `CONTRIBUTING.md` — Updated workflow standards
- `Docs/PROJECT_GUIDE.md` — Rewritten for V2 architecture
- `Docs/CHANGELOG_INTERNAL.md` — Extended with V2 history

### Tests
- `JChatTests/JChatTests.swift`, `JChatTests/OpenRouterServiceTests.swift`

---

## Dead V1 Code (Present on Branch, NOT Routed to by ContentView)

These files compile and are in the Xcode project but ContentView no longer routes to them.
They exist as remnants of the V1 UI. **Marked for deletion in V2 completion work.**

| File | V1 Role |
|---|---|
| `Views/ChatListView.swift` | Sidebar list |
| `Views/ChatToolbarView.swift` | Conversation toolbar |
| `Views/ChatViewModel.swift` | State management |
| `Views/ConversationView.swift` | Conversation pane |
| `Views/MessageBubble.swift` | Message rendering |
| `Views/MessageInputView.swift` | Composer |
| `Views/Components/AdvancedParameterPanel.swift` | Per-chat parameter overrides |
| `Views/Components/CharacterPicker.swift` | Character assignment popover |
| `Views/Components/MarkdownTextView.swift` | Markdown rendering |
| `Views/Components/MessageActionBar.swift` | Message action buttons |
| `Views/Characters/CharacterEditorView.swift` | Character CRUD form |
| `Views/Characters/CharacterListView.swift` | Character list |

---

## Known V2 Gaps (as of 2026-02-13)

These features existed in V1 but are not yet surfaced in V2:

| Feature | Status | Notes |
|---|---|---|
| Character/system prompt assignment | Missing UI | Model relationship exists in Chat.swift; needs picker in conversation header |
| Per-chat parameter overrides | Missing UI | All 16 properties exist in Chat.swift; needs inspector panel |
| Markdown rendering | Disabled | MarkdownTextView removed; no feature flag (must re-add); test for hang regression |
| Font size toolbar buttons | Redundant | Cmd+=/- work; +/- buttons in toolbar should be removed |

---

## Merge Readiness

This branch is **not yet ready to merge to main**. Outstanding before merge:
1. P0: Remove font-size toolbar buttons + delete dead V1 files
2. P1: Re-add per-chat parameter inspector panel
3. P2: Re-add character picker per chat
4. P3: Re-enable markdown (with hang regression test)
5. Build + regression checklist pass (see Docs/PROJECT_GUIDE.md)
