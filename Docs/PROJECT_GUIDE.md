# JChat Project Guide (Canonical)

This is the single source of truth for architecture, workflow, validation, and active direction.

## Product Overview
JChat is a native SwiftUI chat app that uses OpenRouter.

Current direction:
- V2 conversation UI is the default experience.
- Stability and responsiveness are prioritized over feature breadth.
- macOS (`arm64`) is the primary daily target.

## UI Standards
- Source of truth: [Apple SwiftUI Documentation](https://developer.apple.com/documentation/swiftui) and current Apple HIG behavior.
- Prefer native SwiftUI controls, Liquid Glass/material surfaces, and SF Symbols.

## Runtime Architecture (V2)
- UI shell: `NavigationSplitView` with `V2SidebarView` + `V2ConversationPane`.
- State owner: `ConversationStore`.
- Persistence: `ChatRepositoryProtocol` + `SwiftDataChatRepository`.
- Engine: `ChatEngineProtocol` + `OpenRouterChatEngine`.
- Networking: `OpenRouterService` unified on `ModelCallRequest` (send + stream).

Primary files:
- `/Users/josh/Projects/JChat/JChat/Views/ContentView.swift`
- `/Users/josh/Projects/JChat/JChat/V2/UI/V2ShellViews.swift`
- `/Users/josh/Projects/JChat/JChat/V2/Design/V2Design.swift`
- `/Users/josh/Projects/JChat/JChat/Core/Conversation/ConversationStore.swift`
- `/Users/josh/Projects/JChat/JChat/Core/Conversation/ChatEngine.swift`
- `/Users/josh/Projects/JChat/JChat/Core/Conversation/ChatRepository.swift`
- `/Users/josh/Projects/JChat/JChat/Services/OpenRouterService.swift`
- `/Users/josh/Projects/JChat/JChat/Chat.swift`

## Behavioral Rules
- Parameter precedence: chat override -> global settings fallback.
- Character stores identity/system prompt/preferred model only.
- API key is Keychain-only (`com.josh.jchat` / `openrouter-api-key`).
- Message delete/regenerate does not refund usage totals.
- Markdown rendering is intentionally disabled in current stability mode (plain text transcript rows).

## XcodeBuildMCP Defaults (Set Once)
Use `xcodebuildmcp` for all Xcode tasks in this repo. Do not use raw `xcodebuild`.

Canonical defaults schema:
```json
{
  "projectPath": "/Users/josh/Projects/JChat/JChat.xcodeproj",
  "configuration": "Debug",
  "arch": "arm64",
  "platform": "macOS"
}
```

Suggested one-time setup:
```text
session-set-defaults {
  "projectPath": "/Users/josh/Projects/JChat/JChat.xcodeproj",
  "configuration": "Debug",
  "arch": "arm64",
  "platform": "macOS"
}
session-set-defaults { "scheme": "JChat" }
```

Hint: Save a default with `session-set-defaults { projectPath: '...' }` or `{ workspacePath: '...' }`.
JChat hint: Consider saving a default scheme with `session-set-defaults { scheme: "JChat" }` to avoid repeating it.

Notes:
- If you open a workspace, use `workspacePath` instead of `projectPath`.
- Do not re-set these defaults every new chat thread.

## Validation Commands
Fast default:
```bash
xcodebuildmcp macos clean --platform macOS --output text
xcodebuildmcp macos build --output text
```

Launch/stop sanity check:
```bash
xcodebuildmcp macos clean --platform macOS --output text
xcodebuildmcp macos build-and-run --output text
xcodebuildmcp macos stop --app-name JChat --output text
```

Full suite checkpoint:
```bash
xcodebuildmcp macos test --output text
```

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

## Workflow Rules
- Code changes: `codex/<topic>` branch.
- Docs-only changes: direct to `main` allowed.
- Push only with explicit approval.
- No PR flow and no CI gate for this solo workflow.

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
