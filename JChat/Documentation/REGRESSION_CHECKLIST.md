# JChat Regression Checklist

Use this checklist before merging any PR that changes chat behavior, model settings, or message rendering.

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
- [ ] Delete a message and confirm totals remain sensible.

## Toolbar + Parameters
- [ ] Character picker works.
- [ ] Model picker works.
- [ ] Parameters panel opens/closes cleanly.
- [ ] Override count updates when overrides are changed/reset.
- [ ] Token/cost pills render without layout overlap.

## Setup Guardrails
- [ ] No API key + no default model shows setup checklist.
- [ ] API key only still requires default model.
- [ ] Default model only still requires API key.
- [ ] With both configured, conversation view is shown.

## Markdown Rendering
- [ ] Inline markdown (bold/italic/code/links) displays correctly.
- [ ] Fenced code block displays with readable contrast.
- [ ] Code block copy action works.
- [ ] Missing language fence shows `text` label.

## Settings + Persistence
- [ ] Save settings and reopen app.
- [ ] Text size multiplier persists.
- [ ] Default model persists.
- [ ] API key remains available via Keychain.

## Sign-Off
- [ ] Any new behavior is documented in `CHANGELOG_INTERNAL.md`.
- [ ] PR includes risks and rollback note.
