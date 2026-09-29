# MyNotch — instructions for AI sessions

Read `MyNotch/MyNotch.md` (the PRD) before writing code. It is the source of truth for scope, settings, and the power budget.

## Non-negotiables

- **Idle is cheap.** No timers, polling, or animations while the notch is closed and nothing is happening.
- **Event-driven, not polling.** Data arrives through system notifications.
- **Lazy everything.** Heavy views, widgets, and the camera exist only while visible.
- **English everywhere.** UI text, code, identifiers, comments, docs.

## Clean Code (Swift)

- Names reveal intent; types are nouns, functions are verbs. No abbreviations except URL, ID.
- Functions do one thing: ideally < 20 lines, hard limit 40. Max 3 parameters; no `Bool` flag arguments.
- Command/query separation: a function either returns a value or changes state, not both.
- One type, one reason to change. Services never know about the UI.
- System and private APIs are wrapped behind protocols in `Services/`. No `import IOKit` outside `Services/`.
- `throws` with specific error types. No empty `catch`, no `try?` that swallows errors.
- Comments explain *why* (decisions, OS constraints, performance), never *what*.
- Pure logic (coordinator, Pet decay, notch geometry, parsers) has fast, deterministic Swift Testing tests.
- Boy Scout Rule: leave every touched file a little cleaner.

## Anti AI slop (banned)

- Comments that restate code, decorative banners, emoji in comments or logs.
- Made-up APIs. Verify every Apple API in the docs for the deployment target.
- Speculative abstraction: single-implementation protocols with no testing need, factories, "flexibility later" layers.
- Generic type names: `Manager`, `Helper`, `Utils`, `Handler`, `Data`, `Info`.
- Over-defensive error handling and guards for impossible conditions.
- Dead code, commented-out code, debug `print()`, TODOs without an issue.
- Force unwraps / force casts, except guaranteed bundle resources (with a comment saying why).
- Giant files; split SwiftUI views into small named subviews.
- Out-of-scope changes and features not in the PRD.
- New timers, listeners, or animations without a stated stop point.

## Working rules

- One small task per session; never generate a whole module at once.
- Before writing code, list the files that will change and why.
- If unsure whether an API exists or how it behaves, say so; don't guess.
- Every change ships with unit tests for pure logic.

## Review checklist

- [ ] Passes SwiftLint with no new warnings
- [ ] Names explain intent without comments
- [ ] None of the anti AI slop patterns
- [ ] Every new timer, listener, or animation has a clear stop point
- [ ] Idle CPU and RAM recorded before/after (when touching UI or services)
