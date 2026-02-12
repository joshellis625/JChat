# JChat Foundation Rebuild Plan (V2 Status)

## Purpose
This document tracks the V2 foundation rebuild status and the next hardening steps.

## Current Status (2026-02-11)
The app is in a V2-first state:
- V2 shell is the default interface.
- Conversation state runs through `ConversationStore`.
- OpenRouter request pipeline was refactored around `ModelCallRequest`.
- Retry/error handling and SSE parsing were hardened.
- Major freeze sources were reduced through render and streaming-path fixes.

## What Is Already Done

### Architecture
- Added conversation core abstractions under `/Users/josh/Projects/JChat/JChat/Core/Conversation`:
  - `ChatRepositoryProtocol` + `SwiftDataChatRepository`
  - `ChatEngineProtocol` + `OpenRouterChatEngine`
  - `ConversationStore`
  - `MessageRowViewData`
  - `StreamTextAccumulator`

### OpenRouter Pipeline
- Unified send/stream entry around `ModelCallRequest`.
- Added `RetryPolicy` with transient HTTP retry support (`429`, `500`, `502`, `503`, `504`).
- Implemented `Retry-After` support.
- Hardened SSE parsing for keepalive, malformed, and usage-only chunks.

### UI Foundation
- V2 shell and visual primitives created in:
  - `/Users/josh/Projects/JChat/JChat/V2/UI/V2ShellViews.swift`
  - `/Users/josh/Projects/JChat/JChat/V2/Design/V2Design.swift`
- `ContentView` now routes to V2 shell.
- Composer/transcript layering simplified.

### Stability Work
- Long-transcript rendering now uses defensive limits in stability mode.
- Streaming text is coalesced and applied with lower layout churn.
- Assistant streaming content is persisted at completion/cancel/error (not every token flush).
- Auto-scroll behavior tuned for open + active streaming.

## Non-Negotiables (Still Active)
1. Keep chat send/regenerate reliable.
2. Keep streaming responsive and cancellable.
3. Prioritize stability before feature expansion.
4. Keep architecture compatible with eventual macOS+iOS parity.
5. Keep macOS arm64-only support.

## Remaining Work (Next Phases)

### Phase 2: V2 Productization
- Add structured conversation detail metadata (per-message diagnostics, optional debug traces).
- Finalize visual polish for spacing, alignment, and material depth.
- Add more stress-oriented transcript tests for long chats.

### Phase 3: Feature Return (After Stability)
- Reintroduce richer rendering carefully (optional markdown mode behind flag).
- Add export formats (raw OpenRouter JSON first; Markdown later if rendering returns).
- Reintroduce advanced controls only behind safe defaults.

### Phase 4: Cross-Platform Hardening
- Validate iOS runtime behavior with the same conversation core.
- Add platform-specific interaction polish (keyboard/toolbars/gesture expectations).

## Explicitly Deferred
- TypeScript runtime integration for OpenRouter SDK.
- Multi-provider routing layer.
- Hosted backend deployment.

## Acceptance Criteria for Rebuild Completion
1. No UI hangs in normal long-chat usage (typing + scrolling + streaming).
2. V2 shell remains the single default conversation surface.
3. OpenRouter failures produce clear user-facing errors after retries exhaust.
4. Tests cover request encoding, streaming parsing, retry behavior, and usage accounting.
5. Documentation remains synced with implementation.
