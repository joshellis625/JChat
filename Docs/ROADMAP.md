# JChat Roadmap (V2)

## Current Priority Order
1. Freeze prevention and transcript stability in long chats.
2. V2 UI polish toward a clean ChatGPT-style experience.
3. Reliability and consistency of OpenRouter streaming behavior.
4. Documentation consistency and low-friction solo workflow.
5. Controlled feature re-expansion only after stability is locked.

## Active Workstream: V2 Stabilization
- Keep V2 shell as default and continue reducing unnecessary UI layers.
- Maintain stable typing/scrolling under long transcripts.
- Keep streaming smooth and visible with reliable bottom-follow behavior.
- Ensure per-message metadata (tokens/cost/time) is accurate and clear.

## Near-Term Backlog
- Improve conversation list density and readability.
- Add a simple optional “show older messages” affordance when stability truncation is active.
- Add additional tests around `ConversationStore` streaming and cancellation edge cases.
- Add targeted UI tests for long-chat scroll + send/regenerate sequences.
- Keep visual system neutral/system-native (material first, no cartoon gradients).

## Feature Return Queue (After Stability)
- Export conversation to raw OpenRouter JSON.
- Optional markdown rendering mode (feature-flagged).
- Improved keyboard shortcut set for power use.
- First-launch onboarding flow.

## Future Exploration
- iOS runtime polish and feature parity.
- Cross-device sync approach for chats/settings.
- Tool/function calling controls.
- Memory features across chats.
- Provider routing controls.
