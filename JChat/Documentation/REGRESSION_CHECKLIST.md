# JChat Regression Checklist

Use this checklist before merging any branch that changes chat behavior, model settings, or message rendering.

## Setup
- [ ] Build app succeeds.
- [ ] Unit tests (`JChatTests`) pass.
- [ ] App launches with existing data store.

## Core Chat Flow
- [ ] Create new chat.
- [ ] Send user message.
- [ ] Assistant starts streaming response.
- [ ] Stop streaming mid-response.
- [ ] Send another message after stopping.

## Message Operations
- [ ] Edit a user message and save.
- [ ] Edit an assistant message and save.
- [ ] Cancel message edit without saving.
- [ ] Copy message content.
- [ ] Regenerate assistant response.
- [ ] Delete a message and confirm totals remain the same. Messages are non-refundable generations from the API.

## Toolbar + Parameters
- [ ] Character picker works.
- [ ] Model picker works and is refreshed and updates CachedModel from API upon opening.
- [ ] Parameters panel opens/closes cleanly.
- [ ] Override count updates when overrides are changed/reset.
- [ ] Token/cost pills render without layout overlap and totals are not altered from message deletions.

## Setup Guardrails
- [ ] No API key shows setup checklist (Not implemented yet).
- [ ] With API key configured, conversation view is shown.

## Markdown Rendering
- [ ] Inline markdown (bold/italic/code/links) displays correctly.
- [ ] Fenced code block displays with readable contrast.
- [ ] Code block copy action works.
- [ ] Missing language fence shows `text` label.
- [ ] Proper response streaming remains intact and 

## Settings + Persistence
- [ ] Save settings and reopen app.
- [ ] Text size multiplier persists.
- [ ] Default model persists.
- [ ] API key remains available via Keychain.
- [ ] All existing chat conversations remain as they were.

## Sign-Off
- [ ] Any new behavior is documented in `CHANGELOG_INTERNAL.md`.
- [ ] No reversals without explicit user authorization.
- [ ] Any reversals include risks and rollback note.
