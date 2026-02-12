# Contributing to JChat

This project is a solo hobby app, but we use professional workflow standards so the codebase stays maintainable over time.

## Branching Rules
- `main` is stable.
- Code changes start on a feature branch: `codex/<short-topic>`.
- Documentation-only changes are made directly on `main`.
- Do not push any branch or `main` without explicit approval.

## Commit Style
Use clear conventional commit prefixes:
- `feat:` new behavior
- `fix:` bug fix
- `refactor:` internal cleanup with no behavior change
- `docs:` documentation changes
- `chore:` project/tooling maintenance

## Definition of Done
Before pushing:
1. Local macOS build passes (`xcodebuildmcp macos build`).
2. Run full local tests (`xcodebuildmcp macos test`) for risky behavior changes (conversation flow, streaming, persistence, networking, usage accounting) and before final push checkpoints.
3. UI changes include a manual UX check.
4. Any changed behavior is documented.
5. Risks and follow-up work are recorded in notes/changelog.

## UI Design Standards
- Source of truth: [Apple SwiftUI Documentation](https://developer.apple.com/documentation/swiftui) and current Apple HIG direction.
- Prefer native SwiftUI components, Liquid Glass/material surfaces, and SF Symbols.

## V2 Stability Gate
When changes touch transcript rendering, streaming, or input behavior:
1. Validate long-chat scrolling (including while typing).
2. Validate streaming auto-scroll and stop/regenerate flows.
3. Use the consolidated regression checklist in `/Users/josh/Projects/JChat/Docs/PROJECT_GUIDE.md` before push.

## Recommended Solo Workflow
1. For code changes, create branch: `git checkout -b codex/<topic>`. For docs-only changes, work on `main`.
2. Implement one scoped change or small related group of changes.
3. Run local checks.
4. Commit freely with clear messages.
5. Request explicit approval before any push.
6. Push only after approval, then merge locally when ready.
7. After merge, delete the merged feature branch locally and on origin.

Branch cleanup commands:
```bash
git branch -d codex/<topic>
git push origin --delete codex/<topic>
```

## Codex + OpenSpec Usage
This app is a hobby project, so speed matters. Use this simple rule:

- `Direct Codex` (just ask "do that thing"): default for small, low-risk tweaks.
- `Codex Plan mode`: use when you need options/tradeoffs before coding.
- `OpenSpec`: use when behavior, cost/accounting, state flow, or user-facing UX logic is changing.

Quick decision guide:
1. Tiny tweak (about 5-10 minutes, low risk): use `Direct Codex`.
2. Unclear approach or multiple good options: use `Codex Plan mode` first, then execute.
3. Anything you might need to explain/reverse later: use `OpenSpec`.
4. If uncertain, start direct; upgrade to Plan mode or OpenSpec only if scope grows.

Keep OpenSpec lightweight when used:
- Prefer `/opsx:ff <name>` for fast artifact setup.
- Keep proposal/design/tasks short and practical.
- Batch a few related small tweaks into one change to reduce overhead.

Source-of-truth boundary:
- `Docs/`: product/user documentation.
- `openspec/`: planning artifacts and decision history.

## Multi-Agent File Hygiene
You may use multiple AI tools (Codex, Claude Code, etc.). Keep a clean boundary:

- `.codex/`: Codex-specific config, prompts, and skills.
- `.claude/`: Claude-specific config/prompts.
- `.gemini/` (or others): tool-specific config only.
- `Docs/`: shared human-readable project docs.
- `openspec/`: shared change artifacts and decision history.

Rules to prevent mess:
1. Do not duplicate full policy text across tool folders.
2. Keep one canonical policy in `CONTRIBUTING.md`, and reference it from tool-specific files.
3. If two docs conflict, update canonical first, then update references.
4. Prefer small links and short summaries over copy-paste blocks.

## CI/CD Scope for Now
- CI is disabled by choice for this solo workflow.
- Local validation is the quality gate.
- No PR flow is used.

## Preferred Validation Commands (macOS / XcodeBuildMCP)
Canonical commands and defaults:
- `/Users/josh/Projects/JChat/Docs/PROJECT_GUIDE.md`

Policy notes:
- Prefer macOS XcodeBuildMCP workflows in this repo.
- Use `xcodebuildmcp` for all Xcode tasks in this repo; do not use raw `xcodebuild`.
- Avoid simulator-target validation in the default iteration loop.
- If a client does not expose wrapper tools, run `xcodebuildmcp ...` directly in terminal.
- Do not keep re-setting project/scheme defaults on every new thread once they are configured.
