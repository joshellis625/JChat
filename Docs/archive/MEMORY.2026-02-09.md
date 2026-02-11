# JChat Project Memory

## Project Overview
- SwiftUI/SwiftData chat app for macOS 26 + iOS 26 using OpenRouter.ai API
- MVVM architecture, actor-based services
- Bundle ID: joshellis625.JChat, Team: B26L4UNFCX
- Xcode project uses explicit PBX file references (NOT filesystem sync for main target)

## Xcode Project File (pbxproj) Notes
- When adding new Swift files, must update: PBXBuildFile, PBXFileReference, PBXGroup (parent group), PBXSourcesBuildPhase
- Build file IDs and file reference IDs MUST be unique - never reuse the same ID for both
- Existing ID prefix pattern: `03D0F7xx2F37409300FEC0AF` for original files, `03A0F7xx2F37409300FEC0AF` for additions
- Last used IDs: FileRef `03A0F799`, BuildFile `03A0F79A`, Group `03A0F796` — next available: `03A0F79B`
- Test targets (JChatTests, JChatUITests) use PBXFileSystemSynchronizedRootGroup (auto-sync)
- Views group has subgroups: Characters (`03A0F796`), Components (`03A0F78D`), ModelManager (`03A0F78C`)
- CostHeaderView.swift was renamed to ChatToolbarView.swift on disk (same pbxproj IDs `03D0F757`/`03D0F770`)

## Build Settings
- SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor (Swift 6 approachable concurrency)
- SWIFT_APPROACHABLE_CONCURRENCY = YES
- macOS only currently (SUPPORTED_PLATFORMS = macosx)
- App Sandbox enabled, Hardened Runtime enabled
- Network entitlement: `com.apple.security.network.client` in JChat.entitlements (required for API calls)

## Architecture
- Models: Chat, Message, AppSettings, Character (identity-only), CachedModel (SwiftData)
- Services: OpenRouterService (actor), KeychainManager (@unchecked Sendable class), JChatError, ModelManager (@Observable)
- Views/Characters: CharacterEditorView, CharacterListView
- Views/Components: AdvancedParameterPanel, CharacterPicker, InlineModelPicker, MarkdownTextView, MessageActionBar
- Views/ModelManager: ModelManagerView, ModelRowView
- Views: ChatListView, ChatViewModel, ContentView, ConversationView, ChatToolbarView, MessageBubble, MessageInputView, SettingsView
- Parameter cascade: chat override → global fallback (2-level, no character layer for params)
- Characters are identity-only: name, systemPrompt, preferredModelID, isDefault — NO parameter storage
- API key stored in Keychain (service: "com.josh.jchat", account: "openrouter-api-key")
- Text size: AppSettings.textSizeMultiplier (Double, default 1.0) → `TextSizeMultiplierKey` env key in ContentView → child views read `@Environment(\.textSizeMultiplier)` and apply `.font(.system(size: 13 * multiplier))`
- Text size applies to: MessageInputView, MessageBubble (user text), MarkdownTextView (body + code), ConversationView (empty state, error banner)

## Completed Phases
- Phases 1-10: All complete (foundation, API, model manager, characters, streaming, markdown, conversation, settings, navigation, integration)
- Bug fixes: API URL fix, network entitlement, validation flow
- UI Refinement Pass 1: 8 visual fixes (see below)
- UI Refinement Pass 2: edit message button, CharacterEditorView layout overhaul
- UI Refinement Pass 3: AdvancedParameterPanel overhaul (single toggles for booleans, string-backed int fields, bigger text), MessageInputView compact redesign, "Parameters" label, sidebar text bump, default model inheritance fix

## Phase 4 Details
- Renamed Assistant → Character globally (MessageRole.assistant unchanged — API protocol value)
- Character model: id, name, systemPrompt, preferredModelID, isDefault, createdAt, chats relationship
- Chat has 15 override properties: temperature, topP, topK, maxTokens, frequencyPenalty, presencePenalty, repetitionPenalty, minP, topA, stream, reasoningEnabled, reasoningEffort, reasoningMaxTokens, reasoningExclude, verbosity
- Effective defaults: temperature=1.0, stream=true, reasoningEnabled=true, reasoningEffort="medium", all others nil
- New chat inherits overrides from most recent chat via `Chat.inheritParameters(from:)`
- `Chat.resetAllOverrides()` sets all 15 to nil
- ChatRequest includes: stream_options.include_usage=true (when streaming), reasoning payload, verbosity
- ReasoningPayload: enabled, effort, max_tokens, exclude — effort and max_tokens MUTUALLY EXCLUSIVE for Anthropic
- Verbosity: nil default (medium on OpenRouter), maps to Anthropic output_config.effort

## Phase 6-9 Details (updated after UI refinement)
- MarkdownTextView: parses fenced code blocks + inline markdown via AttributedString(markdown:)
- MessageActionBar: token count, cost, edit/copy/regenerate/delete buttons (always visible, left-aligned for AI, right-aligned for user)
- MessageBubble: user=accent color, assistant=Color(.windowBackgroundColor).opacity(0.8), model badge capsule, delete confirmation dialogs
- Edit is inline: pencil → TextEditor replaces bubble content, checkmark saves in place, X cancels. No messages deleted.
- ChatToolbarView: character picker + model picker + token/cost + "Parameters" labeled button (all sized ~13pt)
- MessageInputView: compact rounded border (cornerRadius 12), top-left "Message..." placeholder, focus ring, 26pt send/stop, Return-to-send
- ConversationView: toolbar + messages (spacing 16) + empty state + error banner (.callout font) + input
- SettingsView: API config + defaults + Appearance section (text size slider 80%-140%)
- ChatListView: title 15pt medium, model/date 12pt, model badge only (character badge removed), message count, date, empty chats skip delete confirmation
- ContentView: toolbar buttons + TextSizeMultiplierKey env key + text size loading on appear/settings dismiss
- CharacterEditorView: `.formStyle(.grouped)`, InlineModelPicker (replaced sheet picker), compact TextEditor (minHeight 80), no "Identity" section header

## Key Patterns
- ChatParameters struct for API request params (Sendable)
- StreamEvent enum for SSE streaming events
- CachedModel stores pricing as strings (per-token, from OpenRouter API)
- CachedModel has isModerated, modality, ModelVariant enum (:free, :extended, :exacto)
- ModelVariant badges: green=Free, blue=Extended, red=Exacto (accessibility-safe colors, no purple)
- ModelManager is @Observable, manages fetch/cache/search/filter/sort of CachedModels
- All API params sent as JSON POST to /v1/chat/completions — no SDK (raw URLRequest + JSONEncoder)
- AdvancedParameterPanel uses ScrollView + custom ParamSection views (NOT Form — Form caused overflow). Boolean params are single toggles (name left, switch right — no enable/value split). Int params use string-backed TextField (allows clearing field). All labels 13pt, descriptions 11pt, value text 12-13pt monospaced.
- BadgeCapsule reusable component defined in ModelRowView.swift

## SwiftData Migration Rules
- When adding new non-optional properties to `@Model` classes, ALWAYS use an inline default value (`var foo: Double = 1.0`), not just in `init()`. SwiftData lightweight migration needs the declaration-level default to populate existing rows.
- Without this, adding a mandatory attribute causes crash: `Validation error missing attribute values on mandatory destination attribute`
- If a store gets corrupted from a failed migration, delete it: `rm -f ~/Library/Containers/joshellis625.JChat/Data/Library/Application\ Support/default.store*`

## Bug Fixes Applied
- OpenRouter API URL: `/api/v1/auth/key` → `/api/v1/key` (was 404ing)
- Network entitlement: added `com.apple.security.network.client` to JChat.entitlements (sandbox was blocking)
- SettingsView validateKey(): shows actual errors, credits fetch is non-blocking (requires management key)
- AppSettings.textSizeMultiplier: needed inline default `= 1.0` for SwiftData migration

## User Accessibility Notes
- User has red-green color deficiency
- No purple (hard to distinguish from blue)
- Use bright/saturated reds, standard greens, blues
- Avoid dimming for emphasis — use text weight or badges instead

## File Tree (26 Swift files)
```
JChat/
  Chat.swift              — Chat + Message + MessageRole models (SwiftData)
  JChatApp.swift          — App entry point, schema registration
  Models/
    AppSettings.swift     — Singleton settings (+ textSizeMultiplier)
    CachedModel.swift     — OpenRouter model cache (SwiftData), pricing, variants, modality
    Character.swift       — Identity-only: name, systemPrompt, preferredModelID, isDefault
  Services/
    JChatError.swift      — Typed error enum with descriptions + recovery suggestions
    KeychainManager.swift — Keychain CRUD for API key
    ModelManager.swift    — @Observable, fetches/caches/filters/sorts CachedModels
    OpenRouterService.swift — Actor, SSE streaming, ChatParameters, ChatRequest, ReasoningPayload
  Views/
    ChatListView.swift    — Sidebar list with model badge, message count, date
    ChatToolbarView.swift — Toolbar: character + model pickers, token/cost, "Parameters" button
    ChatViewModel.swift   — @Observable, sendMessage, streaming, regenerate, edit, delete, parameter cascade
    ContentView.swift     — NavigationSplitView, toolbar, TextSizeMultiplierKey env
    ConversationView.swift — Messages scroll + toolbar + empty state + error banner + input
    MessageBubble.swift   — User/assistant bubble, always-visible action bar, model badge capsule
    MessageInputView.swift — Bordered TextEditor + placeholder + Return-to-send
    SettingsView.swift    — API key + defaults + Appearance (text size)
    Characters/
      CharacterEditorView.swift — Character form with "System Prompt" section
      CharacterListView.swift   — Browse/manage characters
    Components/
      AdvancedParameterPanel.swift — ScrollView + ParamSection (15 overrides)
      CharacterPicker.swift       — Inline capsule + popover
      InlineModelPicker.swift     — Inline capsule + popover with search
      MarkdownTextView.swift      — Fenced code blocks + inline markdown
      MessageActionBar.swift      — Edit/copy/regenerate/delete + token/cost display
    ModelManager/
      ModelManagerView.swift — Full model browse/search/filter/sort
      ModelRowView.swift     — Model row + BadgeCapsule component
```

## Known Rough Edges
- No first-launch onboarding — user must manually open Settings to enter API key
- TextEditor height in MessageInputView uses `.fixedSize(horizontal: false, vertical: true)` — test with very long input
- No keyboard shortcut for New Chat (Cmd+N)
- MarkdownTextView code block backgrounds may blend with bubble backgrounds

## Future Considerations
- SillyTavern character import / preset import
- Memory feature (persistent context across chats)
- Provider routing controls in Advanced Parameter Panel
- logit_bias token control
- Tool use / function calling parameters
- First-launch onboarding flow
- CloudKit sync (requires paid Apple Developer account)
