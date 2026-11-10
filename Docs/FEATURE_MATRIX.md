# Qeloryx Feature Matrix & Build Roadmap

> North-star document for building the full Qeloryx experience. Every
> requested capability is mapped to its Qeloryx module, an implementation
> approach that respects upstream licenses, and a trackable status.
> Update the Status column as sprints land.

> ## Honesty note
>
> Statuses below describe **what the code does today**, not what is aspirational.
> "Code complete" means the logic exists and has unit tests; it does **not** mean
> device-verified. Anything requiring a physical iOS device or a macOS/Xcode run
> is marked unverified, because the remediation environment had no Swift toolchain.

## Principles

1. **Native, clean-room.** Qeloryx is Swift/SwiftUI. Popular third-party
   music apps referenced during research are overwhelmingly Kotlin/Flutter/
   TypeScript/Python; their *code* cannot compile here and copyleft licenses
   (GPL-3.0, restrictive EULAs) make copying it undesirable anyway. Features
   are reimplemented from public behavior specifications.
2. **Attribution where due.** Any file-level reuse of permissively licensed
   (MIT/BSD/MPL-2.0) Swift code keeps its copyright header and is recorded
   in `THIRD-PARTY-NOTICES.md`. GPL/EULA sources contribute *ideas only* —
   never code — and the resulting file notes its independent origin.
3. **Core stays Foundation-only.** Audio frameworks live exclusively behind
   adapter protocols in `Qeloryx/Platform/`. Everything testable stays testable.

## Source audit (verified)

| Referenced project | Language / platform | License | Verdict |
|---|---|---|---|
| Cassette (Subsonic client) | Swift/SwiftUI, iOS | MPL-2.0 | Architecture reference; file reuse allowed with headers + notices |
| AudioStreaming (dimitris-c) | Swift | MIT | Optional engine dependency; attribution required |
| LastWave-Native | Kotlin, Android | GPL-3.0 | Concepts only |
| BitChord | Kotlin, Android | GPL-3.0 | Concepts only |
| SpotiFLAC-Mobile | Flutter (Dart) + Go | MIT | Concepts only (language incompatible) |
| Arpeggi | SwiftUI | Closed source | Unusable |
| Harmonoid | Dart | Proprietary EULA | Do not read or reuse; ReplayGain is an open standard — implement from the public spec |
| Feishin | TypeScript, Electron | GPL-3.0 | Concepts only |
| Tauon Music Box | Python | GPL-3.0 | Concepts only |
| Navidrome | Go | GPL-3.0 | Concepts only |

## Sprint board

| # | Sprint | Ships | Origin of the ideas | Status |
|---|--------|-------|--------------------|--------|
| S1 | Seamless playback | Dual-deck gapless engine, equal-power/linear/s-curve crossfades (0–12 s), arming controller, `setCrossfade` command, hard-transition parity | Crossfade concept: BitChord (GPL — clean-room Swift implementation) | 🟡 Code complete, **unverified on hardware**. The crossfade value was previously unreachable from production (`SettingsRepository` now feeds it — BUG-06), but no device run has confirmed an audible fade. |
| S2 | Player surface | Now-playing gesture system, mini-player, artwork transition, bottom-sheet | Idea class: BitChord UI patterns — independently designed in Astryx design language | 🟡 Views exist and are wired through `AppDependencies`; gestures are unverified. |
| S3 | Lyrics | Millisecond synced lyrics on the LRC parser, karaoke line highlighting, per-provider failover | Concept: LastWave synced lyrics; parser already native (Qeloryx) | 🟡 LRC parser + karaoke UI exist. **No LRCLIB/remote provider** — offline only. |
| S4 | Download resilience | Resume ranges, retry with backoff, batch scheduling, progress aggregation | Concept: SpotiFLAC download UX; engine already native | 🟡 State machine, retry/backoff, persistence and atomic replace exist. Resume across relaunch is **unverified** (needs a device). |
| S5 | Smart search | Command palette, predicate builder, smart playlists, filter engine | Concept: Feishin | 🟡 Search index is real; there is **no command palette**. |
| S6 | Listening stats | Dashboard widgets, play-history aggregation, Taste DNA wiring | Concept: Tauon dashboard | 🟡 Counts are real; the dashboard previously displayed fabricated numbers (BUG-17). |
| S7 | Audio Lab | Spectrum visualizer, signal-path diagnostics, ReplayGain from the open spec | Concepts: Tauon/Harmonoid tool families (spec-based) | ❌ **Not real.** The spectrum is an illustrative animation (no FFT) and the signal path is a static illustration. EQ sliders now reach the shared DSP engine, but nothing is applied to the audio graph. |
| S8 | Discovery | Algorithmic daily mixes from Taste DNA, smart playlist generator | Concept: LastWave discovery | 🟡 Profile generation is real; it returns nothing for an empty library (no fabricated profiles). |

## S1 — Seamless playback (landed)

**What shipped**

- `Qeloryx/Services/Player/Transitions/CrossfadeCurve.swift` — fade curves
  (linear, equal-power with constant acoustic power, s-curve smoothstep)
  and the clamped `CrossfadeConfiguration` (0–12 s).
- `Qeloryx/Services/Player/Transitions/CrossfadeCapableAudioPlayer.swift` —
  optional adapter capability: `prepareNext` / `activatePreparedNext` /
  `cancelPreparedNext`. Non-conforming adapters keep hard transitions, so
  the feature is purely additive.
- `Qeloryx/Services/Player/Transitions/GaplessTransitionController.swift` —
  pure, deterministic arming logic (fade window, short-track guard,
  shuffle / repeat-one guards, queue wrap-around on repeat-all).
- `AstryxAudioEngine` — `.setCrossfade` command; the position timer arms
  the transition exactly once per track inside the fade window and commits
  a deck-swap that publishes the same events (`trackEnded(.natural)` →
  `trackStarted`) as a hard transition, so every downstream consumer
  (lyrics, library stats, UI) sees seamless behavior for free.
- `Qeloryx/Platform/Audio/GaplessAudioPlayerAdapter.swift` — dual-deck AVPlayer:
  standby deck pre-buffers at zero gain, a 30 Hz dispatch timer walks both
  decks through the curve, retiring-deck end notifications are suppressed,
  mid-fade pause completes the swap instantly, standby failure falls back
  to a hard transition. Wired as the app's default adapter.
- Tests (in `PlayerTests`, already CI-covered): curve boundary/constant-
  power/clamp math, configuration clamping, all seven arming guards,
  queue wrap-around, engine-level arm with a mocked crossfade adapter,
  and the disabled-by-default parity guarantee.

**Acceptance**

- [x] Crossfade disabled by default; zero behavior change unless enabled
- [x] Fade commits exactly once per track (armed-once guard)
- [x] Queue events identical to hard transitions
- [x] All new logic covered by unit tests in `PlayerTests`
- [ ] **CI has not run green on this branch yet** — the SPM test step was red
      before the remediation (`AstryxAudioEngineTests`), so no test claim here
      has been observed passing.
- [ ] Device verification of audible fade quality (manual, on hardware)

## Cross-sprint invariants

- Every sprint keeps `swift build` + the full CI matrix green.
- Every sprint lands with tests inside the existing per-class CI steps.
- New third-party files (if any) update `THIRD-PARTY-NOTICES.md` in the
  same commit.
