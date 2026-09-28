# ADR-006: Astryx Player Architecture — QEL-012

**Date:** 2026-09-28
**Status:** Accepted
**Milestone:** 0.1.0-alpha.1 — First Alpha (Player)
**Tags:** player, avfoundation, background, now-playing, live-activity, airplay

## Context
Foundation milestone established greenfield architecture with placeholder playback. Now we need production-grade player that satisfies Genesis Bible requirements.

## Decision

### 1. AVFoundationAdapter as Platform Isolation
- Only place where AVFoundation imported
- Owns AVPlayer, AVPlayerItem, periodic time observer, KVO for status, end observer
- Delegate pattern for events: didFinish, didFail, timeUpdate, statusChange
- Fallback for Linux sandbox (simulated playback for CI)

**Why not AVQueuePlayer?**
AVQueuePlayer manages queue internally but gives less control for shuffle/repeat/custom queue logic. We keep custom QueueController as source of truth, AVPlayer is single-item player.

### 2. AudioSessionManager — Real AVAudioSession
- Category: .playback with options: allowAirPlay, allowBluetooth, allowBluetoothA2DP
- Observes interruptionNotification and routeChangeNotification
- Publishes via EventBus: audioSessionInterrupted

### 3. NowPlayingManager — Lock Screen + Control Center
- Isolates MediaPlayer framework
- MPNowPlayingInfoCenter for title/artist/album/artwork/duration/position/rate
- MPRemoteCommandCenter for play/pause/next/prev/seek/skipForward/skipBackward/togglePlayPause
- Command handler protocol injected from Engine

### 4. LiveActivityManager — Dynamic Island
- Isolates ActivityKit
- Attributes: trackID, ContentState: title/artist/album/artwork/isPlaying/position/duration
- Started on trackStarted, updated on position/playbackState changes, ended on stop

### 5. AstryxAudioEngine — Enhanced Coordinator
- Owns AVFoundationAdapter, delegates to it
- QueueController remains source of truth for queue
- Unified playback state with NSLock protection
- Position timer (0.5s) that reads avAdapter.currentTime() or simulates
- Preload next track placeholder for crossfade-ready architecture
- Haptic feedback via HapticEngine on play/pause/next/prev/shuffle/repeat
- Handles interruptions via EventBus subscription
- Remote commands via NowPlayingManager

### 6. Player UI — Premium with Midnight Aurora
- AstryxPlayerView: full-screen with blurred artwork background, artwork transition (scale + opacity), track info with lossless indicator, seek bar, main controls, secondary controls, up next horizontal
- AstryxQueueView: list of queue items with current indicator
- EnhancedMiniPlayer: artwork transition, progress bar, lossless indicator

## Consequences
Positive: Real AVFoundation playback with background, Lock Screen, Dynamic Island, AirPlay, smooth artwork transitions, haptic feedback, crossfade-ready, clean separation, testable
Negative: More complexity, ActivityKit requires iOS 16.1+ with fallback

## Implementation
Files: AVFoundationAdapter, AudioSessionManager, NowPlayingManager, LiveActivityManager, AstryxAudioEngine, PlayerViewModel, PlayerView, QueueView, RootView, QeloryxApp

---
*QELORYX — Astryx Player*
