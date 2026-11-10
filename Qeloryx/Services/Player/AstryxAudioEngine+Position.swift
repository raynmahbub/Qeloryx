// QELORYX — Services/Player
// AstryxAudioEngine+Position.swift
//
// The position clock. BUG-03: it must never invent progress. A position only
// advances while the adapter reports that it is actually playing; otherwise it
// freezes. A track that never played cannot roll over into the next one.

import Foundation

extension AstryxAudioEngine {

    func startPositionTimer() {
        stopPositionTimer()
        // Tolerance keeps the timer cheap and avoids wake-up storms during
        // long background playback.
        let timer = Timer.scheduledTimer(
            withTimeInterval: Self.positionTickInterval,
            repeats: true
        ) { [weak self] _ in
            self?.positionTick()
        }
        timer.tolerance = 0.1
        positionTimer = timer
    }

    func stopPositionTimer() {
        positionTimer?.invalidate()
        positionTimer = nil
    }

    /// Extracted so tests can exercise the tick without waiting on a timer.
    func positionTick() {
        // The adapter is the only source of truth for progress.
        let adapterTime = avAdapter.currentTime()
        let adapterIsPlaying = avAdapter.isPlaying()

        guard adapterIsPlaying else {
            // Freeze: publish nothing, advance nothing.
            return
        }

        let queue = currentQueue
        let state = playbackState
        guard case .playing(let trackID, _, let duration) = state else { return }

        // Only the adapter may advance the clock. If it reports 0 (asset not
        // started, buffering) we hold the last known position rather than
        // inventing `+0.5s` per tick, which made the bar crawl over silence
        // (BUG-03).
        let position: TimeInterval
        if adapterTime.isFinite && adapterTime > 0 {
            position = adapterTime
        } else {
            position = max(state.position, 0)
        }

        // Crossfade arming: only once per track, and only when the queue can
        // actually supply the next item.
        if transitionArmedTrackID != trackID,
           crossfadeConfiguration.isEnabled,
           avAdapter is any CrossfadeCapableAudioPlayer {
            let decision = transitionController.evaluate(
                position: position,
                duration: duration,
                configuration: crossfadeConfiguration,
                queue: queue
            )
            if decision.shouldCrossfade {
                transitionArmedTrackID = trackID
                Task { await self.performCrossfade(fromTrackID: trackID) }
                return
            }
        }

        if duration > 0 && position >= duration {
            Task { try? await self.next() }
            return
        }

        let updated = setState(.playing(trackID: trackID, position: position, duration: duration))
        eventBus.publish(.playbackStateChanged(state: snapshot(from: updated)))

        // Keep system surfaces in step at 1 Hz instead of every tick.
        let second = Int(position)
        if second != lastNowPlayingSecond {
            lastNowPlayingSecond = second
            nowPlayingManager.updatePlaybackState(isPlaying: true, position: position)
            liveActivityManager.updateLiveActivity(
                track: currentTrackCache,
                isPlaying: true,
                position: position,
                duration: duration
            )
        }

        maybeRecordPlay(trackID: trackID, position: position, duration: duration)
    }

    /// Counts a play once 50% (min 30 s) has been heard, at most once per track
    /// per playback session. Replaces the old "count on start" behaviour.
    private func maybeRecordPlay(trackID: String, position: TimeInterval, duration: TimeInterval) {
        guard playRecordedTrackID != trackID else { return }
        let heard = duration > 0 ? min(position / duration, 1) : 0
        let qualifies = duration > 0 ? (heard >= 0.5 || position >= 30) : position >= 30
        guard qualifies else { return }
        playRecordedTrackID = trackID
        Task { await self.recordPlay(trackID: trackID) }
    }
}
