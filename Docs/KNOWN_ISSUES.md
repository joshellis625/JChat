# JChat — Known Issues & Feature Requests

Tracked here until migrated to GitHub Issues or Linear.

---

## Bugs

### BUG-001: Floating-point precision in parameter values
**Severity:** Medium (cosmetic, but appears in API requests)
**Where:** Parameter inspector JSON, API request body
**What:** Values like `top_p` and `temperature` display with IEEE 754 floating-point noise — e.g. `0.9500000000000001` instead of `0.95`, or `1.2000000000000002` instead of `1.20`.
**Root cause:** Swift `Double` representation. When the user sets `0.95` via a slider or field, the stored Double isn't exactly `0.95` in binary. This bleeds through to both the JSON request body sent to OpenRouter and the inspector display.
**Fix approach:** Round parameter values to 2 decimal places at the serialization boundary (when building `ModelCallRequest`), not at the storage layer. Something like `(value * 100).rounded() / 100` or a `Decimal`-based format.
**Screenshots:** `Parameter values need to be limited to two decimal places.png`, `Parameter values not limited to two decimal places #2.png`

### BUG-002: Deleting a message mid-stream causes ghost message / stuck stop button
**Severity:** High (state corruption)
**Where:** Message action toolbar delete button during active streaming
**What:** If you click the delete button twice on a message that's currently streaming, it deletes successfully but leaves the input bar's square "stop" icon stuck in the stop state. Sometimes the full message reappears after deletion because the stream task continues writing to the (now-deleted) message object. Some model providers don't support stream cancellation.
**Fix approach:** Hide the delete button entirely while a message is actively streaming (`isLiveStreaming == true`). Only show it once the stream is complete. This avoids the race condition between stream task writes and SwiftData deletion.

### BUG-003: JSON Inspector Copy button transition has visible crossover
**Severity:** Low (cosmetic)
**Where:** `MessageInspectorSheet` header bar Copy/Copied button
**What:** When clicking Copy, the transition from "Copy" to "Copied" (with green checkmark) shows both labels overlapping briefly — the old icon/text and the new one are visible simultaneously during the animation frame.
**Fix approach:** Use `.contentTransition(.symbolEffect(.replace))` or wrap in an explicit `.animation` with `.transition(.opacity)` so the old content fully fades before the new content appears. Alternatively, use a fixed-width frame on the button to prevent layout shift.
**Screenshot:** `JSON Inspector Copy Button UI Tweak.png`

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

### FR-004: Settings popover needs professional redesign
**Priority:** Medium
**Where:** Settings popover/sheet (accessed from sidebar)
**What:** The current settings UI is functional but visually rough — spacing, typography, and grouping need a professional pass. Note that character/persona implementation hasn't been done yet, so the "Default Character" picker is a placeholder.
**Screenshot:** `Screenshot 2026-02-25 at 6.22.24 AM.png`

### FR-005: Inline model picker needs visual polish
**Priority:** Low (cosmetic)
**Where:** Chat header bar, model picker dropdown (e.g. "DeepSeek V3.2")
**What:** The model picker pill/capsule in the chat header doesn't visually fit well around the model name. It looks unpolished — the padding, border radius, or background treatment needs refinement to feel like a native macOS control.
**Screenshot:** `Screenshot 2026-02-25 at 6.23.46 AM.png`

---

## Status Key

| Tag | Meaning |
|-----|---------|
| **Bug** | Something broken or incorrect |
| **FR** | Feature request or enhancement |
| **Severity/Priority** | High > Medium > Low |

*Last updated: 2026-02-25*
