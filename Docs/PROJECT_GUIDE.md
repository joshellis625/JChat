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
- App does not require a global default model before chatting.

## Key Files
- `/Users/josh/Projects/JChat/JChat/Views/ChatViewModel.swift`
- `/Users/josh/Projects/JChat/JChat/Services/OpenRouterService.swift`
- `/Users/josh/Projects/JChat/JChat/Views/ConversationView.swift`
- `/Users/josh/Projects/JChat/JChat/Views/MessageInputView.swift`
- `/Users/josh/Projects/JChat/JChat/Views/MessageBubble.swift`
- `/Users/josh/Projects/JChat/JChat/Views/ChatToolbarView.swift`

## Engineering Standards
- Code changes use feature branches: `codex/<topic>`.
- Documentation-only changes are made directly on `main`.
- **No PRs**. Merge locally when done.
- **No CI required**. Local build/run is the gate.
- **Push only with explicit approval.**
- Keep changes reasonably scoped per branch (feature/bugfix/doc pass).

## Accessibility Guidelines
- Lead dev is red-green color-deficient. Use of colors is encouraged but avoid problematic combinations and consider the visual context. Prefer primary colors but creativity is encouraged.
- If color alone might be an issue, use text labels to supplement.
- Use strong contrast for important visual elements.
- Prefer emphasis through hierarchy/weight/color/contrast, not opacity dimming.

## Build and Test
Preferred (via `XcodeBuildMCP`):
```bash
xcodebuildmcp macos build-macos --project-path /Users/josh/Projects/JChat/JChat.xcodeproj --scheme JChat
xcodebuildmcp macos test-macos --project-path /Users/josh/Projects/JChat/JChat.xcodeproj --scheme JChat
```

Fallback (direct shell):
```bash
xcodebuild build -project JChat.xcodeproj -scheme JChat -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO
xcodebuild test -project JChat.xcodeproj -scheme JChat -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO
```

## Xcode MCP Integration
JChat uses `XcodeBuildMCP` as the primary MCP server for Apple platform development workflows.

### Primary Server (Required)
Use the third-party `XcodeBuildMCP` server first for all Xcode workflows.

Quick local verification commands:
```bash
xcodebuildmcp --help
xcodebuildmcp tools
xcodebuildmcp doctor
```

Verified in this repository:
- `xcodebuildmcp --help` is available and returns command help.
- MCP project discovery finds `/Users/josh/Projects/JChat/JChat.xcodeproj`.
- `xcodebuildmcp macos build-macos` succeeds for scheme `JChat`.
- `xcodebuildmcp macos test-macos` succeeds for scheme `JChat` (`7/7` tests passed on 2026-02-10).

### Fallback Mode (If MCP Is Not Needed)
Use direct `xcodebuild` shell commands when MCP-specific features are unnecessary.

### Verified `XcodeBuildMCP` Capabilities for This Project
- Project discovery (`discover_projs`)
- Build/test workflows for simulator (`build_sim`, `test_sim`, `build_run_sim`)
- Simulator lifecycle and app control (`list_sims`, `boot_sim`, `install_app_sim`, `launch_app_sim`)
- UI inspection and visual validation (`snapshot_ui`, `screenshot`, `record_sim_video`)
- Logging and diagnostics (`start_sim_log_cap`, `stop_sim_log_cap`, `show_build_settings`)

### Recommended Usage
- Prefer `XcodeBuildMCP` for build/test/simulator/UI verification loops.
- Use simulator screenshots/videos for UI regression checks and iteration.
- Fall back to direct `xcodebuild` shell commands only when MCP tooling is unnecessary.

## Related Docs
- Workflow: `/Users/josh/Projects/JChat/Docs/DEV_WORKFLOW.md`
- Regression QA: `/Users/josh/Projects/JChat/Docs/REGRESSION_CHECKLIST.md`
- Codex usage: `/Users/josh/Projects/JChat/Docs/CODEX_PLAYBOOK.md`
- Roadmap: `/Users/josh/Projects/JChat/Docs/ROADMAP.md`
- Internal change log: `/Users/josh/Projects/JChat/Docs/CHANGELOG_INTERNAL.md`
- Historical docs archive: `/Users/josh/Projects/JChat/Docs/archive/`
