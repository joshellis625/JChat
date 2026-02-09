# JChat Project Guide (Canonical)

This is the single source of truth for project architecture, constraints, and development standards.

## Product Overview
JChat is a native macOS SwiftUI chat app that uses the OpenRouter API to chat with multiple models, manage conversation history, tune model parameters, track usage/costs, and use reusable "Characters" (persona presets).

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
- App requires global default model before chatting

## Key Files
- `/Users/josh/Projects/JChat/JChat/Views/ChatViewModel.swift`
- `/Users/josh/Projects/JChat/JChat/Services/OpenRouterService.swift`
- `/Users/josh/Projects/JChat/JChat/Views/ConversationView.swift`
- `/Users/josh/Projects/JChat/JChat/Views/MessageInputView.swift`
- `/Users/josh/Projects/JChat/JChat/Views/MessageBubble.swift`
- `/Users/josh/Projects/JChat/JChat/Views/ChatToolbarView.swift`

## Engineering Standards
- Feature branches only: `codex/<topic>`
- PR required for every change
- Small PRs with testing evidence
- CI must pass before merge (currently build-focused on GitHub hosted runners)

## Accessibility Constraints
- Avoid purple
- Use strong contrast for status signals
- Prefer emphasis through hierarchy/weight, not opacity dimming

## Build and Test
```bash
xcodebuild build -project JChat.xcodeproj -scheme JChat -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO
xcodebuild test -project JChat.xcodeproj -scheme JChat -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO
```

## Related Docs
- Workflow: `/Users/josh/Projects/JChat/JChat/Documentation/DEV_WORKFLOW.md`
- Codex usage: `/Users/josh/Projects/JChat/JChat/Documentation/CODEX_PLAYBOOK.md`
- Roadmap: `/Users/josh/Projects/JChat/JChat/Documentation/ROADMAP.md`
- Internal change log: `/Users/josh/Projects/JChat/JChat/Documentation/CHANGELOG_INTERNAL.md`
- Historical docs archive: `/Users/josh/Projects/JChat/JChat/Documentation/archive/`
