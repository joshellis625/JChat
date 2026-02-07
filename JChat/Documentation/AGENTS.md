# JChat — AGENTS Instructions

SwiftUI/SwiftData chat app for macOS 26 using the OpenRouter.ai API. MVVM architecture with actor-based services. All 10 implementation phases complete, first UI refinement pass done.

## Build

```bash
xcodebuild build -project JChat.xcodeproj -scheme JChat -destination 'platform=macOS'
```

Bundle ID: `joshellis625.JChat` | Team: `B26L4UNFCX` | macOS only (for now)

## Architecture

- **Models (SwiftData)**: Chat, Message, AppSettings, Character, CachedModel
- **Services**: OpenRouterService (actor), KeychainManager (@unchecked Sendable), ModelManager (@Observable), JChatError
- **Views**: MVVM — ChatViewModel is @Observable, views are pure SwiftUI
- **Parameter cascade**: chat override → global fallback (2-level, no character layer)
- **Characters are identity-only**: name, systemPrompt, preferredModelID, isDefault — NO parameter storage
- **API calls**: raw URLRequest + JSONEncoder to `/v1/chat/completions` — no SDK
- **Text size**: `AppSettings.textSizeMultiplier` (Double, default 1.0) → `TextSizeMultiplierKey` env key in ContentView → child views read `@Environment(\.textSizeMultiplier)` and apply `.font(.system(size: 13 * multiplier))`. Do NOT use `.font(.body)` etc. in views that should scale — those override the parent and ignore the multiplier.

## Xcode Project File (pbxproj) — CRITICAL

The main target uses **explicit PBX file references** (NOT filesystem sync). When adding new Swift files, you MUST update all four sections:

1. `PBXBuildFile` — new build file entry
2. `PBXFileReference` — new file reference entry
3. `PBXGroup` — add to parent group's children
4. `PBXSourcesBuildPhase` — add build file to sources

**ID rules**: Build file IDs and file reference IDs MUST be unique — never reuse the same ID for both. Prefix pattern: `03A0F7xx2F37409300FEC0AF`. Next available: `03A0F79B`. Always increment from the last used ID.

Test targets (JChatTests, JChatUITests) use auto-sync and don't need manual pbxproj edits.

## Swift & Concurrency

- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (Swift 6 approachable concurrency)
- `SWIFT_APPROACHABLE_CONCURRENCY = YES`
- App Sandbox + Hardened Runtime enabled
- **Network entitlement**: `com.apple.security.network.client` required in JChat.entitlements
- API key stored in Keychain (service: `com.josh.jchat`, account: `openrouter-api-key`) — NEVER in SwiftData/UserDefaults

## Naming Conventions

- "Character" not "Assistant" for the persona system (MessageRole.assistant is unchanged — that's the API protocol value)
- CostHeaderView.swift was renamed to ChatToolbarView.swift on disk (same pbxproj IDs)

## Accessibility — USER HAS RED-GREEN COLOR DEFICIENCY

- No purple (hard to distinguish from blue)
- Use bright/saturated reds, standard greens, blues
- Avoid dimming for emphasis — use text weight or badges instead
- ModelVariant badges: green=Free, blue=Extended, red=Exacto

## Key View Patterns

- **AdvancedParameterPanel**: uses `ScrollView` + custom `ParamSection` views (NOT `Form` — Form caused overflow/no-scroll issues). Boolean params are single toggles (name left, switch right). Int params use string-backed TextField for easy editing. All text `.system(size: 13)` for labels, `.system(size: 11)` for descriptions.
- **MessageInputView**: compact rounded border (cornerRadius 12), "Message..." placeholder top-left aligned, focus ring, Return-to-send, 26pt send/stop buttons
- **MessageBubble**: assistant bg = `Color(.windowBackgroundColor).opacity(0.8)`, action bar always visible. All messages show edit/copy/delete; assistant messages also show regenerate. Buttons left-aligned for AI, right-aligned for user. Delete has confirmation dialog. Edit is inline — switches bubble to TextEditor with checkmark/cancel.
- **ConversationView**: has empty state when chat has no messages. Edit saves in place via `onSaveEdit` callback (updates `message.content` directly).
- **ChatToolbarView**: "Parameters" label (not "Params"), token/cost 12pt monospaced, 13pt button text
- **CharacterEditorView**: `.formStyle(.grouped)`, uses InlineModelPicker (not sheet), compact TextEditor
- **ChatListView**: title 15pt medium, model/date 12pt; empty chats skip delete confirmation

## File Tree

```
JChat/
  Chat.swift, JChatApp.swift
  Models/        — AppSettings (+ textSizeMultiplier), CachedModel, Character
  Services/      — JChatError, KeychainManager, ModelManager, OpenRouterService
  Views/
    ChatListView, ChatToolbarView, ChatViewModel, ContentView (+ TextSizeMultiplierKey),
    ConversationView, MessageBubble, MessageInputView, SettingsView (+ Appearance section)
    Characters/  — CharacterEditorView, CharacterListView
    Components/  — AdvancedParameterPanel, CharacterPicker, InlineModelPicker,
                   MarkdownTextView, MessageActionBar
    ModelManager/ — ModelManagerView, ModelRowView (also defines BadgeCapsule)
```

## Known Rough Edges

- No first-launch onboarding (must manually open Settings for API key)
- TextEditor height in MessageInputView may misbehave with very long input
- No Cmd+N keyboard shortcut for New Chat
- MarkdownTextView code block backgrounds may blend with bubble backgrounds

## Detailed Notes

See `.claude/projects/-Users-josh-Projects-JChat/memory/MEMORY.md` for full phase details, API request structure, parameter definitions, and future considerations.
