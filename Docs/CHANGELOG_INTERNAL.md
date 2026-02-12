# Internal Changelog

## 2026-02-11
- Made V2 conversation shell the documented primary app surface.
- Updated canonical docs to reflect current `ConversationStore` + V2 architecture.
- Documented OpenRouter pipeline refactor status (`ModelCallRequest`, retry policy, hardened SSE parsing).
- Added explicit V2 stability guidance for long-chat behavior and streaming updates.
- Updated regression checklist for freeze-focused QA (typing + scrolling + streaming).
- Added archive clarity guidance so historical docs are not mistaken for current behavior.

## 2026-02-10
- Standardized docs on a no-PR, no-CI solo workflow.
- Added explicit push-approval gate to workflow guidance.
- Added docs-only exception: documentation updates can be made directly on `main`.
- Replaced legacy Xcode MCP bridge references with `XcodeBuildMCP` guidance.
- Fixed small doc quality issues (typos and incomplete checklist wording).

## 2026-02-09
- Added branch-first solo workflow standards via `/Users/josh/Projects/JChat/CONTRIBUTING.md`.
- Added PR template at `/Users/josh/Projects/JChat/.github/pull_request_template.md`.
- Added minimal CI workflow at `/Users/josh/Projects/JChat/.github/workflows/ci.yml`.
- Introduced canonical documentation hub at `/Users/josh/Projects/JChat/Docs/PROJECT_GUIDE.md`.
- Added workflow and Codex usage guides.
- Started UI/UX Pass A for message composer, message bubbles, and toolbar clarity.
- Added targeted unit tests for core chat model behavior.
- Improved Markdown code block readability with stronger contrast, consistent header labels, and always-visible copy action.
- Replaced abrupt setup blocking with a first-run readiness checklist for API key and default model in `ContentView`.
- Added a canonical manual regression checklist for chat, setup guardrails, markdown, and settings persistence flows.
- Hardened chat usage accounting by clamping token/cost totals at zero during delete/regenerate paths.
- Optimized CI with workflow concurrency to auto-cancel stale in-progress runs per branch.
- Documented Xcode MCP setup and capabilities for build/test/preview screenshot workflows.
- Removed all PR and CI related instructions and removed use of CI completely by choice. This project is pivoting to a no-PR, no-CI, branch-based development flow for solo-dev hobby-level simplicity.
