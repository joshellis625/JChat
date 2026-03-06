# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## [Unreleased]

(In-progress work goes here)

---

## [2026-03-06] - Cost Architecture Overhaul: /generation API + UI Fixes (Session 2)

### Added
- **`OpenRouterService`**: `GenerationStats` + `GenerationResponse` Codable structs mapping the full `GET /generation` response schema (total_cost, tokens_prompt/completion, native_tokens_*, cache_discount, upstream_inference_cost, provider_name, latency, finish_reason, streamed, cancelled)
- **`OpenRouterService.fetchGeneration(id:apiKey:)`**: new method — calls `GET /generation?id=<genID>`, decodes stats, returns `(stats: GenerationStats, rawJSON: String)`
- **`ConversationStore.settleGenerationStats(...)`**: called after every stream completes — fetches `/generation`, stores the raw API JSON as `rawResponseJSON` on the assistant message, then corrects chat-level token/cost totals (removes streaming estimate, adds settled values)

### Changed
- **`ConversationStore.startAssistantResponse`**: removed `capturedFinishReason`; after stream loop now calls `settleGenerationStats` instead of `buildResponseJSON`. Live streaming estimate (`CachedModel.calculateCost`) is still used during the stream for real-time display, replaced by authoritative values once `/generation` responds.

### Removed
- **`ConversationStore.buildResponseJSON`**: deleted entirely — the synthetic JSON builder is now obsolete. `rawResponseJSON` contains the real `/generation` API record.

### Fixed
- **BUG-007** (follow-up): `autoTitleModelID` now returns `google/gemini-2.0-flash-lite` — `gemini-flash-1.5-8b` was deprecated on OpenRouter causing "Title Generation Failed" errors
- **BUG-009**: JSON inspector now shows authoritative API data — `total_cost`, native token counts, provider info, latency — instead of app-synthesized values
- **BUG-010**: Copy button `Image(systemName: "doc.on.doc")` in `MessageInspectorSheet` now wrapped in `.frame(width: 12, height: 12)` — eliminates height mismatch vs text-only Done button

### Notes
- All changes on branch `fix/quick-wins`; build passes clean
- The `/generation` fetch is fire-and-forget after stream end — failure is logged but silently ignored so a network blip here doesn't surface to the user

---

## [2026-03-06] - Quick Wins Batch: BUG-004/005/006/007/008, FR-001/007

### Fixed
- **BUG-004**: Removed deprecated `stream_options.include_usage` — deleted `StreamOptions` struct, `stream_options` field on `ChatRequest`, and the conditional assignment block in `OpenRouterService.buildRequestBody`
- **BUG-005**: `buildResponseJSON(...)` in `ConversationStore` now accepts a `cost: Double` parameter and includes `jchat_cost_usd` in the synthesized response object shown in the JSON inspector
- **BUG-006**: Done button in `MessageInspectorSheet` font weight changed `.semibold` → `.medium` to match the Copy button; both buttons now visually identical in weight
- **BUG-007**: Auto-title reliability overhauled — `autoTitleModelID(for:)` always returns `google/gemini-flash-1.5-8b` (no longer uses chat's active model); prompt rewritten with explicit system framing and `User:/Assistant:` format (removed erroneous literal `+` separators); `normalizedAutoTitle` relaxed to accept 1+ word titles and now only strips surrounding quotes/markdown characters using unicode escapes
- **BUG-008**: `InlineModelPicker` binding setter in `ConversationPane` now writes the selected model ID back to `AppSettings.defaultModelID` so new chats and post-restart sessions inherit the last-used model

### Added
- **FR-001**: User messages now show prompt token count in the metadata row (`if row.role == .user, row.promptTokens > 0`) — mirrors the existing assistant message metadata layout
- **FR-007**: New assistant message bubble fades in during streaming — `.transition(.opacity)` + `.animation(.easeIn(duration: 0.18), value: isLiveStreaming)` on the outer HStack in `MessageRow.body`

### Notes
- All changes on branch `fix/quick-wins`; build passes clean
- Backlog items also added to `KNOWN_ISSUES.md` this session: BUG-004 through BUG-008, FR-006 through FR-014

---

## [2026-03-06] - Bug Fixes: BUG-001, BUG-002, BUG-003

### Fixed
- **BUG-001**: Added `round2(_:)` helper in `OpenRouterService.buildRequestBody(from:)` — all `Double` parameters now rounded to 2 decimal places at serialization, eliminating IEEE 754 noise from API payloads and the JSON inspector
- **BUG-002**: Delete button in `MessageRow.actionToolbar` now hidden while `isLiveStreaming == true`, preventing ghost messages and stuck stop-button state from the stream/delete race condition
- **BUG-003**: Copy button in `MessageInspectorSheet` now uses `.contentTransition(.symbolEffect(.replace))` on the icon and `.transition(.opacity)` on the label text, eliminating the double-render crossover during the Copy→Copied transition

---

## [2026-03-06] - Code Quality Fixes and DRY Refactoring

### Changed
- `StreamTextAccumulator`: renamed `pending` → `bufferedText` for clarity
- `ConversationFeatureFlags`: added rationale comments to magic numbers (32 chars, 45 ms)
- `KeychainManager`: removed dead `synchronizable` property and stale TODO comments
- `ParameterInspector`: renamed `ParamDefault` → `ParameterDefaults` (32 sites)
- `ConversationStore`: named `autoTitleFallbackModelID` constant with doc comment; extracted `applyFlushed()` helper to collapse 3 repeated streaming update blocks
- `ModelManager`: extracted `sorted(_:by:)` as canonical sort method; `InlineModelPicker` now delegates to it
- `CachedModel`: promoted `formatPrice()` → `Double.formattedPrice` extension; `InlineModelPicker.compact()` deleted
- `Chat`: added `displayTitle` extension; duplicate computed vars removed from `ShellViews`
- `OpenRouterService`: extracted `prettyJSON(from:fallback:)` helper to eliminate 2 inline JSON pretty-print blocks
- `ContentView`: extracted `selectFirstChatIfNeeded()` to collapse 2 repeated nil-check blocks; replaced `try!` in `#Preview` with `do/catch` + graceful fallback

### Fixed
- `SettingsView`: removed duplicate `normalizeKey()` (was identical to `KeychainManager.normalizeKey()`); silent keychain error now logged
- `ConversationStore`, `ModelManager`: `try? save()` calls promoted to `do/catch` with log output — failures no longer silently swallowed
- `JChatTests`: updated 4 assertions from `.pending` to `.bufferedText`

### Notes
- All changes on branch `chore/code-quality-fixes`; build passes clean; no behavior changes

---

## [2026-03-06] - Icon, Preview Polish, Settings UX

### Added
- `WhisperQuill.icon`: Icon Composer file added to target — iridescent feather/fountain pen icon (generated with Gemini 3.1 Flash Image) now appears in Dock and app switcher
- `Views/ContentView.swift`: Two named `#Preview` blocks — `"Empty / Setup"` (pinned setup state via `previewForceSetup`) and `"Active Chat"` (seeded with `makePreviewContainer()` — 2 chats, 4 messages, 3 favorite models)

### Changed
- `Views/ContentView.swift`: Setup screen simplified — removed checklist row and secondary button; now just key icon + one-line message + "Open Settings" button, centered in detail pane
- `Views/ContentView.swift`: `ContentView.init` accepts optional `previewStore` and `previewForceSetup` for preview injection without keychain side-effects
- `Views/SettingsView.swift`: Validate button and `KeyValidationStatusView` merged into one `HStack` row — status slides in from leading edge on the same line as the button; credits chip fades in separately with `.transition(.opacity)` to avoid sliding from wrong direction

### Fixed
- Icon not appearing: `WhisperQuill.icon` was in wrong location (`UI/Icon/` and briefly inside `Assets.xcassets`); moved to top-level JChat group as a direct target member — this is the correct location for Icon Composer `.icon` files
- Stray misspelled `WhispherQuill.icon/` artifact at repo root deleted

### Notes
- Branch: `chore/liquid-glass-cohesion` (continued)
- `.icon` files are NOT asset catalog assets — they are standalone bundles processed by a dedicated Xcode build phase, not `actool`

---

## [2026-03-06] - Liquid Glass UI Cohesion Pass

### Changed
- `UI/Design/AppDesign.swift`: Removed `GlassCardModifier`, `SurfaceCardModifier`, `.glassCard()`, `.surfaceCard()` — replaced everywhere with native `.glassEffect(in:)` and `.buttonStyle(.glass)`
- `Views/ContentView.swift`: Setup card uses `.glassEffect(in: .rect(cornerRadius: 22))`
- `UI/ShellViews.swift`: Conversation header card and error banner use `.glassEffect(in: .rect(cornerRadius: 12))`
- `Views/Components/InlineModelPicker.swift`: Model picker button uses `.buttonStyle(.glass)` — now a real interactive Liquid Glass control (resolves FR-005)
- `Views/SettingsView.swift`: Validation result area replaced with `KeyValidationStatusView` — compact status card, inline chips for model count + credits, debug info only on failure, animated entry; keychain note moved to section footer; Validate button uses `.buttonStyle(.glass)` (resolves FR-004)
- `Docs/PROJECT_GUIDE.md`: Updated design system description to reflect native `.glassEffect(in:)` / `.buttonStyle(.glass)` as the standard

### Notes
- Branch: `chore/liquid-glass-cohesion`
- Zero behavior changes — pure UI/style pass
- All custom material approximations removed; system now handles blur, reflection, dark/tinted/clear adaptation automatically
- Build: clean, zero errors

---

## [2026-02-26] - Remove V2 Naming, Rename UI Directory

### Added
- `JChat/UI/` directory replacing `JChat/V2/`
- `JChat/UI/Design/AppDesign.swift` (renamed from `V2Design.swift`)
- `JChat/UI/ShellViews.swift` (renamed from `V2ShellViews.swift`)
- `JChat/UI/ParameterInspector.swift` (renamed from `V2ParameterInspector.swift`)

### Changed
- `SidebarView` (was `V2SidebarView`)
- `ConversationPane` (was `V2ConversationPane`)
- `MessageRow` (was `V2MessageRow`)
- `Composer` (was `V2Composer`)
- `ParameterInspector` (was `V2ParameterInspector`)
- `AppPalette` (was `V2Palette`)
- `CanvasBackground` (was `V2CanvasBackground`)
- `EmptyStateView` (was `V2EmptyStateView`)
- `Docs/PROJECT_GUIDE.md`: updated architecture section, removed V2 references, updated file paths

### Removed
- `JChat/V2/` directory and all contents

### Notes
- "V2" was a working name for the UI rewrite and is no longer meaningful — this is just the app's current UI
- Build verified clean after rename: `** BUILD SUCCEEDED **` (zero errors)
- `PBXFileSystemSynchronizedRootGroup` means Xcode auto-picks up renamed files/dirs — no pbxproj edits needed

---

## [2026-02-26] - Documentation Restructure & Standards Audit

### Added
- `Docs/CHANGELOG_INTERNAL.md` — Keep a Changelog format, session history
- `CLAUDE.md` — Docs index, AI tool policy, mode selection guide, multi-agent boundaries, changelog update policy

### Changed
- `CLAUDE.md` — Full rewrite; expanded from sparse pointer file to proper Claude Code entry point
- `CONTRIBUTING.md` — Streamlined to git workflow only; removed all content now owned by CLAUDE.md or PROJECT_GUIDE.md
- `Docs/PROJECT_GUIDE.md` — Removed duplicated Workflow Rules section; cleaned up build workflow repetition

### Removed
- `Docs/BRANCH_AUDIT.md` — Outdated V2 rewrite docs; V2 already merged to main
- All duplicated content across files (xcodebuildmcp policy, UI standards, validation commands previously scattered across multiple files)

### Notes
- Strict content ownership: each topic lives in exactly one file
- Universal format across Claude, Codex, Gemini — canonical docs in `Docs/` readable by any AI
- End-of-session changelog update is now an automatic policy in CLAUDE.md

---

## [2026-02-26] - Build Configuration Audit

### Added
- `CHANGELOG_INTERNAL.md` created as living session history (Keep a Changelog format)
- `Docs/PROJECT_GUIDE.md`: xcodebuildmcp environment specs, defaults schema, and full command reference
- `CLAUDE.md`: policy to update CHANGELOG_INTERNAL.md at end of each session
- Memory system for tracking project patterns across sessions

### Changed
- `Docs/PROJECT_GUIDE.md`: reorganized Build Environment section for clarity
- `Docs/PROJECT_GUIDE.md`: clarified clean-before-build workflow as standard practice
- `CONTRIBUTING.md`: corrected xcodebuildmcp app name reference

### Removed
- `Docs/BRANCH_AUDIT.md` (outdated V2 rewrite documentation; V2 already merged to main)

### Notes
- xcodebuildmcp defaults now set once per session via `session-set-defaults`
- Documentation structure cleaned up; all build/validation info now centralized in PROJECT_GUIDE.md

---

## How This File Works

At the **end of each session**, add a new entry:

```markdown
## [YYYY-MM-DD] - Session Title

### Added
- New files or features

### Changed
- Modified existing files/behavior

### Fixed
- Bug fixes

### Removed
- Deleted files or features

### Notes
- Context, decisions, blockers, follow-up work
```

**Format rules:**
- Use date as version: `[YYYY-MM-DD]`
- Use a descriptive title after the date
- Keep sections short and scannable
- Use relative paths for files (e.g., `Docs/PROJECT_GUIDE.md`)
- Include "Notes" if there are decisions or follow-up work

This is your living record of why things changed and what context future sessions need.
