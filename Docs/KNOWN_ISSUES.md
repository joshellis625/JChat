# JChat — Known Issues & Feature Requests

**Open bugs and feature requests are tracked in [GitHub Issues](https://github.com/joshellis625/JChat/issues).** Add new items there, not here.

**Reference links:** see `Docs/PROJECT_GUIDE.md` — Reference Links section.

This file is now a **resolved issue log only** — a record of what was fixed and how.

---

## Bugs

### ~~BUG-001: Floating-point precision in parameter values~~ ✅ Resolved 2026-03-06
Added `round2(_:)` helper in `OpenRouterService.buildRequestBody(from:)` — rounds all `Double` parameters to 2 decimal places at the serialization boundary using `(value * 100).rounded() / 100`. Eliminates IEEE 754 noise from both the API payload and the JSON inspector without touching the storage layer.

### ~~BUG-002: Deleting a message mid-stream causes ghost message / stuck stop button~~ ✅ Resolved 2026-03-06
Delete button in `MessageRow.actionToolbar` is now hidden while `isLiveStreaming == true`. The prop was already threaded into `MessageRow`; added `&& !isLiveStreaming` to the existing `if !isEditing` guard.

### ~~BUG-003: JSON Inspector Copy button transition has visible crossover~~ ✅ Resolved 2026-03-06
Applied `.contentTransition(.symbolEffect(.replace))` to the `Image` and `.transition(.opacity)` to the `Text` label independently inside `MessageInspectorSheet`. This prevents the old and new content from rendering simultaneously during the animation frame.

### ~~BUG-004: `stream_options.include_usage` is deprecated — remove it~~ ✅ Resolved 2026-03-06
Deleted `private struct StreamOptions`, the `stream_options` field on `ChatRequest`, and the `if modelRequest.stream { body.stream_options = ... }` assignment in `buildRequestBody`. OpenRouter now always returns full usage data regardless of this field.

### ~~BUG-005: Raw JSON viewer (message inspector) missing cost and full usage info~~ ✅ Resolved 2026-03-06
Initially patched by adding a `cost` param to `buildResponseJSON(...)`. Fully superseded by BUG-009: `buildResponseJSON` has since been deleted and the inspector now shows the real `/generation` API record with authoritative cost and token data.

### ~~BUG-006: Copy and Done button sizes mismatched in raw JSON viewer~~ ✅ Resolved 2026-03-06
Matched font weight (`.medium`) on the Done button label to align with the Copy button. Both buttons now share identical padding, font size, and visual weight.

### ~~BUG-007: Auto-chat-title generation is unreliable~~ ✅ Resolved 2026-03-06
- `autoTitleModelID(for:)` now always returns `google/gemini-2.0-flash-lite` — never the chat's selected model (original fix used `gemini-flash-1.5-8b` which was deprecated; corrected to `gemini-2.0-flash-lite`)
- Rewrote the title prompt with explicit system-prompt framing, "Output ONLY the title" instruction, and clean User:/Assistant: message formatting (removed the erroneous literal `+` separators)
- Relaxed `normalizedAutoTitle` to accept 1+ word titles (was 3+), replaced aggressive word stripping with surgical quote/markdown-character-only cleanup using unicode escapes for curly quotes

### ~~BUG-008: Selected model not persisted / reselected on app relaunch~~ ✅ Resolved 2026-03-06
The `InlineModelPicker` binding setter in `ConversationPane` now writes the selected model ID back to `AppSettings.defaultModelID` on every pick. `ChatRepository.createNewChat` already reads this value — so new chats and post-restart sessions now inherit the last used model.

### ~~BUG-009: JSON inspector cost/token data was synthesized, not from API~~ ✅ Resolved 2026-03-06
Replaced the `buildResponseJSON` synthesis approach entirely. After each stream completes, `settleGenerationStats` calls `GET /generation?id=<genID>` on OpenRouter and stores the raw API response as `rawResponseJSON`. This gives the inspector the actual settled record: `total_cost`, `tokens_prompt`, `tokens_completion`, `native_tokens_*`, `cache_discount`, `upstream_inference_cost`, `provider_name`, `latency`, `finish_reason`, etc. — all directly from OpenRouter. The `buildResponseJSON` method in `ConversationStore` and the `GenerationStats`/`GenerationResponse` structs + `fetchGeneration` method were added to `OpenRouterService`.

### ~~BUG-010: Copy button in JSON inspector was taller than Done button~~ ✅ Resolved 2026-03-06
The `doc.on.doc` SF Symbol has a taller natural bounding box than the text-only Done button. Added `.frame(width: 12, height: 12)` to the `Image` view in `MessageInspectorSheet`'s Copy button label — caps the icon's layout footprint so both buttons share identical height.

---

## Feature Requests

### ~~FR-001: Show token count and cost metadata on user messages~~ ✅ Resolved 2026-03-06
Added `if row.role == .user, row.promptTokens > 0` branch to the metadata `HStack` in `MessageRow`. User messages now show prompt token count alongside the timestamp and cost, matching assistant message layout.

### FR-002: Cost display needs better precision for small values
**Priority:** Medium
**Where:** Message metadata cost display, chat header cost summary
**What:** Very small costs display as `$0.00` which is technically correct but unhelpful. For LLM API calls, costs are often fractions of a cent (e.g. `$0.00000025`). Need a formatting strategy:
- Option A: Always show enough significant figures — e.g. `$0.000025`
- Option B: Switch to cents for small values — e.g. `0.0025¢`
- Option C: Use scientific notation below a threshold — e.g. `$2.5e-6`
- Option D: Accumulate and only show when meaningful — e.g. show `< $0.01` until it exceeds a cent
**Current behavior:** Both the chat-scoped header ("1,232 tokens · $0.00") and per-message metadata ("627 tokens $0.00") show `$0.00` for cheap models.

### FR-003: Chat-scoped token counter and cost must be accurate and monotonic
**Priority:** High
**Where:** Chat header bar ("1,232 tokens · $0.00")
**What:** The chat-level token counter and cost accumulator should:
1. Only ever increase (monotonic) — never decrease on edits or regenerations
2. Include prompt tokens from every request, including re-sends from edits and regenerations (since each edit/regen sends the full conversation again)
3. Accurately reflect the sum of all API calls made for this chat
**Note:** All the raw data is already in the metadata JSON. This is about ensuring `Chat.totalPromptTokens`, `Chat.totalCompletionTokens`, and `Chat.totalCost` are correctly accumulated and never subtracted from.

### ~~FR-004: Settings popover needs professional redesign~~ ✅ Resolved 2026-03-06
Keychain note moved to section footer. Validate button uses `.buttonStyle(.glass)`. Validation result replaced with `KeyValidationStatusView` — compact status card with checkmark/x icon, inline model count + credits chips on success, debug endpoint/status only on failure. Animated entry with `.easeOut`.

### ~~FR-005: Inline model picker needs visual polish~~ ✅ Resolved 2026-03-06
Replaced manual `.thinMaterial + stroke` background with `.buttonStyle(.glass)` — now a native Liquid Glass interactive control with fluid hover/press response.

### FR-006: Parameter inspector needs a full UI/UX overhaul
**Priority:** High
**Where:** `ParameterInspector.swift` — currently rendered as a SwiftUI `.inspector` panel
**What:** The current inspector feels out of place — wrong fonts, generic sliders and steppers that don't match the app's Liquid Glass aesthetic, and an awkward inline panel layout. Needs a ground-up redesign:
- Move into a sheet (`.sheet` presentation) instead of the `.inspector` sidebar
- Typography should match the app's rounded, weight-considered style
- Sliders should use the app's accent color and feel native
- Group parameters logically with clear section headers
- Consider Liquid Glass card containers per section
- Make the reset button more prominent and destructively styled
**Design reference:** Should feel as polished as the Settings view post-FR-004 redesign.

### FR-007: Add fade-in animation to streaming assistant response messages
**Priority:** Low
**Where:** `MessageRow` in `ShellViews.swift` — the live streaming bubble
**What:** When a new assistant message bubble first appears during streaming, it pops in abruptly. A short opacity fade-in (e.g. `.transition(.opacity)` with `.easeIn(duration: 0.2)`) on first appearance would feel more natural.
**Note:** Must not affect the streaming text content animation itself — only the initial appearance of the bubble container.

### FR-008: Proper Markdown rendering in all message bubbles
**Priority:** High
**Where:** `MessageRow` content bubble — currently uses plain `Text(renderedContent)`
**What:** Assistant responses frequently contain Markdown (headers, bold, italic, code blocks, lists, inline code). These currently render as raw syntax characters. Need a stable Markdown renderer that:
1. Does not affect streaming performance — must work with partial/incomplete Markdown mid-stream
2. Does not cause SwiftData crashes (no model mutations during rendering)
3. Handles code blocks with monospaced font + optional syntax tint
4. Degrades gracefully for incomplete Markdown at the streaming boundary
**Approach options:**
- SwiftUI's built-in `Text` with `AttributedString` from `AttributedString(markdown:)` (limited — no code blocks)
- `swift-markdown-ui` (3rd party, feature-rich, well-maintained)
- Custom parser targeting only the Markdown constructs LLMs commonly emit
**Note:** This is the highest-impact UX improvement for legibility. Implement carefully — streaming stability is non-negotiable.

### FR-009: Sidebar chat context menu — export chat as JSON or Markdown
**Priority:** Medium
**Where:** `SidebarView` — existing `.contextMenu` on each chat row
**What:** Right-clicking a chat in the sidebar should offer "Export as JSON" and "Export as Markdown" options alongside the existing Delete.
- **JSON**: export the full chat with all messages, metadata (tokens, cost, timestamps, model IDs) as a valid JSON file
- **Markdown**: export as a human-readable `.md` file with message role headers, timestamps, and content — suitable for archiving or sharing
**UX:** Use `NSSavePanel` to let the user choose save location and filename.

### FR-010: Native toolbar overhaul — move chat header info into the window toolbar
**Priority:** High
**Where:** `ConversationPane.headerCard` + window toolbar area
**What:** The current chat header is a custom glass card below the toolbar. Goal is to move as much as reasonable into the native macOS `NavigationSplitView` toolbar:
- Chat title (editable inline?)
- Token / cost summary
- Model picker
- Parameter inspector toggle
- Match the ChatGPT mac app aesthetic: native Liquid Glass grouped toolbar buttons, clean spacing
- Remove "WhisperQuill" app name from the window toolbar (it wastes space)
**Note:** Some elements may not be movable without sacrificing macOS window chrome conventions. Start with what translates cleanly; leave the rest in the card.

### FR-011: Overhaul the prompt input bar
**Priority:** High
**Where:** `Composer` struct in `ShellViews.swift`
**What:** The current composer is a minimal single text field + send/stop button. Needs a richer design:
- Better visual weight and padding — feels too small currently
- Placeholder text improvements
- Future: file attachment button (image/document) with a paperclip or attachment icon
- Future: image paste support
- Keyboard shortcut affordances (Enter to send, Shift+Enter for newline)
- Character/token count indicator (optional)
**Note:** File/image attachment is a long-term goal — design the layout to accommodate it even if the functionality isn't wired up yet.

### FR-012: Characters system — named personas with system prompts, model, and parameter presets
**Priority:** High
**Where:** New dedicated Characters UI (sidebar section or sheet) + `Character.swift` + `Chat.swift`
**What:** Restore and surface the Characters system that was previously ripped out. A Character is a named persona that bundles:
- A **system prompt** (injected as the first message in every conversation)
- A **preferred model** (`preferredModelID: String?`)
- Eventually: **parameter presets** (temperature, top-p, etc. — mirroring the per-chat override system)
- An **isDefault** flag so one character is always applied to new chats unless overridden

The data layer is already in place — `Character` model, `Chat.character` relationship, and `ConversationStore.buildHistory` already injects `chat.character?.systemPrompt`. What's missing is entirely the UI:
- A Characters manager (create, edit, delete, set default)
- A way to assign a Character to a chat (picker in the chat header or parameter inspector sheet)
- A way to quickly view/edit the active Character's system prompt from within a conversation

**Phase 1 (basic):** Character manager + assign to chat + system prompt injection (already works at the engine layer)
**Phase 2:** Parameter presets stored on `Character` and applied as the base layer in the override resolution chain (character preset → chat override → API default)
**Note:** `Character` does not yet have parameter preset fields — those will need to be added to the SwiftData model with a migration when Phase 2 is implemented.

### FR-013: iOS support — multi-platform target
**Priority:** Low (long-term)
**Where:** Project-wide
**What:** The app should run on iOS (iPhone + iPad) in addition to macOS. This requires:
- Adding an iOS target to the Xcode project
- Auditing all `#if os(macOS)` / AppKit usage (e.g. `NSPasteboard`, `NSSavePanel`) and replacing with cross-platform equivalents or conditional compilation
- Adapting layouts for smaller screens (NavigationStack instead of NavigationSplitView on iPhone)
- Ensuring SwiftData schema is shared across targets

### FR-014: CloudKit sync for chats, settings, and API key
**Priority:** Low (long-term, requires Apple Developer account ✅)
**Where:** `JChatApp.swift` ModelContainer configuration + `KeychainManager`
**What:** Sync everything across devices via CloudKit:
- **Chats + messages**: migrate `ModelContainer` to use `ModelConfiguration` with CloudKit (`cloudKitContainerIdentifier`) — requires all SwiftData models to be CloudKit-compatible (no non-optional relationships without defaults, etc.)
- **Settings**: sync `AppSettings` via CloudKit or `NSUbiquitousKeyValueStore` for lightweight prefs
- **API key**: store in iCloud Keychain (`kSecAttrSynchronizable: true` in `KeychainManager`) so it's available on all signed-in devices without re-entry
**Note:** CloudKit + SwiftData has known rough edges (merge conflicts, optional handling). Plan for schema migration carefully. Requires `com.apple.developer.icloud-container-identifiers` and `com.apple.developer.ubiquity-kvstore-identifier` entitlements.

---

## Status Key

| Tag | Meaning |
|-----|---------|
| **Bug** | Something broken or incorrect |
| **FR** | Feature request or enhancement |
| **Severity/Priority** | High > Medium > Low |

*Last updated: 2026-03-06 (session 2)*
