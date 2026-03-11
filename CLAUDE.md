# WhisperQuill — Claude Code Context

WhisperQuill is a native SwiftUI chat app for macOS that connects to OpenRouter. Solo hobby project.

## Canonical Docs

| Doc | Contents |
|-----|----------|
| `Docs/PROJECT_GUIDE.md` | Architecture, build environment, xcodebuildmcp defaults, validation, regression checklist, git workflow, reference links |
| `Docs/KNOWN_ISSUES.md` | Resolved issue log (history). Open issues tracked at https://github.com/joshellis625/JChat/issues |
| `Docs/CHANGELOG_INTERNAL.md` | Session-by-session history of changes and decisions |

**Read `Docs/PROJECT_GUIDE.md` first** — it is the single source of truth for how this project is built and run.

---

## Reference Docs Policy

Before writing any SwiftUI, UI layout, or HIG-related code — consult the Apple HIG and SwiftUI links in `Docs/PROJECT_GUIDE.md` (Reference Links section). Before writing any OpenRouter API code — consult the OpenRouter API Reference link in PROJECT_GUIDE. Do not guess at API shapes or UI conventions; check the source.

---

## AI Tool Policy

### Always Use
- **xcodebuildmcp** for all Xcode tasks — never raw `xcodebuild` unless `xcodebuildmcp` is unavailable OR you have confirmed that the Xcode task you need to run is not possible with `xcodebuildmcp`.
- **Context7 MCP** for library/API documentation, code generation, setup steps — proactively, without being asked
- **MCP Codriver** (`mcp__codriver__desktop_screenshot`) for UI validation and regression screenshots - Try to take screenshots via xcode tools using either `xcodebuildmcp` or `xcodebuild`, whichever has the most native and effective tool. Ideally, you want to use the Xcode Framework, "XCUIAutomation".

### Mode Selection Guide
| Situation | Use |
|-----------|-----|
| Small, low-risk tweak | Provide a very brief understanding and what you will do and use Direct mode (ask first for confirmation, then do it) |
| Multiple valid approaches or unclear path | Plan mode first, then execute |
| Behavior, state flow, cost/accounting, or user-facing UX changing | Plan mode before coding |
| Uncertain scope | Determine if Plan mode is safer for the task, ask questions and clarify as needed, otherwise start Direct mode and escalate to Plan only if scope grows, scatters, or the user seems unsure or confused.   |

---

## Multi-Agent File Boundaries

Each AI tool has its own config directory. Do not cross-pollinate:

| Directory | Owner |
|-----------|-------|
| `.claude/` | Claude Code config only |
| `.codex/` | Codex config only |
| `.gemini/` | Gemini config only |
| `Docs/` | Shared human-readable project docs (universal) |

**Rules:**
- One canonical policy per topic; reference it, don't copy it
- If two docs conflict, update the canonical source first, then update references

---

## End-of-Session Changelog Policy

At the end of every session that involves code or doc changes, update `Docs/CHANGELOG_INTERNAL.md` automatically using Keep a Changelog format:

```markdown
## [YYYY-MM-DD] - Session Title

### Added
### Changed
### Fixed
### Removed
### Notes
```

Omit empty sections. Keep entries short and scannable.
