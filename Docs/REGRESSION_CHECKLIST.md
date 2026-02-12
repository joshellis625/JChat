# JChat Regression Checklist (V2)

Run this before shipping any change that touches chat behavior, streaming, layout, or persistence.

## Build + Launch
- [ ] Build succeeds (`xcodebuildmcp macos build`).
- [ ] For risky behavior changes, tests pass (`xcodebuildmcp macos test`).
- [ ] App launches and can be stopped cleanly (`xcodebuildmcp macos build-and-run` + `xcodebuildmcp macos stop --app-name JChat`).

## Core V2 Chat Flow
- [ ] Create new chat.
- [ ] Send user message.
- [ ] Assistant starts streaming response.
- [ ] Stop streaming mid-response.
- [ ] Send another message after stopping.
- [ ] Regenerate an assistant response.

## Long-Chat Stability
- [ ] Open a long conversation and scroll continuously.
- [ ] Type in composer while scrolling long transcript.
- [ ] No beachball/freeze occurs during typing + scroll.
- [ ] Streaming response stays visible and follows to bottom.
- [ ] Opening a chat lands at the bottom of transcript.

## Message Rendering + Alignment
- [ ] User messages are right aligned.
- [ ] Assistant messages are left aligned.
- [ ] Message timestamps render correctly.
- [ ] Assistant per-message token label is not chat-total token count.
- [ ] No obvious clipping/overlap in long messages.

## Conversation List (Sidebar)
- [ ] Selecting chats is immediate.
- [ ] Selected row contrast is clear.
- [ ] Timestamp is static text (not continuously counting).
- [ ] Preview text remains single-line and stable.

## Usage Accounting
- [ ] Chat total tokens/cost update on new assistant usage events.
- [ ] Deleting messages does not refund totals.
- [ ] Regenerating does not refund prior usage totals.

## Setup Guardrails
- [ ] Missing API key shows setup UI.
- [ ] Configured API key allows normal chat usage (model can be selected per chat if no global default is set).

## Rendering Mode
- [ ] Plain text rendering works for assistant output.
- [ ] No markdown parser regressions impact streaming (markdown currently disabled by design).

## Persistence
- [ ] Reopen app and confirm chats persist.
- [ ] Reopen app and confirm settings persist.
- [ ] API key remains accessible from Keychain.

## Sign-Off
- [ ] Update `/Users/josh/Projects/JChat/Docs/CHANGELOG_INTERNAL.md` for behavior changes.
- [ ] Document any known risk or deferred follow-up.
