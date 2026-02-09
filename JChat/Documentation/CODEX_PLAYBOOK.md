# JChat Codex Playbook

Use this guide to collaborate with Codex like a professional dev partner.

## Before Coding: Prompt Pattern
Use this structure:
1. Goal
2. Constraints
3. Files likely involved
4. Acceptance criteria
5. Output format expected

Example:
"Improve message input ergonomics in `/Users/josh/Projects/JChat/JChat/Views/MessageInputView.swift`. Keep visual style consistent. Ensure Return sends and Shift+Return new line still works. Provide diff summary + testing checklist."

## During Coding: Ask For
- Small scoped changes
- Explicit file references
- Why the change is safe
- Risks and follow-up ideas

## After Coding: Always Ask
- "What could break?"
- "What tests should I add next?"
- "What should be split into a separate PR?"

## Best Task Types for Codex
- UI refinements
- Refactors with behavior parity
- Bug triage and root cause analysis
- Documentation consolidation
- Workflow and automation setup

## Xcode MCP Workflow (Preferred for UI Work)
When Xcode MCP is available, ask Codex to:
1. Build in Xcode MCP.
2. Run tests in Xcode MCP.
3. Render specific `#Preview` entries and return snapshot paths.
4. Iterate on UI with screenshot-backed feedback.

Prompt example:
"Use Xcode MCP to render preview snapshots for `/Users/josh/Projects/JChat/JChat/Views/ConversationView.swift` and `/Users/josh/Projects/JChat/JChat/Views/MessageInputView.swift`, then improve spacing/contrast and re-render."

Quick MCP sanity checks:
```bash
codex mcp list
codex mcp get xcode
```

## Guardrails
- Do not skip branch + PR flow
- Do not merge with failing CI unless emergency
- Do not batch unrelated changes in one PR
