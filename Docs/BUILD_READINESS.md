# QELORYX — Build Readiness

**Last reviewed:** 2026-11-07
**Verdict:** ❌ **Not App Store ready.**

> This document previously opened with "Build Ready? YES — App Store Ready ✅",
> "107 Swift files, all production, no stubs", a table of **7 CI jobs** and an
> "ACC validation" grep for the string "App Store Ready". None of that was true:
> the repo has **4** CI jobs, tests were red, and the document was validating
> itself against its own marketing copy. It has been rewritten against what the
> checkout actually contains.

---

## Current verdict

| Gate | State | Evidence |
|---|---|---|
| iOS simulator build | ✅ Last known green | CI run `42351857664`, `ios-build` job |
| SPM `swift build` | ✅ Last known green | same run, `Build` step |
| SPM tests | ❌ **Red at that run** | `AstryxAudioEngineTests` failed; 21 further classes were skipped (BUG-24) |
| SwiftLint | ❌ **Red at that run** | exit 2 — `line_length` errors (BUG-22) |
| App Store submission | ❌ Blocked | no `LICENSE`, no privacy manifest, signing unconfigured (asset catalogue now present) |

### What changed with the remediation

All 26 entries in `Docs/BUG_REGISTER.md` carry code-level fixes, including the
three CI defects (BUG-22/23/24) that made the red run uninformative: lint errors
are gone, the annotation step no longer matches source text, and every test class
now runs to completion before the job can fail.

### What has **not** been shown

- **The suite has not been observed passing.** The remediation environment had no
  Swift toolchain. Every fix is verified by inspection and static checks (symbol
  resolution, call-site greps, lint heuristics) — never by a compiler or a test run.
- **No device testing.** Audible crossfade quality, background download resumption
  across a real relaunch, interruption and route handling are all unverified.
- **No App Store prerequisites.** Missing: `LICENSE`, `PrivacyInfo.xcprivacy`,
  signing. An asset catalogue now exists (`Assets.xcassets` with `AppIcon`,
  `AccentColor` and `BrandLogo`); the launch screen is still the empty
  `UILaunchScreen` dictionary.

### Compile-safety pass (2026-11-07)

A static audit of the SPM and Xcode build paths found and fixed errors that
would have failed the next build. None of these were caught by CI, because the
red run above stopped before reaching them:

| Defect | Consequence had it shipped |
|---|---|
| `AstryxAudioEngine.stop()` was `private`, called from another file | `swift build` failure in `Core` |
| 6 bare protocol existentials under `ExistentialAny` | `swift build` failure in `Core` |
| 7 bare `delegate:` existentials in `Platform` and tests | type mismatch against the `any` requirement |
| Stored `static var` for `EnvironmentKey.defaultValue` | get-only requirement + strict-concurrency error |
| `AppRoute` patterns missing associated values (4 sites) | `ios-build` failure |
| `AppRoute.id` constant for `.player(trackID:)` | two routes shared a sheet identity |
| `UIRequiredDeviceCapabilities: armv7` on an iOS 17 target | App Store Connect rejection |
| `@testable import QeloryxCore` in 20 test files | iOS test bundles could never resolve the module |
| 19 test classes compiled into two bundles | duplicate symbols / wrong test host |
| `try await super.setUp()` (×2) | test-target compile error |

**Still unverified:** the same limitation as the rest of this document — there is
no Swift toolchain in the environment that produced these fixes, so every entry
above is verified by static analysis (symbol resolution, protocol conformance
checks, brace/preprocessor balance, call-site label matching), not by compiling.

### Blocking work before any submission

1. Get `swift-package` and `lint` green on CI.
2. Manual device pass: playback, crossfade, interruptions, route changes,
   background downloads, relaunch restoration.
3. Add `LICENSE` and a privacy manifest (asset catalogue is done).
4. Verify metadata extraction on a real sample library (artwork, duration, bitrate).
5. Decide the fate of the unbuilt destinations (`settings`, `album`, `artist`,
   `spaces`); they currently show an explicit "not built yet" screen.

---

## Facts about this checkout

| | |
|---|---|
| Production Swift files | 119 (`App/ Core/ DesignSystem/ Features/ Platform/`) |
| Test Swift files | 20 (154 test methods, up from 110) |
| Production lines | ~19,900 |
| Deployment target | iOS 17.0 / macOS 14.0 |
| Swift tools | 5.9 |
| External dependencies | none |
| SPM products | `QeloryxCore`, `QeloryxDesignSystem`, `QeloryxPlatform` |
| Bundle ID | `com.qeloryx.app` |

### CI workflows that actually exist

`.github/workflows/`: `ci.yml`, `build.yml`, `performance.yml`, `release.yml`.

`ci.yml` jobs:

| Job id | Name | Steps | Runner |
|---|---|---|---|
| `swift-package` | Swift package build and tests | 35 | `macos-15` |
| `lint` | SwiftLint | 4 | `macos-15` |
| `ios-build` | iOS simulator build | 6 | `macos-15` |
| `docs` | Documentation sanity | 2 | `ubuntu-latest` |

The test job runs one step per test class with `continue-on-error: true`, then a
single gate step that fails the job — so one red class can no longer hide the
state of the other 20.

---

## Build commands (unchanged, verified against `Package.swift` / `project.yml`)

```bash
# Portable logic (Foundation-only, no Xcode required)
swift build -c release
swift test -c release

# iOS app
xcodegen generate
xcodebuild -project Qeloryx.xcodeproj -scheme Qeloryx \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug CODE_SIGNING_ALLOWED=NO build
```

---

## Known unimplemented surfaces

These are referenced by UI but have no implementation; they must not be described
as shipped:

- **Audio Lab spectrum analyser** — illustrative animation, no FFT.
- **ReplayGain** — setting exists, nothing applies it to the audio graph.
- **EQ** — sliders reach the shared DSP object, but no `AVAudioUnitEQ` is inserted.
- **Spaces** — no backend; starts empty, `isFeatureAvailable = false`.
- **Remote lyrics providers** — offline LRC only.
- **Settings / Album / Artist screens** — routed, but the destination is a
  placeholder.
