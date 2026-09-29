# PRD — MyNotch: Notch Utility App for macOS

Sep 29, 2026 · @ryan

## Overview

**MyNotch** is a macOS menu-bar app that turns the MacBook notch into an interactive panel: live activities, widgets, a file tray, a drop area, a watching Eye, and a Tamagotchi-style pet. Feature parity with NotchNook, with one non-negotiable rule: **idle must cost almost zero CPU and very little RAM**, so it never drains the battery the way NotchNook did for some users.

Background: NotchNook shut down, and the "lifetime" license bought for about IDR 1M (about $99) became useless. MyNotch is built for personal use on a MacBook Pro M3 Pro first, with the option to release publicly later.

Product principles:

- **Idle is cheap.** When the notch is closed and nothing is happening, no timers, polling, or animations run.
- **Event-driven, not polling.** All data (media, battery, Bluetooth, calendar) arrives through system notifications.
- **Lazy everything.** Widgets, the camera, and heavy views are created when the notch opens and released when it closes.
- **No rug-pull.** The app keeps working fully even if development stops: no required server, any license is verified offline, user data stays local in open formats.
- **Own name and assets.** Features may be similar, but the name, icon, and visuals never copy NotchNook.
- **English everywhere.** All UI text, code, identifiers, comments, and docs are in English.

## Goals, non-goals, and metrics

Main target: NotchNook-level features with an energy footprint that stays in the "Low" category in Activity Monitor all day.

**Goals**

- Replicate every NotchNook setting (see Settings schema), plus Eye and Pet.
- Idle Energy Impact near 0 and idle RAM under 40 MB.
- Opening and closing the notch feels instant and smooth (60–120 fps on ProMotion).

**Non-goals (v1)**

- Quick Apps (still "coming soon" even in NotchNook).
- Media sources other than Spotify (YouTube in the browser comes after v1).
- Custom Drop Area pipelines, iCloud sync, third-party plugins, Intel Mac support.
- Paid licensing (deferred until a public release is decided).

**Success metrics** (measured on M3 Pro, Release build)

| Condition | CPU | RAM (footprint) | Energy Impact | Wakeups/sec |
| --- | --- | --- | --- | --- |
| Idle, notch closed | < 0.1% | < 40 MB | \~0 | < 1 |
| Media live activity active (visualizer running) | < 2% | < 60 MB | Low | < 60 while visible |
| Notch open, 3 widgets | < 5% while animating, < 1% static | < 90 MB | Low | — |
| Mirror (camera) active | < 8% | < 120 MB | Moderate, only while open | — |
| Eye on, mouse moving | < 1% | < 45 MB | Low | — |
| 5 seconds after closing the notch | back to idle numbers | drops to < 50 MB | \~0 | < 1 |

The last row matters most: memory and CPU must actually **come back down** after use, never pile up.

## Tech stack & architecture

MyNotch is fully native: Swift 5.10+, SwiftUI for content, AppKit for the notch window. Xcode template: **macOS → App**, target macOS 26, `LSUIElement = YES` (no Dock icon). The app uses an AppKit entry point; the SwiftUI `Settings` scene is hosted via `NSHostingSceneRepresentation` (macOS 26) so it can be opened from the notch.

| Layer | Choice | Why |
| --- | --- | --- |
| Notch window | Borderless `NSPanel`, `.nonactivatingPanel`, level `.statusBar + 1`, `collectionBehavior` canJoinAllSpaces + fullScreenAuxiliary | Sits above the menu bar without stealing focus from other apps |
| UI | SwiftUI inside `NSHostingView` | Fast to build, similar to Vue's component model |
| Heavy animation | Core Animation (`CALayer`) | GPU-rendered, never triggers SwiftUI re-renders |
| State | `@Observable` (Observation framework) | Granular updates, cheaper than `ObservableObject` |
| Persistence | `UserDefaults` + JSON in Application Support | No database; data is small |
| Launch at login | `SMAppService.mainApp` | Official API since macOS 13 |
| Updates | Sparkle 2 (the only dependency) | Standard for apps outside the App Store |

&#91;embedded content: MyNotch architecture · system events → services → coordinator → one window\]

Every event flows one way into `ActivityCoordinator`, which decides whether the notch is closed, shows a live activity, or is open; only one panel is ever created.

Suggested Xcode folder structure:

- `App/`: `MyNotchApp.swift`, `AppDelegate.swift`
- `Notch/`: `NotchPanel`, `NotchWindowController`, `NotchGeometry` (notch size detection)
- `Coordinator/`: `ActivityCoordinator`, live activity priority queue
- `Services/`: `MediaService`, `PowerService`, `BluetoothService`, `CalendarService`, `TrayStore`
- `Features/`: `LiveActivities/`, `Nook/Widgets/`, `Tray/`, `DropArea/`, `Gestures/`, `Eye/`, `Pet/`
- `Settings/`: `SettingsStore` + one view per tab

## Coding standards

All MyNotch code follows **Clean Code** (Robert C. Martin), adapted to Swift, plus **anti AI slop** rules, since part of the code is generated with AI help. Code that breaks these rules is not merged, whoever wrote it.

### Clean Code principles

| Principle | Concrete rule in MyNotch |
| --- | --- |
| Meaningful names | Names reveal intent: `inactivityTimeout`, not `t` or `value`. No abbreviations except common ones (URL, ID). Types are nouns, functions are verbs. |
| Functions: small, do one thing | One responsibility and one level of abstraction per function. Ideally < 20 lines, hard limit 40. |
| Few arguments | Max 3 parameters; more than that becomes a configuration struct. No flag arguments (a `Bool` that changes behavior): split into two functions. |
| No side effects / CQS | Functions that return a value don't change state; functions that change state don't return data. |
| Single Responsibility | One type, one reason to change. `MediaService` knows about media only, never the UI. |
| Dependency Inversion | Services talk to the system (IOKit, EventKit, AVFoundation) through protocols, so the coordinator and views are testable without hardware. |
| Boundaries | System APIs and private APIs are wrapped in one place. No `import IOKit` outside `Services/`. |
| Error handling | Use `throws` with specific error types, not ambiguous `nil` or error codes. No empty `catch`. |
| Comments | Code explains itself. Comments only explain *why* (decisions, OS constraints, performance reasons), never *what*. |
| DRY | Never write the same logic twice, but don't abstract before duplication actually exists. |
| Law of Demeter | No long chains like `a.b.c.d`; ask for what you need through one interface. |
| Tests (F.I.R.S.T.) | Pure logic (coordinator, Pet stat decay, notch geometry, parsers) must have fast, deterministic unit tests. |
| Boy Scout Rule | Leave every touched file a little cleaner than you found it. |

### Anti AI slop

These patterns are banned, because they are typical of unreviewed AI-generated code:

- **Comments that restate the code** (`// increment counter`), decorative comment banners, or emoji in comments and logs.
- **Made-up APIs.** Every Apple API used must be verified in the official docs for the target macOS version. No methods that "probably exist".
- **Speculative abstraction:** protocols with a single implementation and no testing need, factories, generics, or layers "for flexibility later" (YAGNI).
- **Generic names:** `Manager`, `Helper`, `Utils`, `Handler`, `Data`, `Info` as type names.
- **Over-defensive error handling:** `try?` that swallows errors, `do/catch` around code that cannot fail, guards for impossible conditions.
- **Dead code and leftovers:** unused functions, commented-out code, debug `print()`, TODOs without an issue.
- **Force unwraps and force casts** (`!`, `as!`), except for bundle resources guaranteed to exist, with a comment saying why.
- **Giant files:** a SwiftUI view with hundreds of lines; split it into small, clearly named subviews.
- **Out-of-scope changes:** AI must not tidy up or rename code it wasn't asked to touch in the same change.
- **Features or options not in this PRD**, unless discussed first.
- **New timers, polling, or animations** without stating when they stop (see Performance & power budget).

### Automated guardrails

Rules are enforced by tools, not memory. SwiftLint and SwiftFormat run as a build phase and a pre-commit hook.

| SwiftLint rule | Warning | Error |
| --- | --- | --- |
| `function_body_length` (lines) | 20 | 40 |
| `function_parameter_count` | 3 | 5 |
| `type_body_length` (lines) | 150 | 250 |
| `file_length` (lines) | 250 | 400 |
| `cyclomatic_complexity` | 8 | 12 |
| `line_length` (characters) | 120 | 160 |
| `force_unwrapping`, `force_cast`, `force_try` | — | on |
| `todo` | on | — |

### Rules for the AI assistant

Everything in this section is copied into an instruction file at the repo root (e.g. `AGENTS.md` or `CLAUDE.md`), so every AI session reads it before writing code. AI-specific additions:

- One small task per session; never generate a whole module at once.
- Before writing code, list the files that will change and why.
- If unsure whether an API exists or how it behaves, say so; don't guess.
- Every change ships with unit tests for pure logic.

Review checklist for every change:

- [ ] Passes SwiftLint with no new warnings
- [ ] Type and function names explain intent without comments
- [ ] None of the anti AI slop patterns above
- [ ] Every new timer, listener, or animation has a clear stop point
- [ ] Idle CPU and RAM recorded before/after (when touching UI or services)

## Features by module

The first seven modules mirror NotchNook's Settings tabs; Eye and Pet are MyNotch's own additions. Each module lists its core behavior and its power notes.

### 1. Notch shell (General)

- Transparent borderless window over the notch, above the menu bar, hidden from the Dock and Cmd-Tab.
- Three states: **closed** (blends with the physical notch), **live activity** (widens left and right), **open** (full panel with widgets).
- Opens by click, hover (optional "Always open on hover"), or a downward swipe gesture.
- Notch size auto-detected from `NSScreen.safeAreaInsets` + `auxiliaryTopLeftArea/RightArea`, with manual width/height fine-tuning.
- Screens without a notch: a small "handler" pill at the top center (adjustable width/height, optional transparent and hover-only).
- Fullscreen: show on notched screens only / all screens / never.
- Options: capsule vs rounded-rect buttons, translucent background (experimental), content padding, haptics on/off, demo mode, launch at login, reset settings, quit.
- Typing: don't close on mouse leave while typing; optional lock while typing.

### 2. Gestures

- Hovering the notch enables trackpad gestures.
- Vertical swipe: open/close the notch.
- Horizontal swipe: next/previous track, with an invert option.
- Power note: the scroll event monitor is **only installed while the cursor is over the notch**, and removed when it leaves.

### 3. Live Activities

Small notifications that widen the notch when something happens.

- **Media**: album artwork + visualizer (Audio Spectrograph, Waves, Vibrating Circle, GIF), effect color from the artwork, artwork corner radius. Source: Spotify (v1).
- **Files Tray**: shown while the tray holds files.
- **Calendar**: upcoming events.
- **New Update**: an app update is available.
- **Bluetooth**: device connect/disconnect (e.g. AirPods and their battery).
- **Battery**: charger plugged/unplugged, low battery.
- **Timer Ended**.
- General settings: inactivity timeout (seconds), interactive (click), Quick Peek on hover, auto-unhide after being swiped away, show song change, hide on non-notched screens, and which activities stay visible while another app is fullscreen.
- Power note: the visualizer is **not** real audio analysis (that needs audio capture permission and lots of CPU). It is a procedural animation that stops completely when playback pauses or the notch is not visible.

### 4. Nook (widget panel)

- Enable nook (when off, clicking the notch does nothing) and dividers between widgets.
- Grid layout based on **cells**; each widget has a default, adjustable width, a live preview in Settings, and drag-to-reorder.
- v1 widgets: **Calendar** (5 cells; choose calendars, days behind/ahead, past/all-day/multi-day events), **Media Player** (5), **Shortcuts** (4; runs Apple Shortcuts), **Mirror** (2; front camera), **Notes** (5; lightweight text notes, local only), **To-dos** (4; local only), **Timer**.
- Power note: widgets are only instantiated while the nook is open. Mirror opens the camera when visible and **closes the camera session immediately** when the notch closes.

### 5. Tray

- Temporary file shelf: drag a file onto the notch, it's kept, then drag it out to another app or into any Finder folder.
- Setting: tray width.
- Store **references** (security-scoped bookmarks), never file data in memory. Thumbnails are generated lazily via QuickLook, small, and cached to disk.

### 6. Drop Area

- When the user starts dragging a file toward the notch, a drop zone appears with **two fixed targets: AirDrop and Tray**.
- No "Customize pipelines" in v1. Moving files to a folder is done by dragging from the Tray into Finder.
- Setting: drop area width.
- Global drag detection is only active for the duration of a drag session.

### 7. License & About

- v1: About (version, credits, update check). No license while the app is personal; if it's ever released, any license must be **verifiable offline** so the app keeps working even if the server dies (the NotchNook lesson).

### 8. Eye

A pair of eyes on the notch whose pupils follow the cursor, so the notch feels like it's "watching". **Off by default**, enabled in Settings.

- Notch closed: the eyes sit on the left and right wings of the notch. Notch open: the eyes stay alive in the panel header.
- Pupils follow the cursor anywhere on screen, with random blinking.
- Small reactions: glance at a file being dragged toward the notch, droopy eyelids when the cursor has been still for a while, eyes closed when the screen is locked.
- Conflict with live activities: the live activity wins; the eyes hide temporarily and return after the inactivity timeout.
- Settings: `eye.enabled` (false), `eye.showWhenClosed` (true), `eye.showWhenOpen` (true), `eye.blink` (true), `eye.sleepWhenIdle` (true).

Power notes (the riskiest feature for battery, because it tracks the mouse):

- Tracking uses `NSEvent.addGlobalMonitorForEvents(.mouseMoved)` **only** while Eye is on and visible. The monitor is removed when Eye is off, a fullscreen app covers the notch, the screen is locked, or the Mac sleeps. Mouse movement does not require Accessibility permission.
- Event-driven: a still mouse means zero work. Pupil updates are throttled to max 30 Hz.
- Pupils move by changing a `CALayer` position (implicit animations disabled), with no SwiftUI re-render.
- Blinking: one randomized timer with a large `tolerance`, stopped whenever the eyes aren't visible.

### 9. Pet

A **Tamagotchi-style** pet that lives in the notch, with stats that persist across sessions and change over time.

- Pet types: **Cat**, **Dog**, and **Blob** (an original Tamagotchi-style creature, not a copy of Bandai's characters). The user picks one on first enable and can switch later.
- Stats: **Hunger**, **Happiness**, **Energy**, plus an age/level that grows with regular care.
- Actions from the nook panel: feed, play (a short click mini-game), pet, put to sleep.
- Reacts to events the coordinator already has: dances while music plays (raises Happiness), sleeps when the Mac sleeps, startles when a file is dropped.
- Display: the pet idles on the notch wing when closed; the full status card appears when the notch is open.
- Power note: stats are **never ticked by a timer**. Store the last timestamps (fed, played, slept) and compute stat values on demand (lazy decay). For a "pet is hungry" notification, schedule a single timer to the next threshold time.
- Sprite-sheet animation via `CALayer.contents` at max 12 fps; when idle the pet holds a static frame. Sprites load when Pet is enabled and are released when disabled.
- Pet data is stored locally as JSON in Application Support. All pet art is original.

Pet decisions:

- [x] Model: **Tamagotchi-style** with persistent stats.
- [x] Types: **Cat, Dog, Blob**, chosen by the user.
- [x] Neglect: the pet **never dies**. Stats bottom out at zero and the pet looks sad; after a long stretch at zero it **runs away temporarily** (the wing shows an empty spot), and comes back when the user opens the notch and calls it back with food.
- [x] Roaming: the pet **stays in the notch** (closed-state wing and open panel only), never on the menu bar.
- [x] Eye + Pet: **both can be on together**. Layout: both eyes move to the left wing, the pet takes the right wing. The eyes occasionally glance at the pet.

## Performance & power budget

Battery drain in notch apps almost always has the same causes: timers or polling that never stop, SwiftUI animations that keep running, global event monitors, and heavy views that are never released. The rules below are mandatory, not suggestions.

### Energy rules

1. **Zero timers while idle.** No `Timer`, `DispatchSourceTimer`, or `TimelineView` runs while the notch is closed and no live activity is shown. Every timer has a clear owner and is invalidated when state changes.
2. **Event-driven for every data source:**
   - Spotify media: `DistributedNotificationCenter` (`com.spotify.client.PlaybackStateChanged`). Artwork and details are fetched once per track change, not every second.
   - Battery: `IOPSNotificationCreateRunLoopSource`.
   - Bluetooth: `IOBluetoothDevice.register(forConnectNotifications:)`.
   - Calendar: `EKEventStoreChanged` + one timer scheduled to the next event only (no periodic polling).
   - Mouse over the notch: `NSTrackingArea` on the notch window, **not** a global `.mouseMoved` monitor (the only exception is Eye, while enabled and visible).
3. **Animations stop when not visible.** The visualizer, Eye, Pet, and progress bars only run while the window is visible, not covered by a fullscreen app, and (for media) while playing. Watch `NSWindow.occlusionState` and `NSWorkspace` sleep/screen-lock to shut everything down.
4. **Just enough frame rate.** Visualizer max 30 fps, Eye max 30 Hz, Pet max 12 fps; notch open/close may use full 120 fps because it is brief.
5. **Prefer Core Animation.** Visualizer, Eye, Pet, and other moving effects use `CALayer`/`CAReplicatorLayer` rendered on the GPU, not SwiftUI views re-rendering every frame.
6. **Tolerant timers.** Timers that are truly needed (inactivity timeout, Timer widget, Eye blink, Pet threshold) set `tolerance` ≥ 10% so the system can coalesce wakeups.
7. **No AppleScript polling** of Spotify. AppleScript is only called on demand (play/next clicks) because it wakes the target app.
8. **Background QoS.** Non-UI work (thumbnails, calendar parsing) runs at `.utility`/`.background`.

### Memory rules

1. **Lazy view tree.** Nook content is built on open and released (views removed from the hierarchy) a few seconds after close.
2. **Mirror camera** uses a low-resolution preset (`.low`/640×480), and calls `AVCaptureSession.stopRunning()` + releases it when the notch closes. Never leave a camera session alive in the background.
3. **Downsample images.** Artwork is kept at max 2× its display size (e.g. 128 px) via `CGImageSourceCreateThumbnailAtIndex`. Artwork cache holds one track at most.
4. **Tray stores bookmarks, not file data.** Small QuickLook thumbnails, disk cache, `NSCache` with count and cost limits.
5. **No WebView.** The whole UI is native (SwiftUI + AppKit). A WebView alone can add 50–100 MB.
6. **One window, reused.** Never create a new `NSPanel` every time the notch opens.
7. **Watch for retain cycles** in Combine/async closures: use `[weak self]`, cancel `AnyCancellable` when a module is turned off.
8. **Disabled modules are truly dead:** no listeners installed, no objects created.

### How to measure (part of the Definition of Done)

- Activity Monitor → Energy tab (Energy Impact, "Preventing Sleep" must be No) and Memory tab.
- Instruments: **Energy Log**, **Time Profiler**, **Allocations + Leaks**, **Animation Hitches**.
- `sudo powermetrics --samplers tasks --show-process-energy -i 5000` for wakeups per second.
- `footprint <pid>` or `vmmap --summary` for the real memory footprint.
- 8-hour soak test during a normal workday: memory must not keep climbing (a sign of a leak).
- Every change touching animations, listeners, or widgets records idle numbers before/after.

## Settings schema

Every option below comes from the NotchNook configuration in the screenshots, plus Eye and Pet; the Default column uses the values currently in use. Stored via `@AppStorage`/`UserDefaults`, except widget and pet data (notes, to-dos, tray, pet state), which is stored as JSON in Application Support.

| Tab | Key | Type | Default |
| --- | --- | --- | --- |
| General | launchAtLogin | Bool (SMAppService) | true |
| General | showInFullscreen | enum: notchedScreens / all / never | notchedScreens |
| General | mediaSource | enum: spotify (v1 only) | spotify |
| General | preferRoundButtons | Bool | true |
| General | translucentBackground | Bool (experimental) | false |
| General | alwaysOpenOnHover | Bool | false |
| General | disableHaptics | Bool | true |
| General | preventCloseWhileTyping | Bool | false |
| General | lockWhileTyping | Bool (enabled only if the above is true) | false |
| General | contentPadding | Int (slider) | 12 |
| General | notchFineTuneWidth / Height | Int (px offset) | 0 / 0 |
| General | handlerEnabled | Bool (non-notched screens) | false |
| General | handlerWidth / Height | Int | 184 / 8 |
| General | handlerTransparent | Bool | false |
| General | demoMode | Bool | false |
| Gestures | gesturesOnHover | Bool | true |
| Gestures | verticalOpenClose | Bool | true |
| Gestures | horizontalMediaControl | Bool | true |
| Gestures | invertMediaGestures | Bool | false |
| Live Activities | enabled | Bool | true |
| Live Activities | hideOnNonNotched | Bool | false |
| Live Activities | inactivityTimeout | Int seconds | 10 |
| Live Activities | interactive | Bool | true |
| Live Activities | quickPeek | Bool | true |
| Live Activities | unhideAutomatically | Bool | true |
| Live Activities | showSongChange | Bool | false |
| Live Activities | showInFullscreen | Set: media, filesTray, calendar, newUpdate, bluetooth, battery, timerEnded | all |
| Live Activities | activity.enabled (per activity) | Bool | media, filesTray, newUpdate on; rest off |
| Live Activities | media.albumCornerRadius | Int | 5 |
| Live Activities | media.effectType | enum: spectrograph / waves / vibratingCircle / gif | spectrograph |
| Live Activities | media.coloredEffects | Bool | true |
| Nook | enabled | Bool | true |
| Nook | showDividers | Bool | true |
| Nook | widgets | Ordered array {id, enabled, width} | Media Player 5, Mirror 2, Notes 5 enabled |
| Nook | calendar.calendarIDs | Set of String | all calendars |
| Nook | calendar.width | Int cells | 5 |
| Nook | calendar.showPastToday / allDay / multiDay | Bool | false / false / false |
| Nook | calendar.daysBehind / daysAhead | Int | 7 / 7 |
| Tray | width | Int | 11 |
| Drop Area | width | Int | 11 |
| Drop Area | targets | fixed, not editable in v1 | AirDrop, Tray |
| Eye | enabled | Bool | false |
| Eye | showWhenClosed / showWhenOpen | Bool | true / true |
| Eye | blink | Bool | true |
| Eye | sleepWhenIdle | Bool | true |
| Pet | enabled | Bool | false |
| Pet | type | enum: cat / dog / blob | chosen on first enable |
| Pet | hungerNotifications | Bool | true |

The Settings window uses toolbar-style tabs like the screenshots (SwiftUI `Settings` scene + `TabView`), with Eye and Pet as two extra tabs and live previews on the Nook and Live Activities tabs.

## Permissions, privacy, distribution

MyNotch is distributed outside the Mac App Store (Developer ID + notarization), because Spotify control via Apple Events and a window above the menu bar are hard to fit inside the App Store sandbox.

| Permission | Used for | When requested |
| --- | --- | --- |
| Automation (Apple Events) to Spotify | play, pause, next, previous | first time a media button is pressed |
| Calendars (EventKit, full access) | Calendar widget & live activity | when the Calendar widget is enabled |
| Camera | Mirror widget | first time the Mirror widget opens |
| Bluetooth | Bluetooth live activity | when the Bluetooth activity is enabled |
| Notifications | "pet is hungry" alerts | when Pet is first enabled |
| Files (security-scoped bookmarks) | Tray | automatically when a file is dropped |

- Every permission is requested **in context**, never all at once during onboarding.
- No analytics or network calls other than the update check (Sparkle, can be turned off).
- No Accessibility or Screen Recording permission. If a feature seems to need one, the feature is re-evaluated.
- Minimum target: macOS 26, Apple Silicon (raised from 14 to open the Settings scene from a Dock-less app without workarounds).
- Updates: Sparkle 2 with a static appcast (GitHub Releases), so the app keeps working even if an update server goes down.

## Roadmap

&#91;embedded content: roadmap · 5 phases, an energy gate at every transition\]

Phase 0 is intentionally an empty shell: if the shell alone isn't at 0% while idle, every feature built on top will drain the battery too, so idle numbers are locked in before features are added. Eye ships with Phase 1 (it builds on the shell and mouse tracking); Pet ships with Phase 2 (its status card lives in the nook).

## Decisions & risks

**Decisions**

- [x] Release: **personal for now**. No license system; the no rug-pull principle still applies if it's ever released.
- [x] Media source: **Spotify only in v1**. YouTube in the browser comes after v1, because it needs MediaRemote (private API) or a browser extension.
- [x] Notes and To-dos: **local only**, no sync with Frodo yet.
- [x] Drop Area: **AirDrop and Tray only**. Moving to a folder is done by dragging from the Tray into Finder.
- [x] Language: **English** for all UI text, code, and docs.
- [x] Pet types: **Cat, Dog, Blob**.

**Risks**

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Swift/AppKit is new for a frontend developer | Slow progress early on | Start with the shell + one live activity; many SwiftUI concepts map to Vue (state, computed, components) |
| Private APIs (MediaRemote) change with macOS updates | Media breaks after an OS update | v1 only uses Spotify's public notifications |
| Notch size detection is off on some models | Notch doesn't blend in | Manual width/height fine-tune (already in the schema) |
| SwiftUI animations silently keep running | Battery drain, NotchNook's main problem | Energy rules + measure on every change |
| Eye's global mouse tracking | Constant wakeups while the mouse moves | Throttle to 30 Hz, remove the monitor whenever Eye isn't visible |
| Similarity to NotchNook | Legal trouble if released | Own name, icon, and visuals; generic features are not protected |
