# JChat Project Guide (Canonical)

This is the single source of truth for project architecture, constraints, and development standards.

## Product Overview
JChat is a native macOS (future iOS) SwiftUI chat app that uses the OpenRouter API to chat with multiple models, manage conversation history, tune model parameters, track usage/costs, and use reusable "Characters" (persona presets).

## Architecture
- UI: SwiftUI
- State: MVVM (`ChatViewModel`, `ModelManager`)
- Persistence: SwiftData (`Chat`, `Message`, `AppSettings`, `Character`, `CachedModel`)
- API layer: `OpenRouterService` actor with raw `URLRequest` and JSON
- Secrets: Keychain (`KeychainManager`)

## Core Behavior
- Parameter precedence: chat override -> global settings fallback
- Character model is identity-only (name/prompt/preferred model), no parameter storage
- New chat inherits parameter overrides from most recent chat
- App DOES NOT requires global default model before chatting

## Key Files
- `/Users/josh/Projects/JChat/JChat/Views/ChatViewModel.swift`
- `/Users/josh/Projects/JChat/JChat/Services/OpenRouterService.swift`
- `/Users/josh/Projects/JChat/JChat/Views/ConversationView.swift`
- `/Users/josh/Projects/JChat/JChat/Views/MessageInputView.swift`
- `/Users/josh/Projects/JChat/JChat/Views/MessageBubble.swift`
- `/Users/josh/Projects/JChat/JChat/Views/ChatToolbarView.swift`

## Engineering Standards
- Feature branches only: `codex/<topic>`
- **No PRs**. Merge locally when done.
- **No CI required**. Local build/run is the gate.
- Keep changes reasonably scoped per branch (feature/bugfix/doc pass).

## Accessibility Guidelines
- Lead dev is red-green color-deficient. Use of colors is encouraged but avoid problematic combinations and consider the visual context. Prefer primary colors but creativity is encouraged.
- If color alone might be an issue, use text labels to supplement.
- Use strong contrast for important visual elements.
- Prefer emphasis through hierarchy/weight/color/contrast, not opacity dimming.

## Build and Test
```bash
xcodebuild build -project JChat.xcodeproj -scheme JChat -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO
xcodebuild test -project JChat.xcodeproj -scheme JChat -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO
```

## Xcode MCP Integration
JChat uses Xcode's MCP bridge so Codex can interact with your live Xcode session for build/test/preview workflows.

### Setup
```bash
codex mcp add xcode -- xcrun mcpbridge
codex mcp list
```

Expected entry:
- Name: `xcode`
- Command: `xcrun`
- Args: `mcpbridge`
- Status: `enabled`

If the server is added but not visible in a current chat session, restart the Codex app/session.

### Verified MCP Capabilities for This Project
- Detect active workspace/window (`XcodeListWindows`)
- Build via Xcode (`BuildProject`)
- Run tests from active test plan (`RunAllTests` / `RunSomeTests`)
- Render SwiftUI previews and capture snapshot image paths (`RenderPreview`)
- Read/grep/update files through Xcode project paths (`XcodeRead`, `XcodeGrep`, `XcodeUpdate`, etc.)

### Recommended Usage
- Prefer MCP build/test/preview checks for UI work and Xcode-specific validation.
- Keep GitHub Actions CI as the cross-machine safety net.
- Use MCP preview snapshots when iterating on SwiftUI layout or visual regressions.

## Related Docs
- Workflow: `/Users/josh/Projects/JChat/JChat/Documentation/DEV_WORKFLOW.md`
- Regression QA: `/Users/josh/Projects/JChat/JChat/Documentation/REGRESSION_CHECKLIST.md`
- Codex usage: `/Users/josh/Projects/JChat/JChat/Documentation/CODEX_PLAYBOOK.md`
- Roadmap: `/Users/josh/Projects/JChat/JChat/Documentation/ROADMAP.md`
- Internal change log: `/Users/josh/Projects/JChat/JChat/Documentation/CHANGELOG_INTERNAL.md`
- Historical docs archive: `/Users/josh/Projects/JChat/JChat/Documentation/archive/`
