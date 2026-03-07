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

Before writing any SwiftUI, UI layout, or HIG-related code — consult the Apple HIG and SwiftUI links in `Docs/PROJECT_GUIDE.md` (Reference Links section). Before writing any OpenRouter API code — consult `Docs/openapi.json` (local copy) or the OpenRouter API Reference link in PROJECT_GUIDE. Do not guess at API shapes or UI conventions; check the source.

---

## AI Tool Policy

### Always Use
- **xcodebuildmcp** for all Xcode tasks — never raw `xcodebuild`
- **Context7 MCP** for library/API documentation, code generation, setup steps — proactively, without being asked
- **MCP Codriver** (`mcp__codriver__desktop_screenshot`) for UI validation and regression screenshots

### Mode Selection Guide
| Situation | Use |
|-----------|-----|
| Small, low-risk tweak | Direct (just do it) |
| Multiple valid approaches or unclear path | Plan mode first, then execute |
| Behavior, state flow, cost/accounting, or user-facing UX changing | OpenSpec before coding |
| Uncertain scope | Start direct; escalate to Plan or OpenSpec only if scope grows |

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
