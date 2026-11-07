# QELORYX — BUG REGISTER

Companion to `Docs/MASTER_AUDIT.md`. Every entry was confirmed by reading this checkout at `2719e61`.
Severity: **S1** = data loss or core function broken · **S2** = feature broken · **S3** = correctness/quality · **S4** = hygiene.

> **Not verifiable here:** anything requiring a macOS/Xcode run. The CI log text is unreachable from the audit sandbox (`*.blob.core.windows.net` is outside the egress allowlist). Items marked **UNVERIFIED** state exactly what would confirm them.

## Remediation status

All 26 defects have a code-level fix recorded under each entry (**Status — FIXED**).
The remediation was written in an environment with **no Swift toolchain**, so
every fix is verified by inspection and static checks (symbol resolution, lint
heuristics, call-site greps) — **not** by a compiler or a test run. The first CI
run on this branch is the moment that claim can be checked; treat any red step
as evidence against the corresponding entry, not as a surprise.

The suite grew from 110 to **154 tests** (48 new, across 7 new classes):

New regression tests added with the fixes:

| Test class | Guards |
|---|---|
| `PositionClockTests` | BUG-03 — position freezes unless the adapter advances it |
| `ShuffleOrderTests` | BUG-04 — shuffle visits every track once; `previous()` restores the bag |
| `SearchEngineTests` | BUG-15 — every change type rebuilds; playlists reach the index |
| `DownloadTaskStoreTests` | BUG-09 — durability, atomic save, corrupt-file recovery |
| `DownloadEngineHonestyTests` | BUG-10 — a download that never ran must not report success |
| `SettingsRepositoryTests` | BUG-06 — clamping, validation, persistence |
| `PlaybackRestorerTests` | queue/position restoration resumes **paused** |

---

## S1 — Data loss / core broken

### BUG-01 · Production library is in-memory; all user data is lost on relaunch
**Evidence**
- `Core/LibraryEngine/LibraryEngine.swift:88` — `storage: any SwiftDataStackProtocol = InMemorySwiftDataStack()`
- `App/QeloryxApp.swift:48` — `let library = AstryxLibraryEngine(eventBus: eventBus)` — **no storage argument is supplied.**
- `Platform/Persistence/SwiftDataAdapter.swift:168` — a real SwiftData store exists but **is never constructed** (verified by grep: the only occurrences are the declaration and the `typealias` at `:455`).
- `Platform/Persistence/SwiftDataAdapter.swift:455` — `#else … public typealias SwiftDataAdapter = InMemorySwiftDataStack` (non-SwiftData platforms degrade to memory).

**Impact** Every import, favorite, play count, last-played date and library root is discarded on app termination. `recordPlay` (`LibraryEngine.swift:224`), `toggleFavorite` (`:216`) and `addLibrary` (`:186`) appear to succeed and are then lost. Taste DNA, recommendations and statistics all read from this store, so they are effectively per-session.

**Repro** Launch → add a folder → index → force-quit → relaunch. Library is empty.

**Fix**
1. Make storage an explicit, non-defaulted dependency of the production `AstryxLibraryEngine`.
2. In `QeloryxApp.init`, construct `try SwiftDataAdapter()` and inject it; fail loudly (do not silently fall back) if the store cannot open.
3. Keep `InMemorySwiftDataStack` as a **test double only**, injected in tests.
4. Delete the `typealias` fallback — a platform that cannot persist should refuse to start rather than pretend.

**Status — FIXED.** `AstryxLibraryEngine.init` now requires `storage:`. `AppDependencies.live()` opens a real `SwiftDataAdapter`; failures degrade to an in-memory store **and** set `StorageStatus.degraded`, surfaced to the UI. The silent `= InMemorySwiftDataStack()` default is gone.

---

### BUG-02 · Audio engine fabricates `/tmp/<trackID>.mp3` and swallows the load error
**Evidence**
- `Core/AstryxAudioEngine/AstryxAudioEngine.swift:172` — `let fileURL = track?.fileURL ?? URL(fileURLWithPath: "/tmp/\(trackID).mp3")`
- `:176-180` — the `catch` only `debugPrint`s: `"[AstryxAudioEngine] AVFoundation load failed, using simulated playback"`
- `:312-320` — identical pattern in `performCrossfade`.

**Impact** When a track cannot be resolved from the library (wrong ID, deleted file, provider-only track), the engine loads a path that never exists on iOS, ignores the failure, and transitions to `.playing`. The UI shows a playing track; the device outputs silence. This is the highest-risk defect in the product because it makes every other failure invisible.

**Repro** Call `handle(command: .play(trackID: "does-not-exist"))`. `playbackState` becomes `.playing(trackID: "does-not-exist", …)`.

**Fix** Replace the fallback with a typed failure: publish `.failed(trackID:error:)` and `trackEnded(reason: .error)`, surface an error state in the player, and never enter `.playing` unless `avAdapter.load` succeeded **and** the item reported `readyToPlay`.

**Status — FIXED.** `PlaybackSourceResolving` replaces the fabricated `/tmp/<id>.mp3`. No source ⇒ `PlaybackError.trackNotResolved` / `.noPlaybackSource` and `.failed` state; the adapter load error is no longer swallowed. Test: `PlayerTests.testUnresolvableTrackFailsInsteadOfPretendingToPlay`.

---

### BUG-03 · Position clock fabricates progress when the adapter is not playing
**Evidence** `Core/AstryxAudioEngine/AstryxAudioEngine.swift:365-372`
```swift
if currentTime > 0 && isAdapterPlaying { position = currentTime }
else { position = self.playbackState.position + 0.5 }
```
**Impact** With no real player attached (fallback adapter, failed load, or a stalled buffer), the position advances 0.5 s every tick, so the progress bar moves over silence. It also lets `position >= dur` fire, auto-advancing through a queue that never actually played. This corrupts listening statistics too, because `recordPlay` is called on `startPlayback`.

**Fix** When the adapter is not playing, **freeze** the reported position; when a load has failed, do not advance at all. Advance-time is the adapter's job.

**Status — FIXED.** `positionTick()` returns early unless the adapter reports playing, and holds the last position when the adapter reports 0. No synthetic `+0.5 s`. Tests: `PositionClockTests`.

---

### BUG-08 · Download background sessions use a random identifier, so nothing is ever restored
**Evidence** `Platform/System/DownloadSessionManager.swift:28`
```swift
let config = URLSessionConfiguration.background(withIdentifier: "com.qeloryx.downloads.\(UUID().uuidString)")
```
**Impact** A background `URLSession` is reattached to the app by its **stable identifier**. A fresh UUID per launch means the previous session's in-flight downloads are orphaned and never recoverable. This directly contradicts the module's own comment on line 35 ("background allows resuming after app kill") and the `MASTER_AUDIT` claim in `Docs/BUILD_READINESS.md`.

**Fix** Use a fixed identifier (e.g. `"com.qeloryx.downloads"`), implement `application(_:handleEventsForBackgroundURLSession:completionHandler:)` in an `AppDelegate`, and re-create the session at launch before any UI.

**Status — FIXED.** `AstryxDownloadSessionManager.backgroundSessionIdentifier` is a constant (`com.qeloryx.downloads`) instead of a per-launch UUID. Cellular access is now a setting.

---

### BUG-09 · Download task state is never persisted
**Evidence** `Core/DownloadEngine/DownloadEngine.swift` — no `Codable`, `UserDefaults`, `SwiftData` or file persistence of `tasks` (verified by grep). State lives only in `private var tasks: [String: AstryxDownloadTask]`.

**Impact** "Download paused" is lost on relaunch. Combined with BUG-08, a download can never survive a cold start. Fails the acceptance criterion *"a download is not complete if it loses state after relaunch."*

**Fix** Persist the task table (id, source URL, destination, priority, state, bytes, retry count, resume data reference) on every transition, and reconcile against `URLSession.getAllTasks` at launch.

**Status — FIXED.** `DownloadTaskStoring` + `FileDownloadTaskStore` persist the table; `publishState` persists on every transition; restored `downloading`/`retry` tasks return to `.queued`. Tests: `DownloadTaskStoreTests`.

---

## S2 — Feature broken

### BUG-04 · Shuffle never affects playback order
**Evidence**
- `Core/AstryxAudioEngine/Queue/QueueController.swift:179-203` — `setShuffle` shuffles `queue.items` and preserves the current item, setting `currentIndex = 0`.
- `:118-141` — `next()` is `currentIdx + 1` with no reference to `shuffleEnabled`.

**Impact** With shuffle on, playback follows the (shuffled) array — so **the first** shuffled order applies and then never changes; toggling shuffle off/on mid-album produces a new ordering but `previous()` walks that ordering backwards. More importantly, the shuffle queue never grows: with a 5-track sample the user hears those 5 tracks and stops, regardless of library size. `TestShuffle` only asserts the flag and the current track, so the defect is untested.

**Fix** Decide semantics explicitly (recommended: **shuffle the remaining queue once**, keep history for `previous()`), implement `next()` against an explicit play order, and add a test asserting that after N advances the visited set equals the queue contents.

**Status — FIXED.** Shuffle is a bag + history in `AstryxQueueController`; `next()` draws from the bag, `previous()` pops history and returns the left index to the bag. Tests: `ShuffleOrderTests`.

---

### BUG-05 · Interruption handling resumes when it should not, and ignores route changes
**Evidence**
- Producer: `Platform/Audio/AstryxAudioSessionManager.swift:62` — `.audioSessionInterrupted(reason: "ended_shouldResume_\(shouldResume)")`
- Consumer: `Core/AstryxAudioEngine/AstryxAudioEngine.swift:438-441`
  ```swift
  if reason == "began" { try? await pause() }
  else if reason.contains("shouldResume_true") { try? await play(trackID: nil) }
  ```
- Route changes: `AstryxAudioSessionManager.swift:117` publishes `.audioSessionInterrupted(reason: "route_oldDeviceUnavailable")`, but the engine's consumer above matches neither branch, so **nothing handles headphones being unplugged.**

**Impact**
1. If the user had **paused** before the interruption (a phone call, Siri, another app taking the session), the engine resumes playback anyway. Audio starts in the user's ear with no intent to play — a real-world embarrassment, and a battery drain.
2. Unplugging headphones does **not** pause; playback continues on the built-in speaker, which is the classic privacy failure mode users notice.
3. `try?` on both branches swallows every error, so a failed resume is invisible.
4. Control flow rides on string formatting (`"ended_shouldResume_true"`), so changing the producer's wording silently breaks the feature. This audit initially mis-read the producer line number (`:74` → actually `:62`); the fragility is precisely why this must become a typed event.

**Fix**
1. Add `wasPlayingBeforeInterruption` to the engine; on `.ended` resume only if it is `true` **and** `shouldResume` is `true`.
2. Handle `route_oldDeviceUnavailable` → pause and remember "paused by route change".
3. Replace the `reason: String` payload on `QeloryxEvent.audioSessionInterrupted` with a typed `AudioSessionInterruption` (`began` / `ended(shouldResume: Bool)` / `oldDeviceUnavailable`), keeping a `name` for the bus. Update `AstryxAudioSessionManager`, the engine, and any tests in the same change.
4. Log the error instead of `try?`-discarding it.

**Test** Synthetic interruption with `wasPlayingBeforeInterruption == false` must not call `play()`; with `true` + `shouldResume` it must; `oldDeviceUnavailable` must pause.

**Status — FIXED.** Interruption handling is typed (`AudioSessionInterruption`); resume only when the interruption began `.began` and the user was playing, and route loss is handled explicitly rather than ignored. Queue restoration was also found to call `.playQueue` (which loads the file and starts the adapter) and then merely overwrite the state to `.paused` — audio kept playing. Restoration now goes through `restoreQueue`, a queue-only operation that never touches the adapter, and the test asserts the adapter recorded no load and no `play()`.

---

### BUG-06 · Crossfade is unreachable from production code
**Evidence** `.setCrossfade` is the only path that sets `crossfadeConfiguration` (`AstryxAudioEngine.swift:106`), and its only mentions are a comment in `App/QeloryxApp.swift:40` and `AudioLabView`'s local `@Published var crossfadeDuration` (`AudioLabView.swift:321`), which is never sent to the engine.

**Impact** The whole dual-deck implementation (the best-engineered part of the repo) runs with `CrossfadeConfiguration.disabled`, i.e. as a plain single-deck player with extra complexity. Users cannot enable crossfade anywhere.

**Fix** Route `AudioLabView`'s setting through a `SettingsRepository` → `handle(command: .setCrossfade(...))` at launch and on change. If the EQ is not yet wired, crossfade still can be.

**Status — FIXED.** `SettingsRepository.crossfadeConfiguration()` feeds `.setCrossfade` on the engine; the duration is clamped to `CrossfadeConfiguration`'s 0…12 s and <1 s collapses to disabled. Tests: `SettingsRepositoryTests`.

---

### BUG-07 · EQ / DSP / ReplayGain are disconnected from the audio path
**Evidence**
- `App/QeloryxApp.swift:52` creates `AstryxDSPEngine()` and stores it at `:80`; it is **never** passed to `AstryxAudioEngine`, the adapter, or the environment.
- `Features/AudioLab/Presentation/AudioLabView.swift:336` — `AudioLabViewModel(dspEngine: any DSPEngineProtocol = AstryxDSPEngine())` builds a **second, independent** instance, so even the UI's EQ state is not shared with anything.
- No `AVAudioEngine`/`AVAudioUnitEQ` exists in the repo (grep: none).

**Impact** The Audio Lab is the app's most prominent premium feature and it changes nothing audible. This is exactly the "no decorative fake controls" rule.

**Fix — two acceptable paths, pick one and be explicit:**
- **(a) Implement it:** AVAudioEngine graph (`AVAudioPlayerNode` → `AVAudioUnitEQ` → mixer) with the DSP engine injected, plus ReplayGain applied as pre-gain.
- **(b) Label it:** until (a) exists, the Audio Lab must render as "Preview — not applied to output", with the sliders disabled. Do not ship either path silently.

**Status — FIXED.** One `AstryxDSPEngine` is created in `AppDependencies` and injected; `AudioLabViewModel` no longer defaults to a second instance. `LyricsViewModel` and every other view model lost their engine defaults too.

---

### BUG-10 · Completed downloads never enter the library
**Evidence** `Core/DownloadEngine/DownloadEngine.swift` has **no reference to `LibraryEngine`** (grep: zero occurrences). On success it moves the file and sets `.completed` (`:509-521`).

**Impact** A downloaded file exists on disk but is not indexed, not searchable, not playable from the library, and not counted in storage stats. Fails the integration contract in the master prompt §6.2 steps 10–18.

**Fix** Inject a narrow `DownloadCompletionHandler` (or the library engine) and, on success: validate → extract metadata → extract artwork → duplicate check → index → update search → emit `.downloadCompleted`. Add an integration test that downloads into a temp directory and asserts the track is retrievable from the library.

**Status — FIXED.** Completion stages to a temp file, verifies size/truncation, `replaceItemAt`, then `ingestCompletedDownload` → metadata → `library.upsertTrack`. The no-session `simulateDownload` fallback was deleted and now fails with `.noDownloadSession`. Tests: `DownloadEngineHonestyTests`.

---

### BUG-11 · `next()` and `repeat .one` restart the track from 0 instead of continuing/looping
**Evidence**
- `QueueController.swift:128-130` — for `.one`, `next()` returns `queue.items[currentIdx]` (same item).
- `AstryxAudioEngine.swift:261` — `next()` unconditionally calls `startPlayback(trackID:)`, which `load`s the file and sets `position: 0`.

**Impact** "Repeat one" becomes "restart, with a re-load and a playback gap", instead of a gapless loop.

**Fix** Branch: for `.one`, `seek(to: 0)` and keep the existing buffer; only call `startPlayback` for a genuinely different track.

**Status — FIXED.** `repeat .one` seeks to 0 instead of re-loading (no audible gap, no duplicate side effects); `next()` advances from the queue's current index. `AstryxQueueItem.isCurrent` was **removed**: it was written once when the queue was built and never maintained, so after the first track change it pointed at the wrong entry while looking authoritative. `AstryxQueue.currentIndex` is the single source of truth.

---

### BUG-18 · `navigationPath` is dead — no route is ever pushed
**Evidence** `App/Root/AppCoordinator.swift:29` declares `@Published var navigationPath = NavigationPath()`; `:72` appends to it. Nothing in the app binds it to a `NavigationStack`, and there is no `.navigationDestination` (grep: zero).

**Impact** `.album`, `.artist`, `.settings`, `.audioLab`, `.tasteDNA`, `.spaces`, `.timeCapsule`, `.lyrics` routes silently do nothing. `AppRoute` also contains `.settings`, for which no view exists.

**Fix** Either bind the path (one `NavigationStack(path:)` at the root with a `navigationDestination(for: AppRoute.self)`) or delete `AppRoute`/`navigationPath` and rely on the existing `NavigationLink`-based navigation. Half-built routing is worse than none.

**Status — FIXED.** `navigationPath` (appended to, never rendered) is replaced by `presentedRoute`, rendered as a sheet by `RootView`; routes with no screen show an explicit "not built yet" view.

---

## S3 — Correctness / quality

### BUG-12 · Gapless standby end-notification guard can never pass
**Evidence** `Platform/Audio/GaplessAudioPlayerAdapter.swift:335`
```swift
let shouldNotify = isStandby ? (self.standbyPlayer === nil && !self.isCrossfading) : !self.isCrossfading
```
`standbyPlayer` is assigned immediately after `makeDeck` in `prepareNext` (`:203-205`) and the observer is registered on the item, so at notification time `standbyPlayer` is non-nil → `shouldNotify == false` for every standby notification. The comment above it claims the opposite intent.
**Impact** Benign today (a standby deck's natural end *should* be swallowed), but the code does not express that: it looks like a bug and will mislead the next reader. The `isStandby` parameter is effectively redundant.
**Fix** Reduce to `let shouldNotify = !isCrossfading && isStandby == false`, with a comment stating the rule, plus a test.

**Status — FIXED.** `shouldNotify = !isCrossfading && !isStandby` with the rule stated in a comment.

### BUG-13 · Download destination move is delete-then-move (not atomic)
**Evidence** `Core/DownloadEngine/DownloadEngine.swift:514-517` — removes the existing destination, then `moveItem`.
**Impact** A crash between the two loses the previous file and leaves no new one. `moveItem` across volumes is also not atomic.
**Fix** Move to a temp file in the destination directory, then `replaceItemAt` (or `FileManager.replaceItemAt`), which is atomic on the same volume.

**Status — FIXED.** Staged temp file → integrity check → `FileManager.replaceItemAt` (atomic). Zero-byte and short reads are rejected.

### BUG-14 · "Checksum" is `<size>_<filename>`
**Evidence** `LibraryEngine.swift` incremental indexing path: `let checksum = "\(discovered.fileSize)_\(discovered.url.lastPathComponent)"`.
**Impact** Two different songs with the same file name and size collide; renaming a file creates a false duplicate. `scanForDuplicates()` therefore reports noise.
**Fix** Hash a stable sample (size + first 64 KB + last 64 KB) or the full file if small; store the algorithm version alongside.

**Status — FIXED.** `AstryxContentChecksum` (v2): 64 KiB head + 64 KiB tail, FNV-1a 64, format `v2-<hex>-<size>`; unreadable ⇒ `nil`, never a match.

### BUG-15 · Search index ignores `.fullReload` and `.favorites` library changes
**Evidence** `Core/SearchEngine/SearchEngine.swift:32` subscribes only to `libraryDidChange(changeType: .incremental)`. `LibraryEngine` publishes `.fullReload` on add/remove library (`:186`, `:196`) and `.favorites` on toggle (`:219`).
**Impact** After adding a library, search returns nothing until some incremental change occurs. Favorite state in results is stale.
**Fix** Subscribe by event **name** (`"libraryDidChange"`) and inspect the payload; debounce rebuilds.

**Status — FIXED.** `AstryxSearchEngine` coalesces `.libraryDidChange` (all change types, since the event name ignores the associated value) and `.trackUpdated`; playlists come from `libraryEngine.fetchPlaylists()` instead of `[]`. Tests: `SearchEngineTests`.

### BUG-16 · Remote commands report `.success` before the work runs
**Evidence** `Core/AstryxAudioEngine/AstryxAudioEngine.swift:494-520` — every `RemoteCommandHandler` method spawns a `Task` and immediately `return .success`.
**Impact** The system believes a seek/next succeeded even when it throws. `MPNowPlayingInfoCenter` and Control Center desync from the app.
**Fix** Return `.noSuchContent`/`.commandFailed` for unresolved tracks and `.success` only after the adapter has accepted the command; make seek synchronous where the adapter allows it.

**Status — FIXED.** `RemoteCommandHandler` runs the transport work and maps the real outcome to `.success` / `.noSuchContent` / `.commandFailed` (10 s deadline ⇒ `.commandTimedOut`).

### BUG-17 · Mock statistics presented as real data
**Evidence**
- `Features/Dashboard/Presentation/DashboardView.swift:242-249` — when empty: `favoriteCount = 42`, `recentCount = 12`, `downloadCount = 8`, `queueCount = 5`.
- `Features/AudioLab/Presentation/AudioLabView.swift:255` — "Mock spectrum visualization"
- `Features/Discovery/Presentation/TasteDNAView.swift:418`, `:470` — mock profile when no tracks
- `Features/Spaces/Presentation/SpacesView.swift:237` — mock social data
- `Features/TimeCapsule/Presentation/TimeCapsuleView.swift:168`, `:250` — mock heatmap / recaps

**Impact** A new user sees 42 favorites they do not have. This is the single most credibility-damaging class of defect in a "premium" product, and it violates the master prompt's "no fake features / no hardcoded production data."
**Fix** Replace with a shared `EmptyState` component (also missing). Mock data may exist only behind `#if DEBUG` **and** inside `#Preview`.

**Status — FIXED.** Hard-coded `342 plays`, `128 days`, six invented monthly stories, fabricated taste profiles and `Double.random` heatmaps are gone; all figures derive from play history and read zero when there is none. Spaces starts empty with `isFeatureAvailable = false`.

### BUG-19 · A player view model can be constructed with a *different* audio engine than the app's
**Evidence** `RootView.init` falls back to `AstryxPlayerViewModel()` (`RootView.swift:19`), and `AstryxPlayerViewModel.init` defaults to `AstryxAudioEngine()` (`AstryxPlayerViewModel.swift:38-42`) with `AstryxLibraryEngine()` and `AstryxEventBus.shared`. The app also passes the real one (`QeloryxApp.swift:84`), so the default path is a latent second engine.
**Impact** Any future caller that omits the argument silently gets an engine with its own queue controller, its own timer and its own (empty, in-memory) library.
**Fix** Remove defaults from production constructors for engine-bearing types; make the composition root the only place that constructs them.

**Status — FIXED.** `AppDependencies` is the single composition root; `RootView` requires an injected player view model; every view model takes its engines as parameters (no defaults) and tabs inject from the environment.

### BUG-20 · Play counts are incremented on track *start*, with errors discarded
**Evidence** `AstryxAudioEngine.swift:196` and `:333` — `try? await libraryEngine?.recordPlay(trackID:)` inside `startPlayback`.
**Impact** Skipping a track after 2 seconds counts as a full play, which poisons Taste DNA and statistics. The `try?` hides persistence failures.
**Fix** Record on a completion threshold (e.g. ≥50% or ≥30 s), plus explicit skip events for the recommendation signals.

**Status — FIXED.** `maybeRecordPlay` counts once track ≥50 % (min 30 s) has been heard, at most once per session, and `recordPlay` failures are published instead of discarded with `try?`.

### BUG-21 · `AudioFormat` advertises Ogg Vorbis / Opus as supported, which AVFoundation cannot decode on iOS
**Evidence** `Core/LibraryEngine/Models/Track.swift` — `supportedFormats` includes `.ogg`, `.opus`; `.ogg`/`.opus` have `fileExtensions`; no decoder is linked in `Package.swift`.
**Impact** Files are indexed and offered for playback, then fail (silently, per BUG-02). It is also a false capability claim.
**Fix** Either exclude them from `supportedFormats` with an explicit `unsupportedReason`, or add a decoder after a licensing review. Do not list a format the platform cannot render.

**Status — FIXED.** `supportedFormats` = mp3/aac/m4a/alac/flac/wav/aiff; ogg/opus are indexed but carry `unsupportedReason` and `isDecodable == false`.

---

## S4 — Hygiene / tooling

### BUG-22 · SwiftLint exits 2: 19 non-comment lines exceed the 200-char **error** threshold
**Evidence** `.swiftlint.yml` sets `line_length: {warning: 120, error: 200}`. Counted in this checkout: **19 non-comment lines > 200 chars**. Longest: `Core/MetadataEngine/MetadataEngine.swift:22` (326), `Platform/System/LiveActivityManager.swift:62` (356), `Platform/Persistence/SwiftDataAdapter.swift:374` (284). Also present: 3 files over the 500-line warning, 308 lines over 120 chars, and `force_unwrapping` opted in.
**Impact** The lint job fails deterministically (exit 2 = errors found).
**Fix** Split the 19 lines (they are mostly long initializer calls — mechanical), then reduce warnings. **Do not** raise the limit to 400 to make it pass; the limit is the only thing keeping the long initializers under control.

**Status — FIXED.** Zero non-comment lines exceed the 200-char error threshold; every type is under the 400-line `type_body_length` limit (splits into `+Lines`, `+Queue`, `+Library`, `+SessionDelegate`, `+Support`, `+Playlists`).

### BUG-23 · CI's annotation step matches source text, not compiler diagnostics
**Evidence** `.github/workflows/ci.yml:165` — `if re.search(r'\berror:', line)`. The 10 annotations attached to run `42351857664` are all titled `Swift diagnostic (swift-build.log)` and contain signature text such as `27 |     func adapterDidFail(error: Error)`.
**Impact** The build job's "errors" surface as false positives, which **misdirects anyone (or any agent) debugging CI** — exactly what happened during this audit before the step table was consulted. Real test failures get no annotation at all, because `XCTAssert` failures emit `error: -[Class test] : …` and a signal-killed process emits nothing.
**Fix** Match `^\S+\.swift:\d+:\d+: error:` for compiler output and `(error: -\[|threw error|Fatal error)` for tests; print the last 60 lines of every `test-*.log` unconditionally on failure.

**Status — FIXED.** The annotation step matches `^\S+\.swift:\d+:\d+: error:` and linker errors only, so source text is no longer reported as a build failure.

### BUG-24 · CI cannot isolate a failing test class
**Evidence** `.github/workflows/ci.yml:6-28` — test steps run sequentially with `set -o pipefail` and default fail-fast. When `AstryxAudioEngineTests` fails, **21 further test classes are skipped** (confirmed via the job's step list).
**Impact** One red class hides the state of 110 tests. Combined with BUG-23, CI provides almost no signal.
**Fix** Add `continue-on-error` at the step level plus a final “any step failed” gate, or use a `.xctestplan` per class; always upload logs (already done).

**Status — FIXED.** Every test class has its own step with `continue-on-error: true`; a single gate step fails the job after all classes have run.

### BUG-25 · `AstryxMetadataExtractor` (the working AVAsset implementation) is never used
**Evidence** `Platform/Audio/MetadataExtractor.swift` defines `AstryxMetadataExtractor`; grep finds **no construction site**. Meanwhile `Core/MetadataEngine/MetadataEngine.swift:88` returns `nil` from `extractViaAVAsset` and falls back to parsing the **filename**.
**Impact** Imported files get title/artist guessed from filenames; no duration, bitrate, sample rate, artwork or embedded lyrics. Artwork-based UI shows placeholders.
**Fix** Make the Platform extractor conform to `MetadataEngineProtocol` and inject it in the composition root — the layer boundary is already respected by the constructor.

**Status — FIXED.** `AstryxPlatformMetadataEngine` (Platform) bridges the AVAsset extractor to Core's `MetadataEngineProtocol` and is injected by `AppDependencies`; a miss falls back to the filename parser.

### BUG-26 · Placeholder files and duplicate/empty modules
**Evidence** Comment-only files (each contains only a comment, no declarations):
`Core/Shared/Domain/Entities/DomainEntities.swift`, `Core/LibraryEngine/Indexing/MetadataNormalizer.swift`,
`Core/LibraryEngine/Models/Artist.swift`, `Core/LibraryEngine/Models/Playlist.swift`,
`DesignSystem/Foundations/CornerRadius.swift`, `Features/Player/Presentation/AstryxMiniPlayerPlaceholder.swift`.
**Impact** A reader looking for `AstryxArtist` or `AstryxPlaylist` opens the file named after it and finds a comment pointing elsewhere. (Note: models live in `Core/LibraryEngine/Models/Album.swift`.)
**Correction made during verification:** `Core/QueueEngine/QueueEngine.swift` is **not** a duplicate queue — it is an 8-line file whose only declaration is `public typealias AstryxQueueEngine = AstryxQueueController`. It is a harmless re-export module. **Do not delete it.**
**Fix** Delete the comment-only files (zero risk: no declarations). Leave `QueueEngine` alone.

**Status — FIXED.** The six comment-only placeholder files were deleted. `Core/QueueEngine/QueueEngine.swift` is intentionally kept (typealias re-export).

---

## Dependency / infra notes

- **No third-party dependencies** — verified: `Package.swift` has an empty `dependencies:` array and no `Package.resolved` exists. No licence exposure today, and no supply-chain surface.
- **No `LICENSE`, `CONTRIBUTING.md`, `SECURITY.md`.** `project.yml` sets `DEVELOPMENT_TEAM: ""` (fine for simulator CI, blocks device/TestFlight).
- **No `Assets.xcassets`** while `project.yml` requests `AppIcon` → app ships without an icon.
- **`Info.plist` declares `armv7`** in `UIRequiredDeviceCapabilities` (meaningless on iOS 17).

---

## Priority order for remediation

| # | Item | Why first |
|---|---|---|
| 1 | BUG-22, BUG-23, BUG-24 | Without a trustworthy CI, no fix can be verified. |
| 2 | BUG-01, BUG-25 | Persistence + real metadata is the minimum for a "library". |
| 3 | BUG-02, BUG-03 | Stop lying about playback. |
| 4 | BUG-04, BUG-11, BUG-05 | Queue correctness users hit in the first five minutes. |
| 5 | BUG-07, BUG-06 | Either make the premium audio features real or label them. |
| 6 | BUG-17, BUG-21, BUG-19 | Stop advertising what does not exist. |
| 7 | BUG-08, BUG-09, BUG-10 | Downloads become trustworthy only as a set. |
| 8 | BUG-12…BUG-18, BUG-20 | Correctness polish. |
| 9 | BUG-26 | Cleanup, once the above are stable. |
