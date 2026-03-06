# JChat — Known Issues & Feature Requests

Tracked here until migrated to GitHub Issues or Linear.

---

## Bugs

### ~~BUG-001: Floating-point precision in parameter values~~ ✅ Resolved 2026-03-06
Added `round2(_:)` helper in `OpenRouterService.buildRequestBody(from:)` — rounds all `Double` parameters to 2 decimal places at the serialization boundary using `(value * 100).rounded() / 100`. Eliminates IEEE 754 noise from both the API payload and the JSON inspector without touching the storage layer.

### ~~BUG-002: Deleting a message mid-stream causes ghost message / stuck stop button~~ ✅ Resolved 2026-03-06
Delete button in `MessageRow.actionToolbar` is now hidden while `isLiveStreaming == true`. The prop was already threaded into `MessageRow`; added `&& !isLiveStreaming` to the existing `if !isEditing` guard.

### ~~BUG-003: JSON Inspector Copy button transition has visible crossover~~ ✅ Resolved 2026-03-06
Applied `.contentTransition(.symbolEffect(.replace))` to the `Image` and `.transition(.opacity)` to the `Text` label independently inside `MessageInspectorSheet`. This prevents the old and new content from rendering simultaneously during the animation frame.

---

## Feature Requests

### FR-001: Show token count and cost metadata on user messages
**Priority:** Medium
**Where:** Message metadata row below user message bubbles
**What:** Currently only assistant messages show token count and cost. User messages should display the same metadata (prompt tokens, cost) since we already capture this data on the user `Message` object. This gives full visibility into what each turn costs.
**Design note:** The user message metadata should match the assistant message layout for visual consistency — timestamp, token count, cost, all in the same style.

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

---

## Status Key

| Tag | Meaning |
|-----|---------|
| **Bug** | Something broken or incorrect |
| **FR** | Feature request or enhancement |
| **Severity/Priority** | High > Medium > Low |

*Last updated: 2026-03-06*
