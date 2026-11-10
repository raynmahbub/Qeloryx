# QELORYX — IMPLEMENTATION ROADMAP

Derived from `Docs/MASTER_AUDIT.md` and `Docs/BUG_REGISTER.md`.
**Rule for every phase:** build must be green before the phase starts and after it ends; no phase begins while the previous phase's acceptance criteria are unmet.

---

## Corrections to the master prompt's Phase 1–11 sequence

The master prompt proposes structural refactoring as Phase 1 and the *foundation* (persistence, library, playback) as Phases 2–3. In this repository that order is inverted in terms of risk: a structural refactor of code that cannot persist a track or play a file produces a cleaner arrangement of broken parts, and it would touch `Package.swift`/`project.yml`, putting the one passing CI job (iOS build) at risk for no user-visible gain.

**Two deviations, both deliberate:**

1. **Foundation before structure.** Persistence → audio correctness → reachability → honesty → *then* structure.
2. ~~**No `Qeloryx/` folder reshuffle.**~~ **Superseded.** The single `Qeloryx/` root layout (with `App/ Models/ Views/ ViewModels/ Services/ Platform/ DesignSystem/ Utilities/ Resources/`) has since been adopted at the owner's explicit request. `Package.swift` and `project.yml` were retargeted together with the move, CI paths were updated, and the full old→new mapping is recorded in `Docs/ARCHITECTURE.md`. The original concern — that a reshuffle would endanger the iOS build — was mitigated by keeping type names stable inside moved files and updating every build/CI/lint reference in the same change.

Everything else in the prompt's phasing is retained, just re-sequenced.

---

## Phase 0 — Audit (this delivery) ✅

**Delivered** `Docs/MASTER_AUDIT.md`, `Docs/BUG_REGISTER.md`, `Docs/ROADMAP.md`.
**Not delivered, and why:** `ARCHITECTURE_REVIEW.md`, `FEATURE_MATRIX.md` (exists but must be rewritten), `DEPENDENCY_REPORT.md`, `LICENSE_REPORT.md`, `IMPLEMENTATION_ROADMAP.md` (this file) — folded into the three documents above rather than created as six overlapping files with duplicated tables. `SOURCE_INVESTIGATION.md` content lives in `MASTER_AUDIT.md` §9 with live-verified licences.

---

## Phase 0.5 — Make CI truthful — ✅ REMEDIATED (unverified)

> **Status update.** Every item below has a code-level fix and is recorded as
> **FIXED** in `Docs/BUG_REGISTER.md`. The acceptance criterion — "CI green with
> all classes executed" — **has not been observed**, because the remediation
> environment had no Swift toolchain. Treat the next CI run as the verification
> step: if `swift-package` or `lint` is red, read the annotations (they now point
> at real diagnostics) and fix forward from there.
>
> Specifically: the annotation matcher is exact and unit-checked against sample
> output; every test class has its own `continue-on-error` step plus a gate;
> `line_length` has zero errors and every type fits `type_body_length`; and
> `AstryxAudioEngineTests` now injects a `DictionaryPlaybackSourceResolver`,
> which is the most likely cause of the original failure (no resolver ⇒ every
> `play` threw). That last point remains a hypothesis until CI confirms it.

## Phase 0.5 — Make CI truthful (original specification)

**Why blocking:** every later phase needs a trustworthy signal. Today one failing test class skips 21 others and the annotation step reports false errors (BUG-22/23/24). As of this audit **all 110 tests are effectively unverified**.

**Work**
1. Fix the annotation matcher (`^...\.swift:\d+:\d+: error:`, `error: -\[`, `threw error`, `Fatal error`) and always dump the tail of every `test-*.log`. (BUG-23)
2. Make test steps non-fatal-but-reported so one class cannot mask 21. (BUG-24)
3. Split the 19 over-long lines → SwiftLint exit 0. (BUG-22)
4. Rebase onto `main` (this branch is 1 commit behind) so the workflow fixes apply here.
5. Reproduce `AstryxAudioEngineTests` on macOS and **record the actual failure** — the audit's top hypotheses (timer retaining the test process; engine never deallocating; trap in `next()`) are explicitly unverified and must not be "fixed" by guesswork.

**Acceptance** CI green on this branch, with all 14 test classes executed and the test count reported. If a class still fails, its real diagnostic appears in the check annotations.

**No feature work happens in this phase.**

---

## Phase 1 — Persistence that survives relaunch (S1, highest user value)

**Objective** Close the loop *import → persist → relaunch → play*.

**Work**
- Inject `SwiftDataAdapter` into `AstryxLibraryEngine`; remove the in-memory default from production paths; make failure to open the store loud. (BUG-01)
- Add `SchemaV1` + `MigrationPlan`; add `libraryID` to `TrackModel` and enforce it (the in-memory filter is literally `|| true` at `SwiftDataStack.swift:110`).
- Replace the `size_filename` checksum with a content hash. (BUG-14)
- Wire the real AVAsset metadata extractor through `MetadataEngineProtocol`. (BUG-25)
- Persist playlists (currently `[]` in both stores), favorites, history.
- Debounce/rebuild search on every library change type. (BUG-15)
- Delete the six comment-only files. (BUG-26) — first structural cleanup, done on a working foundation. Note: `Core/QueueEngine` is an 8-line typealias re-export, **not** a duplicate engine; keep it.

**Acceptance** Import 3 files → force quit → relaunch → 3 tracks with correct tags, duration and artwork; favorites and play counts survive; search finds them; new persistence tests in CI.

**Explicitly not in scope** Streaming tracks, provider IDs, sync. `AstryxTrack` currently carries `fileURL`/`checksum`/`folderPath` — do **not** generalise it into a provider-agnostic model yet; that is Phase 5, and doing it now would destabilise the persistence schema before it has ever run.

---

## Phase 2 — Audio correctness

**Objective** Playback reports exactly what is happening.

**Work**
- Typed playback failure instead of `/tmp` fallback; never enter `.playing` unless the item is `readyToPlay`. (BUG-02)
- Position advances only from the adapter; freeze otherwise. (BUG-03)
- Shuffle semantics: define an explicit play order, keep history for `previous()`, test that N advances cover the queue. (BUG-04)
- `repeat .one` seeks to 0 instead of reloading. (BUG-11)
- Interruption: remember `wasPlayingBeforeInterruption`, resume only if it was true; handle `route_oldDeviceUnavailable`. Replace the stringly-typed interruption event with a typed enum. (BUG-05)
- Remote commands return success only after the adapter accepts them. (BUG-16)
- Persist queue + position; restore **paused**, never auto-play.
- Record play counts on a completion threshold, not on start. (BUG-20)
- Honest quality reporting: source codec/bit-depth/sample-rate from metadata, output sample-rate and route from `AVAudioSession`; label bit-perfect **unverified** unless proven. Remove Ogg/Opus from the supported list or add a decoder. (BUG-21)

**Acceptance** With a real 3-track album on a device: play → pause → force quit → relaunch restores the queue paused at the right position; unplugging headphones pauses; interrupting with a call resumes only if it was playing; the quality badge states source and output separately; unit + audio-path tests green.

**Note** "Passing unit tests does not prove device audio." This phase needs a real device run; CI alone is insufficient.

---

## Phase 3 — Reachability

**Objective** Everything that exists can be reached; nothing advertises what is not wired.

**Work**
- Bind `navigationPath` or delete `AppRoute`. (BUG-18)
- Route to `LyricsView` from the player.
- Add a queue sheet (the engine supports add/move/remove; no UI exists).
- Add a **Settings** screen + a single `SettingsRepository` (the prompt's §10) with typed groups: Appearance, Audio, Downloads, Privacy. Defaults, validation, persistence, and a defined effect per key.
- Crossfade setting → engine. (BUG-06)
- DSP: choose (a) implement the AVAudioEngine graph, or (b) label Audio Lab "Preview — not applied". Do not leave it ambiguous. (BUG-07)

**Acceptance** Every tab, sheet and detail screen is reachable in ≤2 taps from Home; no control exists that changes nothing; settings survive relaunch.

---

## Phase 4 — Honesty and empty states

**Objective** Delete every fabricated number.

**Work** Remove the `42/12/8/5` fallback stats, mock spectrum, mock Taste DNA, mock Spaces, mock TimeCapsule (BUG-17). Add `EmptyState`, `LoadingState`, `ErrorState`, `Skeleton` components. Rewrite `Docs/BUILD_READINESS.md` (currently asserts "App Store Ready ✅ … all production, no stubs"), `Docs/FEATURE_MATRIX.md` (claims Core is Foundation-only — it is not), and `CHANGELOG.md`.

**Acceptance** A fresh install shows honest empty states on all five tabs; no document in `Docs/` makes a claim contradicted by `MASTER_AUDIT.md` §11.

---

## Phase 5 — Providers, network, credentials

**Objective** The first real network layer.

**Work** `MusicProvider` capability protocols (separate protocols per capability, as the prompt specifies — never a god-protocol). Keychain-backed credential store. Start with **Subsonic/Navidrome** (public API, implement our own client — Navidrome itself is GPL and irrelevant as code) and **LRCLIB** (MIT API). Then MusicBrainz + Cover Art Archive with correct rate limits and a User-Agent. Typed unsupported-operation errors; provider failure must never break local playback. Download→library integration with stable background sessions (BUG-08/09/10).

**Acceptance** Connect a Navidrome server, stream a track, download an album, and have it appear in the local library — with a provider-contract test suite.

---

## Phase 6 — Discovery and recommendations

**Objective** Make Taste DNA produce something a user can see and trust.

**Work** Explainable local ranking (genre/artist affinity, completion, skip penalty, recency, favourite bonus, diversity), recommendation explanations ("because you played X"), daily mixes, artist radio, testable ranking weights. Remote services only with explicit consent.

**Acceptance** Ranking tests assert ordering behaviour on synthetic histories; every recommendation surface can state why it appeared.

---

## Phase 7 — Premium UI and customization

**Objective** The design language does the work — but only after the data is real.

**Work** Complete the component library (`TrackRow`, `AlbumCard`, `ArtistCard`, `PlaylistCard`, `MiniPlayer`, `FullPlayer`, `QueueSheet`, `AudioQualityBadge`, `DownloadProgressView`, `SearchField`). Matched geometry for mini→full player. **Reduce Motion support (currently zero `accessibilityReduceMotion` uses in the repo).** Dynamic artwork gradients. Accessibility audit (labels exist in places — `astrixAccessible` — but are not systematic).

---

## Phase 8 — Ecosystem

Widgets (also unlocks the Live Activity, which currently has no extension target), App Intents/Siri, Spotlight indexing, CarPlay (requires Apple entitlement), sleep timer, keyboard navigation. Then macOS as a **real target** with its own menu bar and shortcuts.

---

## Phase 9 — Sync and social

Design conflict resolution *before* writing sync (last-writer-wins on whole documents is explicitly rejected; per-field with vector clocks or per-entity `updatedAt` + tombstones). Social listening last, and only over content the user legitimately controls — never third-party DRM streams.

---

## Deferred deliberately (with reasons)

| Item | Reason |
|---|---|
| `Qeloryx/` folder restructure | Fights both build systems; no user value. (§ above) |
| macOS app target | SPM declares macOS 14 but the app is iOS-only; `Platform` is iOS-centric. Phase 8. |
| Ogg/Opus support | AVFoundation can't decode them; needs a bundling + licensing decision. Until then, do not list them. (BUG-21) |
| Cloud sync | Nothing to sync until Phase 1 lands. |
| CloudKit/backend | No server exists; adding one before local correctness multiplies failure modes. |
| AI/"DJ" features | The prompt forbids fake AI. An explainable local ranker (Phase 6) comes first. |

---

## Standing rules for every phase

1. **Never** commit, push or merge — the repository owner does all Git operations. (Exception: this session's own branch, per Arena's branch policy, where changes are saved automatically.)
2. Never report a build as passing without a named CI run ID and conclusion.
3. Never report a feature as implemented without a file and line reference.
4. Every new engine/service/model requires a prior grep for an existing equivalent (`QueueEngine` vs `QueueController` is the cautionary example).
5. Every phase adds tests; every phase states its known limitations.
6. No new `@unchecked Sendable` without a written justification in the file. The repo currently has **43** and **zero** actors — the target is actors for shared mutable state, not more locks.
