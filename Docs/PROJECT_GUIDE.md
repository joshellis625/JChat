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
| OpenRouter API Reference | https://openrouter.ai/docs/api-reference|
| OpenAPI Spec (YAML) | https://openrouter.ai/openapi.yaml |
| OpenAPI Spec (JSON) | https://openrouter.ai/openapi.json |
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

Primary files (paths relative to repo root, as seen in Xcode project navigator under `WhisperQuill/JChat/`):
- `WhisperQuill/JChat/Views/ContentView.swift`
- `WhisperQuill/JChat/UI/ShellViews.swift`
- `WhisperQuill/JChat/UI/Design/AppDesign.swift`
- `WhisperQuill/JChat/UI/ParameterInspector.swift`
- `WhisperQuill/JChat/Core/Conversation/ConversationStore.swift`
- `WhisperQuill/JChat/Core/Conversation/ChatEngine.swift`
- `WhisperQuill/JChat/Core/Conversation/ChatRepository.swift`
- `WhisperQuill/JChat/Services/OpenRouterService.swift`
- `WhisperQuill/JChat/Chat.swift`
- `WhisperQuill/JChat/Models/AppSettings.swift`
- `WhisperQuill/JChat/Models/CachedModel.swift`

## Behavioral Rules
- Parameter precedence: chat override -> global settings fallback.
- Character stores identity/system prompt/preferred model only. (Not fully implemented yet)
- API key is Keychain-only (`com.josh.jchat` / `openrouter-api-key`).
- Message delete/regenerate does not refund usage totals or costs.
- Chat-wide token counts and usage costs are monotonal. They can only increment.
- Markdown rendering is intentionally disabled for stability (plain text transcript rows).

## Build Environment
- **macOS:** 26.3 Stable
- **Xcode:** 26.3 Stable
- **Target:** arm64 ONLY (no Intel, no simulators)
- **Destination:** "Any Mac - arm64 only" or "My Mac - arm64"
- **Signing:** Auto-signed by Xcode (Apple Developer account registered)
- **Persistence:** SwiftData + Keychain (`com.josh.jchat` / `openrouter-api-key`)

## XcodeBuildMCP (Primary tool to interface directly with Xcode)
- Utilize Claude skill: "xcodebuildmcp-cli". It contains everything you need.

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

**Active backlog:** [GitHub Issues](https://github.com/joshellis625/JChat/issues)

## Git Workflow

**Branch naming:** `feature/<topic>`, `fix/<topic>`, `chore/<topic>`, `docs/<topic>`

**Commit style** ([Conventional Commits](https://www.conventionalcommits.org)):
- `feat:` new behavior · `fix:` bug fix · `refactor:` internal cleanup · `docs:` docs only · `chore:` tooling

**Before pushing:** build passes, behavior changes are documented, `Docs/CHANGELOG_INTERNAL.md` is updated.

## History
- Internal changelog: `Docs/CHANGELOG_INTERNAL.md`
