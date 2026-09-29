# IL-009 — Seamless Playback (Gapless Engine & Crossfades)

Sprint S1 of `Docs/FEATURE_MATRIX.md`. First-party clean-room work; see
`THIRD-PARTY-NOTICES.md` for the reuse policy this sprint operated under.
The dual-curve-crossfade interaction pattern is a well-known music-player
behavior class (popularized among third-party clients by apps such as
BitChord); no third-party source was read or reused — the implementation
was designed from the acoustic requirement (constant-power overlap) and
the repository's existing adapter protocol.

## Decisions

- **Optional capability, not a new engine.** `CrossfadeCapableAudioPlayer`
  extends `AudioPlayerAdapterProtocol`; `AstryxAudioEngine` arms fades only
  when its adapter conforms. `FallbackAudioPlayerAdapter` therefore keeps
  every pre-existing test on hard-transition semantics untouched, and
  crossfade is disabled by default (`CrossfadeConfiguration.disabled`).
- **Decision purity.** `GaplessTransitionController` is a stateless value
  type with seven explicit deny/allow reasons; the position timer asks it
  once per tick, guarded by `transitionArmedTrackID` so a track fades
  exactly once. All edge rules (fade window, short-track, shuffle,
  repeat-one, wrap-around, NaN/end timing) are unitpinned.
- **Event parity.** A committed crossfade publishes
  `trackEnded(reason: .natural)` then `trackStarted` then
  `playbackStateChanged` — identical to the hard `next()` path — so
  lyrics sync, scrobbling counters, and UI need no special cases.
- **Dual decks in Platform.** `GaplessAudioPlayerAdapter` owns two
  `AVPlayer` instances behind the same protocol; volume ramps run on a
  dispatch timer (no run-loop dependency from engine tasks), the retiring
  deck's `AVPlayerItemDidPlayToEndTime` is swallowed inside the fade
  window, a mid-fade pause fast-forwards the swap, and a failed standby
  deck degrades to a hard transition instead of failing playback.
- **Wired by default.** `QeloryxApp` composes `GaplessAudioPlayerAdapter`;
  with crossfades disabled its behavior is byte-for-byte the classic
  single-deck path.

## Files

- `Core/AstryxAudioEngine/Transitions/{CrossfadeCurve,CrossfadeCapableAudioPlayer,GaplessTransitionController}.swift`
- `Core/AstryxAudioEngine/{AstryxAudioEngine,Playback/PlaybackCommand}.swift` (additive)
- `Platform/Audio/GaplessAudioPlayerAdapter.swift`
- `App/QeloryxApp.swift` (composition)
- `Tests/CoreTests/PlayerTests.swift` (curve math, arming guards, engine arm, parity)

## Manual verification still owed

- Audible crossfade quality on device (curve choice, 30 Hz ramp smoothness)
- AirPlay target switch during an in-flight fade
- Crossfade across the repeat-all queue boundary on hardware
