# QELORYX — MASTER AUDIT (Phase 0)

**Audit date:** 2026-11-07
**Branch audited:** `arena/45fda02b-qeloryx`
**HEAD:** `2719e61239f4e5b2d3f3c1f6302e842508045c0a` — *"feat: player features, UI wiring, and repo structure cleanup"*
**Working tree:** clean (0 modified / 0 deleted / 0 untracked)
**Upstream state:** `origin/main` is **1 commit ahead** of this branch (`7ec6b0a` — CI workflow change). This branch is behind `main`.

> **Method.** Every claim below is derived from source inspection of this exact checkout, from `git`, or from the GitHub Actions API. Where something could **not** be verified, it is marked **UNVERIFIED** with the reason. No feature is reported as working without a named file and line.
>
> **Environment limitation (important).** This sandbox is Linux with **no Swift toolchain, no Xcode, no SwiftLint** (`swift`, `xcodebuild`, `swiftlint` are all absent). CI logs and artifacts live on `*.blob.core.windows.net`, which is outside the sandbox egress allowlist, so **the CI logs could not be downloaded**. CI conclusions and step-level results below come from the GitHub Actions API (which is reachable); the underlying log text is **UNVERIFIED**.

---

## 1. Executive summary

Qeloryx is a **well-structured skeleton with several genuinely good subsystems, wired together by a composition root that negates most of them.**

The engineering spine is real and better than typical at this stage: a protocol-first module layout, a typed event bus, an isolated `Platform` layer that keeps AVFoundation out of `Core`, a clean-room dual-deck crossfade adapter with actual unit tests, an LRC/lyric model with word-level timing, a smart-playlist rule model, and 110 unit tests. The `Package.swift` / `project.yml` split (SPM for portable logic, XcodeGen for the app) is a sound, maintainable choice.

But the product currently **cannot be used as a music player end-to-end**, and the documents describing it are not accurate. The five defects that matter most:

1. **The production library is in-memory only.** The app constructs `AstryxLibraryEngine(eventBus:)` with no storage argument, so it gets the default `InMemorySwiftDataStack()` (`Core/LibraryEngine/LibraryEngine.swift:88`). On iOS the "real" `SwiftDataAdapter` exists but **is never instantiated**; on non-SwiftData platforms it is `typealias`-ed back to the in-memory store (`Platform/Persistence/SwiftDataAdapter.swift:455`). A real one exists (`Platform/Persistence/SwiftDataAdapter.swift:168`) but nothing constructs it. **Every import, favorite, play count and playlist is lost on relaunch.**
2. **The audio path is partly simulated.** When the library does not resolve a track, the engine loads `URL(fileURLWithPath: "/tmp/\(trackID).mp3")` (`Core/AstryxAudioEngine/AstryxAudioEngine.swift:172`, `:312`) — a path that never exists on iOS. When the adapter is not really playing, the position clock **fabricates time** (`playbackState.position + 0.5`, `:369`). So "playing" can be a clock advancing over silence while the UI reports progress.
3. **DSP, EQ and ReplayGain never reach the audio path.** `AstryxDSPEngine` is created in the composition root (`App/QeloryxApp.swift:52`), stored in a property, and then **never injected into the audio engine or the adapter**. `AudioLabView` mutates EQ state on its *own* second DSP instance. The EQ sliders move; the audio does not change.
4. **Two advertised features are hard-wired off.** Crossfade is only applied via the `.setCrossfade` command, whose only callers are comments and local view state — **no production code ever sends it**, so the dual-deck adapter always runs with `CrossfadeConfiguration.disabled`. Shuffle is stored on the queue but **`next()` ignores it entirely** (`Core/AstryxAudioEngine/Queue/QueueController.swift:118-141` iterates `currentIdx + 1`).5. **There is no network layer at all.** No `URLSession`, `URLRequest` or HTTP URL exists anywhere in `Core/`, `Features/`, or `DesignSystem/` — the only networking in the repo is the download file transfer. Every "provider" is therefore local-only: no MusicBrainz, no Cover Art Archive, **no LRCLIB** (so `AstryxLyricsEngine` cannot fetch synced lyrics), no Navidrome/Jellyfin, no Spotify/Apple Music. There is also **no Keychain** code in the repository.

**CI is red on `main` and on this branch.** The iOS simulator build and `swift build` both pass; the `AstryxAudioEngineTests` step fails, which short-circuits the other 21 test steps, and SwiftLint fails with exit code 2. See §6.

**Verdict:** the honest grade today is **foundation, not product**. The fastest route to a real music app is not the 11-phase rewrite in the master prompt — it is a small number of surgical fixes (persistence, real audio, honest quality reporting, and reaching the features that already exist), followed by rebuilding the documentation so it stops overstating the system.

---

## 2. Repository inventory

| Layer | Swift files | LOC | Assessment |
|---|---:|---:|---|
| `App/` | 5 | 521 | Composition root + coordinator + root tabs. Works, but owns concrete types directly. |
| `Core/` (12 modules) | 52 | 7,995 | Strong protocol design; several modules are placeholders or unused. |
| `Platform/` | 10 | 2,025 | Correct layer isolation (`canImport` guards everywhere). Mix of real and stub adapters. |
| `Features/` | 10 | 5,512 | Screens exist and are navigable; several depend on mock data; no Settings screen. |
| `DesignSystem/` | 11 | 1,113 | Coherent tokens (Midnight Aurora) + 7 components. No Reduce Motion handling. |
| `Tests/` | 14 | 1,863 | 110 test methods, `Core` + `DesignSystem` only. No UI, no provider-contract, no perf tests. |
| **Total** | **122** | **19,118** | |

**Build configuration**

- `Package.swift`: `swift-tools-version:5.9`; platforms iOS 17 / macOS 14; three products (`QeloryxCore`, `QeloryxDesignSystem`, `QeloryxPlatform`); **zero external dependencies** (true — verified, no `Package.resolved` needed).
- `project.yml` (XcodeGen): iOS app target `Qeloryx`, bundle `com.qeloryx.app`, iOS 17, `SWIFT_STRICT_CONCURRENCY: complete`, `SWIFT_VERSION: 5.9`, framework links for SwiftData/AVFoundation/MediaPlayer/CoreHaptics/UIKit/SwiftUI.
- There is **no `.xcodeproj` in the repo** — the project is generated in CI via `xcodegen generate`. Correct and reproducible.
- **`Assets.xcassets` does not exist**, although `project.yml` sets `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon`. The app builds without an icon and **`AstryxColors` must therefore resolve colors in code**, not from an asset catalog.
- `App/Info.plist` declares `UIBackgroundModes: [audio, fetch]` ✅, and legacy `UIRequiredDeviceCapabilities: [armv7]` (harmless on iOS 17 but meaningless — should be removed).

**Module map (as built, not as documented)**

```
Core/AstryxAudioEngine   engine + queue + transitions        ← real logic, several defects
Core/LibraryEngine       protocol, models, indexing, storage  ← in-memory in production
Core/SearchEngine        inverted-index search                ← real, event-driven
Core/MetadataEngine      protocol + filename parser           ← AVAsset path returns nil
Core/DownloadEngine      URLSession-backed queue              ← real; not integrated w/ library
Core/TasteDNA            recommendation scaffolding           ← real-ish
Core/DSP                 EQ / ReplayGain / spectrum           ← NOT CONNECTED to audio
Core/EventBus            typed pub/sub                        ← real
Core/CapabilityRegistry  capability flags                     ← real
Core/ProviderLayer       provider protocols + 1 stub         ← no network
Core/QueueEngine         8-line typealias re-export           ← NOT a duplicate (verified)
Core/Shared              3 files; 2 are comments only
```

---

## 3. Architecture vs. the Cassette-inspired target

| Target principle | Current state | Gap |
|---|---|---|
| Feature-oriented SwiftUI | ✅ `Features/<Feature>/Presentation/...` | Feature *services* live in `Core`; acceptable. |
| Observable ViewModels | ✅ mostly `@MainActor ObservableObject` (27 `@MainActor` uses) | Several screens (`AudioLabView`, `DashboardView`, `DiscoveryView`, `TasteDNAView`, `SpacesView`, `TimeCapsuleView`) put the ViewModel **in the same file as the View** (300–550 lines each). |
| Actor-based services | ❌ **zero `actor` declarations in 19,118 lines** | 43 `@unchecked Sendable` + 25 `NSLock`s are doing the concurrency work by hand. This is the single largest architectural divergence from the target. |
| Shared domain models | ⚠️ `Core/Shared/Domain/Entities/DomainEntities.swift` is a **comment-only file**; real models live inside `LibraryEngine/Models` | Models are library-centric (`AstryxTrack` carries `fileURL`, `checksum`, `folderPath`), which will fight provider/streaming tracks later. |
| Centralized DI | ⚠️ partial | `App/QeloryxApp.swift` builds ~15 concrete objects in `init`, then re-declares them as **mutable stored properties**. There is no `AppDependencies` / composition-root type, and views still default-construct engines (`AstryxPlayerViewModel()` fallback, `AudioLabView(dspEngine: AstryxDSPEngine())`). |
| Native Apple integration | ✅ good layer boundary | `Platform/` correctly guards MediaPlayer/ActivityKit/UIKit/SwiftData. |
| Explicit persistence | ❌ **in-memory in production** | See §4. |
| Keychain credentials | ❌ none | No provider auth exists to store yet; still a stated principle with no implementation. |
| Swift concurrency safety | ⚠️ mixed | Hand-rolled locks + `@unchecked Sendable` + `try?` (74 uses) swallowing errors on critical paths (`AstryxAudioEngine.swift:196`, `:333` discard play-count failures). |

**Structural mismatches with the master prompt's target tree** — and my recommendation:

| Prompt asks for | Reality | Recommendation |
|---|---|---|
| `Qeloryx/App/…` inside a `Qeloryx/` folder | Sources are at repo root (`App/`, `Core/`, …) | **Do not move.** Both `Package.swift` and `project.yml` depend on these paths; a wholesale move buys nothing and risks CI. |
| `Models/`, `Views/`, `ViewModels/`, `Services/` mega-folders | Feature-oriented `Features/X/Presentation` + `Core/X` | **Keep the current layout.** It is closer to Cassette's actual philosophy than the prompt's flat tree. |
| `Configuration/*.xcconfig` | Settings live in `project.yml` | **Keep `project.yml` as the single source of truth**; adding xcconfig splits config across two systems. |
| `QeloryxUITests/` | none | **Add later**, as a real target, once screens are data-backed. Fake UI tests are worse than none. |
| 15 required docs | 3–4 real (`CHANGELOG`, `FEATURE_MATRIX`, ADRs), rest missing | Write them **from this audit**, incrementally, describing code that exists. |

---

## 4. Feature reality matrix

Legend: **REAL** = implemented, reachable, data-backed. **PARTIAL** = implemented but unreachable / incomplete / broken in practice. **MOCK** = placeholder or fabricated data. **MISSING** = absent.

### 4.1 Library & persistence

| Capability | Status | Evidence |
|---|---|---|
| Track/album/artist/genre models | **REAL** | `Core/LibraryEngine/Models/Track.swift`, `Album.swift` |
| Persistent library | **MOCK** | Production engine defaults to `InMemorySwiftDataStack` (`LibraryEngine.swift:88`); `App/QeloryxApp.swift:48` passes no storage. `SwiftDataAdapter` (`Platform/Persistence/SwiftDataAdapter.swift:168`) is never constructed; on Linux it degrades to in-memory (`:455`). |
| Schema / migrations | **MISSING** | No `VersionedSchema`, no `MigrationPlan` anywhere. |
| File scan + import | **PARTIAL** | `FileScanner`, `LibraryIndexer` real; but metadata comes from the **filename parser** because `extractViaAVAsset` returns `nil` (`Core/MetadataEngine/MetadataEngine.swift:88`) and the working `AstryxMetadataExtractor` (`Platform/Audio/MetadataExtractor.swift`) is **never instantiated** (verified: zero references). |
| Artwork extraction | **PARTIAL** | `RawMetadata.artworkData` is populated only by the unused Platform extractor. |
| Duplicate detection | **PARTIAL** | `checksum` is `"\(fileSize)_\(fileName)"` (`LibraryEngine.swift` incremental path) — **same-name files in different albums collide; renames create false duplicates.** |
| Missing-file recovery | **MISSING** | No `bookmarkData` persistence; no recovery UI. |
| Playlists CRUD | **MISSING** | `fetchPlaylists()` returns `[]` in both stores (`SwiftDataStack.swift`, `SwiftDataAdapter.swift:408`). `AstryxPlaylist` model exists; nothing persists or edits it. |
| Favorites / play counts | **PARTIAL** | Logic correct, but lost on relaunch (in-memory). |
| Search index refresh | **PARTIAL** | `SearchEngine` subscribes to `.incremental` only (`SearchEngine.swift:32`); `.fullReload` and `.favorites` changes are ignored. `rebuildIndex()` has **no caller** outside that one event. |

### 4.2 Playback

| Capability | Status | Evidence |
|---|---|---|
| Real decoding/playback | **PARTIAL** | `GaplessAudioPlayerAdapter` (dual `AVPlayer`) is real and is what the app injects (`QeloryxApp.swift:41`). But the engine falls back to `/tmp/<id>.mp3` when a track is unresolvable (`AstryxAudioEngine.swift:172`), and swallows load errors (`:176-180`). |
| Honest progress clock | **PARTIAL** | Position is fabricated when the adapter isn't playing (`:369` `position + 0.5`). |
| Play/pause/next/previous/seek | **REAL** (logic) | `AstryxAudioEngine.swift:223-289` |
| Queue add/move/remove | **REAL** | `QueueController.swift:69-115` |
| Shuffle | **BROKEN** | State toggles and order is shuffled (`QueueController.swift:179-200`), but `next()` never consults `shuffleEnabled` — playback follows array order. |
| Repeat off/one/all | **REAL** | `QueueController.swift:128-141` |
| Crossfade | **UNREACHABLE** | `.setCrossfade` is never sent from app code (grep: only `AudioLabView` local `@Published` state and a comment at `QeloryxApp.swift:40`). |
| Gapless | **PARTIAL** | Dual-deck pre-staging exists, but the guarded natural-end path can never fire for a standby deck (see BUG-06) and preload is a `debugPrint` (`AstryxAudioEngine.swift:349-356`). |
| EQ / ReplayGain / DSP | **DISCONNECTED** | `AstryxDSPEngine` never passed to engine/adapter; `AudioLabView:336` builds a second instance. |
| Background audio | **PARTIAL** | `UIBackgroundModes: audio` ✅; `AVAudioSession` category/activation real (`AstryxAudioSessionManager.swift`); but no `MPNowPlayingInfoCenter` rate/`playbackState` beyond position, and no interruption correctness (BUG-05). |
| Lock screen / Control Center | **PARTIAL** | `AstryxNowPlayingManager` real-ish; remote command handlers return `.success` **before** the async work runs (`AstryxAudioEngine.swift:494-520`), so failures are invisible to the system. |
| AirPlay | **PARTIAL** | `allowsExternalPlayback` + `isExternalPlaybackActive` wired; no route-picker UX. |
| Sleep timer | **MISSING** | Not found. |
| Playback state restoration | **MISSING** | No persistence of queue/position; no `UserDefaults`/`@AppStorage` anywhere outside one comment (`SearchViewModel.swift:88`). |
| Audio quality reporting | **PARTIAL / MISLEADING** | `AstryxTrack.isLossless` is trusted as a display flag; `BitPerfectOutput.swift` exists but no output-side verification. Pair with the honesty rule: source ≠ output. |

### 4.3 Downloads

| Capability | Status | Evidence |
|---|---|---|
| Queue, priority, concurrency cap | **REAL** | `Core/DownloadEngine/DownloadEngine.swift` |
| Retry with backoff | **REAL** | `:583-592` |
| Pause/resume/cancel | **REAL** | `:140-210` |
| Persistent task state across relaunch | **MISSING** | Zero `Codable`/`UserDefaults`/SwiftData in `DownloadEngine.swift` (verified by grep). |
| Background session restore | **BROKEN** | Identifier is randomised per launch: `"com.qeloryx.downloads.\(UUID().uuidString)"` (`DownloadSessionManager.swift:28`). A background session **must** use a stable identifier to be reattached after relaunch. |
| Atomic move | **PARTIAL** | `moveItem` used (`:517`) but preceded by delete-then-move (`:514-517`) — a crash between them loses both files. |
| Integrity verification | **MISSING** | No checksum/hash of downloaded bytes. |
| Post-download → library | **MISSING** | `DownloadEngine` has **no reference to `LibraryEngine`** (grep: none). A completed download is a file on disk that nothing indexes. |
| Wi-Fi-only setting | **MISSING** | `allowsCellularAccess = true` hard-coded (`DownloadSessionManager.swift:31`). |

### 4.4 Discovery, recommendations, lyrics

| Capability | Status | Evidence |
|---|---|---|
| Search (local) | **REAL** | `IndexedSearch.swift` inverted index; `SearchView` wired |
| Search across providers | **MISSING** | No network layer (§1.5) |
| Recommendations | **PARTIAL** | `TasteDNAEngine` computes a profile; `AstryxRecommendationProvider(tasteEngine:)` registered. Provider itself is local-only — acceptable **if labeled**, per the "no fake AI" rule. |
| Daily mixes / artist radio | **MISSING** | Not present. |
| Lyrics: LRC parse, synced, karaoke | **REAL** | `LyricsProvider.swift` models + `AstryxLyricsEngine` |
| Lyrics: fetching from LRCLIB | **MISSING** | No HTTP anywhere; provider is local text only |
| Lyrics UI reachability | **BROKEN** | `LyricsView` is **referenced by nothing** (grep: only its own file and viewmodel). No route to it. |
| Smart playlists (rule model) | **REAL** | `Core/LibraryEngine/SmartPlaylists/SmartPlaylist.swift` (316 LOC) |
| Smart playlists persisted/applied | **MISSING** | No store, no evaluation entry point from the library |

### 4.5 Screens & reachability

| Screen | Data-backed? | Reachable? |
|---|---|---|
| Library | yes (in-memory) | ✅ tab |
| Search | yes | ✅ tab |
| Discovery | partly | ✅ tab |
| Dashboard/Home | **MOCK fallback** — `favoriteCount = 42; recentCount = 12; downloadCount = 8; queueCount = 5` when empty (`DashboardView.swift:242-249`) | ✅ tab |
| Downloads | yes | ✅ tab |
| Player (full) | yes | ✅ sheet |
| AudioLab | **MOCK spectrum** (`AudioLabView.swift:255`) | via Discovery → ✅ |
| TasteDNA | **MOCK profile** when no tracks (`TasteDNAView.swift:418`, `:470`) | via Discovery/Dashboard ✅ |
| Spaces (social) | **MOCK** (`SpacesView.swift:237`) | via Discovery ✅ |
| TimeCapsule (stats) | **MOCK** (`TimeCapsuleView.swift:168`, `:250`) | via Discovery ✅ |
| Lyrics | real model | ❌ **unreachable** |
| **Settings / customization** | — | ❌ **does not exist** |
| Queue sheet | — | ❌ does not exist (queue is engine-only) |

**Dead navigation:** `AppCoordinator.navigationPath` is `@Published` and appended to (`AppCoordinator.swift:72`) but **no view binds it** — there is no `.navigationDestination`. Every `.album/.artist/.settings/.audioLab/.lyrics` route is a no-op.

Also: the Dashboard's "Music" tab bar is **5 tabs** and Home is last; the prompt wants Home first. Minor, but reflects that navigation was not designed as a whole.

### 4.6 Ecosystem

| Capability | Status |
|---|---|
| Widgets, App Intents, Siri, CarPlay, Spotlight, Share extension | **MISSING** (no `Intents`/`WidgetKit`/`CarPlay` imports anywhere) |
| Dynamic Island / Live Activity | **PARTIAL** — `AstryxPlaybackAttributes` exists (`LiveActivityManager.swift:14`) but there is **no Widget Extension target**, so `Activity.request` cannot render a UI. |
| Cloud sync | **MISSING** |
| Social listening | **MOCK** (`SpacesView`) |
| macOS target | **MISSING** as an app target (SPM declares macOS 14; the app is iOS-only, `project.yml`) |
| Listening statistics | **MOCK** (`TimeCapsuleView`) |

---

## 5. Defect register (summary)

Full detail, repro and remediation in **`Docs/BUG_REGISTER.md`**. Severity: **S1** data loss / broken core; **S2** feature broken; **S3** quality; **S4** hygiene.

| ID | Sev | Defect | File:line |
|---|---|---:|---|
| BUG-01 | S1 | Production library is in-memory; all data lost on relaunch | `LibraryEngine.swift:88`, `QeloryxApp.swift:48` |
| BUG-02 | S1 | Audio engine fabricates a `/tmp/*.mp3` URL and swallows the failure | `AstryxAudioEngine.swift:172`, `:176-180`, `:312` |
| BUG-03 | S1 | Position clock fabricates progress when not playing | `AstryxAudioEngine.swift:369` |
| BUG-04 | S2 | Shuffle never affects playback order | `QueueController.swift:118-141` |
| BUG-05 | S2 | Interruption resume fires **unconditionally** on `shouldResume_true` (even if user had paused); `route_oldDeviceUnavailable` is published but never consumed; stringly-typed control flow | `AstryxAudioSessionManager.swift:62`, `:117` vs `AstryxAudioEngine.swift:438-441` |
| BUG-06 | S2 | Crossfade unreachable from production code | `QeloryxApp.swift:40` (comment only) |
| BUG-07 | S2 | EQ/DSP/ReplayGain disconnected from audio; AudioLab edits a second instance | `QeloryxApp.swift:52`, `AudioLabView.swift:336` |
| BUG-08 | S1 | Download background session uses a random identifier → no restore | `DownloadSessionManager.swift:28` |
| BUG-09 | S1 | Download task state is never persisted | `DownloadEngine.swift` (no persistence) |
| BUG-10 | S2 | Completed downloads never enter the library | `DownloadEngine.swift` (no library ref) |
| BUG-11 | S2 | `next()`/`repeat .one` re-`load()` the same track from position 0 | `AstryxAudioEngine.swift:261` → `QueueController.swift:128` |
| BUG-12 | S3 | Gapless standby end-notification guard can never pass | `GaplessAudioPlayerAdapter.swift:335` |
| BUG-13 | S3 | `@Attribute(.unique)` present but no schema versioning/migration | `SwiftDataAdapter.swift:14`, `:127` |
| BUG-14 | S3 | Search index ignores `.fullReload` and `.favorites` | `SearchEngine.swift:32` |
| BUG-15 | S3 | Duplicate "checksum" is size+filename → false dupes / missed dupes | `LibraryEngine.swift` incremental path |
| BUG-16 | S3 | Atomic-ish move is delete-then-move | `DownloadEngine.swift:514-517` |
| BUG-17 | S3 | Remote commands return `.success` before work completes | `AstryxAudioEngine.swift:494-520` |
| BUG-18 | S3 | `navigationPath` is never bound → dead deep links | `AppCoordinator.swift:29`, `:72` |
| BUG-19 | S3 | Mock numbers shown as real stats | `DashboardView.swift:242-249` and 4 others |
| BUG-20 | S3 | Playback failure is swallowed into "simulated playback" | `AstryxAudioEngine.swift:176-180` |
| BUG-21 | S4 | 19 lines exceed the 200-char `line_length` **error** threshold → SwiftLint exit 2 | repo-wide |
| BUG-22 | S4 | CI annotation step greps `\berror:` and matches source text `error: Error` (false positives) | `.github/workflows/ci.yml:165` |

---

## 6. CI / build status (verified via API)

Run `42351857664` — `CI` on `main` @ `7ec6b0a` (also reproduced on `2719e61` and on the earlier branch run `42292058334`).

| Job | Result | Note |
|---|---|---|
| **iOS simulator build** | ✅ success | `xcodegen generate` + `xcodebuild … build` passes. This is the only proof the app compiles. |
| Swift package — **Build** | ✅ success | `swift build -v` passes. |
| Swift package — **Test AstryxAudioEngineTests** | ❌ **failure** | Step 6 fails; steps 7–28 (all remaining test classes) **skipped**. |
| Swift package — all other tests | ⏭ skipped | Never ran. **All 110 tests are effectively unverified in CI.** |
| **SwiftLint** | ❌ failure | `swiftlint lint` exit code **2**, which is the "errors found" code (`config`/`missing` are 3/4). |
| Documentation sanity | ✅ success | Checks doc files exist only. |
| Performance checks | ✅ success (earlier run) | — |

**On the `AstryxAudioEngineTests` failure.** I could not read the log (egress). What the evidence *does* establish:

- The step contains 6 tests (`testInitialState`, `testPlayQueue`, `testPlayPauseToggle`, `testNextPrevious`, `testShuffle`, `testSeek`).
- The job's annotation step greps `\berror:` across `swift-build.log` and **all** `test-*.log` files, and produced **10 annotations, all titled `Swift diagnostic (swift-build.log)`**, all of which are *source context lines containing the text* `error: Error` (from `adapterDidFail(error: Error)` / `downloadDidFail(... error: Error ...)`). **No annotation came from `test-AstryxAudioEngineTests.log`.**
- Therefore the failing test log contained **no line matching `\berror:`** — i.e. **not** an `XCTAssert*` failure (those emit `error: -[Class test] : …`) and **not** a thrown Swift error (`threw error:`).
- A test step that fails with no diagnostic, plus the workflow's own comments about runs "wedging", points to a **process-level failure: a trap/crash or a killed/hung run**, not an assertion.

**Ranked hypotheses (UNVERIFIED, require a macOS reproduction):**
1. **Test-induced trap/deadlock** in the timer path: `startPlayback` unconditionally starts a repeating `Timer.scheduledTimer` (`AstryxAudioEngine.swift:358`) which retains itself and never stops if the test ends without `stop()`; on a non-main runloop it silently never fires, and on a main-thread XCTest it keeps the process alive. Combined with `eventBus.publish`'s `DispatchQueue.global(...).async` fan-out, this is the most plausible hang.
2. **`AstryxAudioEngine` never deallocates** (retain cycle: `avAdapter.delegate = self` is `weak`, but `subscriptionStore` + `Timer` keep the engine and bus observers alive across tests in the same process).
3. A trap inside the queue/crossfade path reachable from `testNextPrevious` via `next()` → `startPlayback` → `preloadNext`.

**None of these may be claimed as the cause until a macOS run names it.** The fix plan (§8) makes this the first task.

**On the SwiftLint failure — this one I can prove statically.** `line_length` is configured as `error: 200` (`/home/user/Qeloryx/.swiftlint.yml`), and there are **19 non-comment lines longer than 200 characters** in non-excluded files, e.g.:

```
Core/MetadataEngine/MetadataEngine.swift:22           326
Platform/System/LiveActivityManager.swift:62          356
Platform/Persistence/SwiftDataAdapter.swift:374       284
Platform/Persistence/SwiftDataAdapter.swift:378       263
Core/AstryxAudioEngine/AstryxAudioEngine.swift:454    231
Core/AstryxAudioEngine/Queue/QueueModels.swift:45     232
Core/SearchEngine/SearchResult.swift:26               224
Features/Player/Presentation/AstryxPlayerView.swift:297  227
```

19 error-level violations ⇒ exit code 2. **This is deterministic and explains the lint job without needing logs.** There are also ~308 warnings (over `warning: 120`), 3 files over the 500-line warning threshold, and `force_unwrapping` is opted-in — so simply lengthening the limit is the wrong fix; the plan splits lines *and* brings the worst offenders under `file_length`/`type_body_length`.

---

## 7. Security & privacy review

| Item | Finding |
|---|---|
| Credentials in code | ✅ none found |
| Keychain | ❌ absent (`SECURITY.md` also absent) |
| Logging | ⚠️ `debugPrint` is used liberally and guarded by `#if DEBUG` in most places, but `AppConfiguration.enableLogging` is not enforced, and there is no redaction layer. Provider URLs/tokens would leak if added naively. |
| File validation | ⚠️ `AudioFormat.fromExtension` only — no container/codec sniffing, so an `.mp3`-named non-audio file is "supported". |
| Network | ⚠️ download `URL` is taken from the caller with no scheme/host allowlist (`DownloadEngine.enqueue(track:sourceURL:)`) — SSRF-ish surface once providers exist. |
| Temp files | ⚠️ downloads land in `.documentDirectory` directly; no temp+verify+confirm. |
| Privacy | ℹ️ no analytics, no telemetry, no network → currently the best kind of privacy. `enableAnalytics` is hard-coded `false` in `.current` and `true` in `.production` — **`enableAnalytics: true` exists but nothing consumes it**; it must not become a switch that ships silent telemetry. |

---

## 8. Recommended plan

### 8.0 Two corrections to the master prompt before we proceed

1. **Do not follow the 11-phase sequence as written.** Phases 1–9 all assume the foundation is sound; it isn't. Structural refactoring now would move broken code around. **Foundation first.**
2. **Do not do the `Qeloryx/` folder restructure.** It contradicts both `Package.swift` and `project.yml` and delivers no behaviour. Keep the current feature-oriented layout, which is genuinely Cassette-like.

### 8.1 Phase 0.5 — Make the truth-tellers work (2 small PRs)

1. **Fix CI so it can tell us anything.** Repair the annotation step to match real diagnostics (`: error:` with a file path, and `XCTAssert|threw error`), then reproduce `AstryxAudioEngineTests` on macOS and record the actual failure. Add per-test `.xctestplan` filtering so one failing class cannot mask 110 tests.
2. **Fix SwiftLint.** Split the 19 over-long lines; add `force_unwrapping` remediation; confirm exit 0. Keep `Tests` excluded.
3. **Rebase onto `main`** (this branch is 1 commit behind) so the CI workflow fixes apply here.

### 8.2 Phase 1 — Persistence that survives relaunch (S1) — *the highest-value slice*

**Objective:** close the loop *import → persist → relaunch → play*. This is the smallest unit that converts "demo" into "app".

- Wire `SwiftDataAdapter` into `AstryxLibraryEngine` via an injected `SwiftDataStackProtocol`; delete the in-memory default from the production path (keep it for tests explicitly).
- Add `SchemaV1` + `MigrationPlan`; add `libraryID` to `TrackModel` and enforce it (the in-memory filter is literally `|| true` — `SwiftDataStack.swift:110`).
- Persist playlists (currently `[]`); persist favorites/history (already modelled).
- Make `AstryxMetadataExtractor` (Platform) the real `MetadataEngineProtocol` implementation and inject it; stop returning `nil` from Core.
- Replace the `size_filename` "checksum" with a content hash (or `fileSize + duration + first-N-bytes`).
- **Acceptance:** import 3 files, relaunch, all 3 present with correct tags/artwork; favorites and play counts survive; search returns them; CI green with new persistence tests.

### 8.3 Phase 2 — Audio correctness (S1/S2)

- Remove the `/tmp` fake-URL fallback: an unresolvable track must produce a **typed failure** and a visible error state (`AstryxPlaybackState.failed`), never "simulated playback".
- Drive position from the adapter only; when it is not playing, **freeze**.
- Fix `setShuffle` semantics: shuffle must reorder the *upcoming* queue while preserving the current item, and `next()` must respect it.
- Fix the interruption string mismatch; on `ended` with `shouldResume`, resume only if we were playing when interrupted.
- Fix `repeat .one` to **seek to 0** rather than reload.
- Accept remote commands only after the command is applied (return `.success` from the completion).
- Persist queue + position; restore on launch (paused, never auto-playing).
- **Honest quality reporting:** report *source* codec/bit-depth/sample-rate from metadata, and *output* sample-rate/route from `AVAudioSession`; label "bit-perfect" as **unverified** unless route+format equality is actually proven.

### 8.4 Phase 3 — Make existing features reachable

- Bind `navigationPath` with `.navigationDestination` (or delete the half-route model).
- Route to `LyricsView` from the player; give the queue a sheet.
- Establish a real **Settings** screen and a single `SettingsRepository` (the prompt's §10) — appearance, audio, downloads, privacy. This also gives DSP/EQ a home.
- Connect DSP: build the EQ into the adapter's `AVAudioEngine` path (or, realistically, gate the UI and label the feature **"Preview — not applied to output"** until the engine exists). *Do not ship sliders that do nothing.*

### 8.5 Phase 4 — Remove the mocks and the dishonest docs

- Delete the `42/12/8/5` fallback stats, the mock spectrum, the mock TasteDNA profile, mock Spaces, mock TimeCapsule. Replace with **empty states**, which are honest and shippable.
- Rewrite `Docs/BUILD_READINESS.md` (currently claims *"App Store Ready ✅ … all production, no stubs"* — demonstrably false), `Docs/FEATURE_MATRIX.md` and `CHANGELOG.md` against this audit.

### 8.6 Phase 5+ — Then, and only then, the ambitious work

Network/provider layer (with Keychain + a real `MusicProvider` capability system), download→library integration with stable background sessions, then discovery/recommendations, then ecosystem (widgets/personas), then macOS.

**Deliberately deferred, with reasons:**
- **Cloud sync / social**: needs identity, a backend, and conflict resolution — and the prompt's own rule says design conflict resolution first. Nothing to sync until Phase 1 lands.
- **macOS app target**: SPM declares macOS, but `Platform` is iOS-centric; a real Mac app is Phase 10+, not now.
- **Ogg Vorbis / Opus**: AVFoundation cannot decode these on iOS. Supporting them requires bundling a decoder (licensing + maintenance review). **Do not advertise them** until that decision is made — note `AudioFormat` already lists `.ogg`/`.opus` as "supported" (`Track.swift`), which is a false claim in the model.

---

## 9. Source research (verified live, 2026-11-07)

Licenses below were fetched from the GitHub API, **not** assumed. This matters: the existing `Docs/FEATURE_MATRIX.md` is wrong in several places.

| Project | Actual license | Language | Status | Verdict for Qeloryx |
|---|---|---|---|---|
| CassetteLab/cassette | **MPL-2.0** | Swift | active | ✅ Best architectural reference. MPL-2.0 permits use in a differently-licensed app **at file granularity** with notices. Not GPL-compatible-free — keep attribution. |
| knp-org/luma-ios | **AGPL-3.0** | Swift | active (1★) | ❌ **Do not copy any code.** AGPL would infect the whole app. Ideas only. |
| evince55/Aria | **MIT** | Swift | active | ✅ Safest Swift source to borrow patterns from. Attribution required. |
| BLeeEZ/amperfy | **GPL-3.0** | Swift | active (1844★) | ❌ Code incompatible. Study server-sync/CarPlay *architecture* only. |
| navidrome/navidrome | **GPL-3.0** | Go | active | ❌ Code incompatible; ✅ Subsonic API is a public protocol — implement our own client. |
| metabrainz/listenbrainz-server | **GPL-2.0** | Python | active | ❌ Code; ✅ the *API* is public and usable. |
| metabrainz/musicbrainz-server | **NOASSERTION** (multi-licence, incl. GPL for server) | Perl | active | ❌ Server code irrelevant; ✅ MusicBrainz **web service** has its own terms — comply with rate limits + User-Agent. |
| tranxuanthang/lrclib | **MIT** | Rust | active | ✅ API free to call; lyrics remain user/provider content — respect terms. |
| team-spotube/spotube | **AGPL-3.0** | Kotlin | active | ❌ Do not reuse resolvers (also ToS-risky). |
| finamp-app/finamp | **MPL-2.0** | Dart | active | ❌ Language; ✅ Jellyfin integration patterns. |
| jeffvli/feishin | **GPL-3.0** | TypeScript | active | ❌ Code. |
| nukeop/nuclear | **AGPL-3.0** | TypeScript | active | ❌ Code; plugin concepts only. |
| harmonoid/harmonoid | **NOASSERTION** (EULA-style) | Dart | active | ❌ **Do not read or reuse.** ReplayGain is an open spec — implement from spec. |
| Clash-Projects/LastWave-Native | **GPL-3.0** | Kotlin | active | ❌ Code. |
| kushagrasinghx/BitChord | **GPL-3.0** | Kotlin | active | ❌ Code. |
| chthollyphile/folia-major | **AGPL-3.0** | TypeScript | active | ❌ Code. |
| OneOfWolvesBilly/HarmoniaPlayer | **NOASSERTION** | Swift | active (1★) | ⚠️ Unclear licence → treat as all-rights-reserved until confirmed. |

**Corrections to the existing `Docs/FEATURE_MATRIX.md`:** it lists LastWave-Native and BitChord as GPL-3.0 (✅ correct), **Finamp as "MPL-2.0"** (✅ correct, though it lists it under a different name), and **Harmonoid as "Proprietary EULA"** (⚠️ GitHub reports `NOASSERTION` — treat as unknown → do not read). It also claims *"Core stays Foundation-only"*, which is **false**: `Core/Shared/Protocols/PlatformProtocols.swift:7-8` and `Core/AstryxAudioEngine/AstryxAudioEngine.swift:490-491` import `MediaPlayer` (guarded), and `Core/LibraryEngine/Storage/SwiftDataStack.swift:347` imports `SwiftData`.

**Unverifiable from this sandbox (recorded, not guessed):** `8spine/8spine` **does not exist** as a public repo (only forks/release mirrors, no canonical source); `Yuzic`, `LocalMusic (j23n)`, `Eclipse Music`, `Medley (sbdevelopment)`, `SereneAudioPlayer`, `OpenSong` could not be verified as canonical/maintained under those paths. **Treat all of these as unverified and do not cite them as architectural references** until confirmed.

### 8.6.1 Legal position

- **Only MIT / MPL-2.0 sources may contribute code**, with per-file notices in `THIRD-PARTY-NOTICES.md` (MPL-2.0 requires file-level availability of *modified* MPL files).
- GPL/AGPL/NOASSERTION projects: **ideas only**; a file that was written after reading GPL code must be clean-room and note its independent origin.
- **Qeloryx has no `LICENSE`** (verified: no `LICENSE`, `CONTRIBUTING.md`, or `SECURITY.md`). This must be decided before any borrowing occurs.
- No DRM circumvention, stream ripping, or paywall bypass — the existing `Docs/FEATURE_MATRIX.md` already takes this position; keep it.

---

## 10. What to preserve (do not rewrite)

These are good and should be repaired, not replaced:

1. **`Core/EventBus`** — clean typed pub/sub. One flaw: handlers run on arbitrary global-queue threads; give consumers an explicit executor.
2. **`Platform/GaplessAudioPlayerAdapter`** — genuinely well-considered dual-deck crossfade with curve math and tests. Fix BUG-06 (make it reachable) and BUG-12 (guard), do not replace.
3. **`Core/AstryxAudioEngine/Transitions/*`** — `CrossfadeCurve`, `CrossfadeConfiguration`, `GaplessTransitionController` are testable and correct.
4. **`Core/SearchEngine/IndexedSearch`** — real inverted index, sub-50ms design goal, worth keeping and extending.
5. **`Core/LibraryEngine/SmartPlaylists`** — a real rule model; needs a store + evaluator, not a rewrite.
6. **`Core/ProviderLayer/LyricsProvider`** models — LRC/word-level/karaoke/translation-readiness is the right data model.
7. **`DesignSystem`** — coherent tokens; keep the Midnight Aurora identity.
8. **The SPM + XcodeGen split** — keep it.

---

## 11. Explicit non-claims

To be unambiguous, the following are **not** true today and must not appear in any document, release note, or store listing until fixed:

- ❌ "Persistent library" — in-memory.
- ❌ "Gapless playback" — pre-staging exists, natural-end path is defeated for the standby deck.
- ❌ "Crossfade" — unreachable.
- ❌ "Equalizer / ReplayGain" — no audio path connection.
- ❌ "Background downloads that survive relaunch" — random session ID, no persisted state.
- ❌ "Synced lyrics from LRCLIB" — no network layer.
- ❌ "Supports OGG/Opus" — AVFoundation cannot decode them on iOS.
- ❌ "Bit-perfect output" — never verified; source quality ≠ output quality.
- ❌ "App Store ready" / "no stubs" — `Docs/BUILD_READINESS.md` is inaccurate.
- ❌ "macOS app" — no macOS target exists.
- ❌ "Social listening" — a mock view.

---

## 12. Bottom line

The repository is a **credible engineering skeleton with real, testable logic in the places that are hardest to get right (crossfade math, search index, event bus, lyric model) and missing or disconnected logic in the places that make it a product (persistence, the audio path, feature reachability, honesty of reporting).**

The next commit should make the app remember a song after relaunch. Everything else in the master prompt is downstream of that.
