# JChat Project Guide (Canonical)

This is the single source of truth for architecture, workflow, validation, and active direction.

## Product Overview
WhisperQuill is a native SwiftUI chat app for macOS that connects to OpenRouter.

Current direction:
- Stability and responsiveness are prioritized over feature breadth.
- macOS (`arm64`) is the primary daily target.
- UI: native SwiftUI, Liquid Glass/material surfaces, SF Symbols.
- Source of truth for UI standards: [Apple SwiftUI Documentation](https://developer.apple.com/documentation/swiftui) and Apple HIG.

## Reference Links

### Apple Developer Documentation
| Resource | URL |
|----------|-----|
| SwiftUI Documentation | https://developer.apple.com/documentation/swiftui |
| SwiftData Documentation | https://developer.apple.com/documentation/swiftdata |
| Human Interface Guidelines (HIG) | https://developer.apple.com/design/human-interface-guidelines |
| HIG — macOS Patterns | https://developer.apple.com/design/human-interface-guidelines/designing-for-macos |
| HIG — Toolbars | https://developer.apple.com/design/human-interface-guidelines/toolbars |
| HIG — Sheets | https://developer.apple.com/design/human-interface-guidelines/sheets |
| SF Symbols Browser | https://developer.apple.com/sf-symbols |
| Foundation (Keychain, URLSession) | https://developer.apple.com/documentation/foundation |
| Security / Keychain Services | https://developer.apple.com/documentation/security/keychain_services |
| Swift Concurrency (async/await) | https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency |

### OpenRouter API
| Resource | URL |
|----------|-----|
| OpenRouter API Reference | https://openrouter.ai/docs/api-reference/overview |
| OpenAPI Spec (YAML) | https://openrouter.ai/openapi.yaml |
| OpenAPI Spec (local copy) | `Docs/openapi.json` |
| Chat Completions endpoint | https://openrouter.ai/docs/api-reference/chat-completion |
| Generation Stats endpoint (`GET /generation`) | https://openrouter.ai/docs/api-reference/get-a-generation |
| Streaming (SSE) | https://openrouter.ai/docs/api-reference/streaming |
| Models list | https://openrouter.ai/models |

## Runtime Architecture
- UI shell: `NavigationSplitView` with `SidebarView` + `ConversationPane`
- State owner: `ConversationStore`
- Persistence: `ChatRepositoryProtocol` + `SwiftDataChatRepository`
- Engine: `ChatEngineProtocol` + `OpenRouterChatEngine`
- Networking: `OpenRouterService` unified on `ModelCallRequest` (send + stream)
- Design system: `AppPalette` color tokens in `UI/Design/AppDesign.swift`; chrome/controls use native `.glassEffect(in:)` and `.buttonStyle(.glass)` directly

Primary files:
- `JChat/Views/ContentView.swift`
- `JChat/UI/ShellViews.swift`
- `JChat/UI/Design/AppDesign.swift`
- `JChat/UI/ParameterInspector.swift`
- `JChat/Core/Conversation/ConversationStore.swift`
- `JChat/Core/Conversation/ChatEngine.swift`
- `JChat/Core/Conversation/ChatRepository.swift`
- `JChat/Services/OpenRouterService.swift`
- `JChat/Chat.swift`

## Behavioral Rules
- Parameter precedence: chat override -> global settings fallback.
- Character stores identity/system prompt/preferred model only.
- API key is Keychain-only (`com.josh.jchat` / `openrouter-api-key`).
- Message delete/regenerate does not refund usage totals.
- Markdown rendering is intentionally disabled in current stability mode (plain text transcript rows).

## Build Environment
- **macOS:** 26.3 Stable
- **Xcode:** 26.3 RC2 (not 26.4 Beta 2 — risk of breaking changes)
- **Target:** arm64 ONLY (no Intel, no simulators)
- **Destination:** "Any Mac - arm64 only" or "My Mac - arm64"
- **Signing:** Auto-signed by Xcode (Apple Developer account registered)
- **Persistence:** SwiftData + Keychain (`com.josh.jchat` / `openrouter-api-key`)

## XcodeBuildMCP Defaults (Required — Set Once per Session)
Use `xcodebuildmcp` for all Xcode tasks. Do not use raw `xcodebuild`.

**Canonical defaults schema:**
```json
{
  "projectPath": "/Users/josh/Projects/JChat/WhisperQuill.xcodeproj",
  "scheme": "WhisperQuill",
  "configuration": "Debug",
  "arch": "arm64",
  "platform": "macOS"
}
```

**One-time setup command:**
```
session-set-defaults {
  "projectPath": "/Users/josh/Projects/JChat/WhisperQuill.xcodeproj",
  "scheme": "WhisperQuill",
  "configuration": "Debug",
  "arch": "arm64",
  "platform": "macOS"
}
```

**Notes:**
- Set defaults once per session — they persist within the session
- No simulators; macOS arm64 only

## Validation Commands

**Always clean before build** to avoid stale artifacts.

**Clean + build (fast iteration):**
```bash
xcodebuildmcp macos clean --platform macOS
xcodebuildmcp macos build --output text
```

**Launch/stop sanity check:**
```bash
xcodebuildmcp macos clean --platform macOS
xcodebuildmcp macos build-and-run --output text
xcodebuildmcp macos stop --app-name WhisperQuill --output text
```

**Run app (attach to running process):**
```bash
xcodebuildmcp macos run --output text
```

**Full test suite:**
```bash
xcodebuildmcp macos test --output text
```

**Screenshotting:**
Use the MCP Codriver to take screenshots of the running app:
```bash
mcp__codriver__desktop_screenshot
```
Useful for UI validation and regression testing.

## Regression Checklist
Run before shipping behavior-affecting changes (chat/streaming/layout/persistence):
- Build passes, and tests pass for risky changes.
- App launches/stops cleanly.
- New chat/send/stream/stop/regenerate flow works.
- Long-chat typing + scrolling has no freeze.
- Sidebar selection is immediate and stable.
- Usage accounting remains non-refundable and accurate.
- Setup guardrails still work (missing API key vs configured key).
- Persistence works after restart (chats/settings/key access).
- Update `/Users/josh/Projects/JChat/Docs/CHANGELOG_INTERNAL.md` for behavior changes.

## Roadmap (Current)
Priority order:
1. Freeze prevention and transcript stability in long chats.
2. V2 UI polish toward a clean ChatGPT-style experience.
3. OpenRouter streaming reliability and consistency.
4. Documentation simplicity and low-friction solo workflow.
5. Feature re-expansion only after stability is locked.

Near-term backlog:
- Improve conversation list density/readability.
- Add stress coverage for streaming/cancellation edge cases.
- Add targeted UI tests for long-chat scroll + send/regenerate.

## History
- Internal changelog: `/Users/josh/Projects/JChat/Docs/CHANGELOG_INTERNAL.md`
