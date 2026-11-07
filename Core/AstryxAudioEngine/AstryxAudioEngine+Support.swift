// QELORYX — AstryxAudioEngine
// AstryxAudioEngine+Support.swift
//
// Play-count bookkeeping, failure reporting and event snapshots. Split out of
// `AstryxAudioEngine.swift` to keep the type inside the 400-line
// `type_body_length` limit; no behaviour moved.

import Foundation

extension AstryxAudioEngine {

    // MARK: - Play counts

    /// Records a play once the listener has meaningfully engaged with a track.
    /// Counting on `startPlayback` alone inflated statistics for instant skips
    /// (BUG-20); the position clock calls this when the threshold is crossed.
    func recordPlay(trackID: String) async {
        guard let libraryEngine else { return }
        do {
            try await libraryEngine.recordPlay(trackID: trackID)
        } catch {
            publishError(error, context: "recordPlay(\(trackID))")
        }
    }

    // MARK: - Failures

    /// Transitions to `.failed`, publishes the event and stops the clock.
    /// Returns the state for callers that rethrow.
    @discardableResult
    func fail(trackID: String?, error: Error) -> AstryxPlaybackState {
        stopPositionTimer()
        let state = setState(.failed(trackID: trackID, error: error.localizedDescription))
        eventBus.publish(.playbackStateChanged(state: snapshot(from: state)))
        if let trackID {
            eventBus.publish(.trackEnded(trackID: trackID, reason: .error))
        }
        return state
    }

    /// Replaces the queue only — no adapter load, no transport, no events that
    /// would make a UI think playback started.
    public func restoreQueue(trackIDs: [String], startIndex: Int) async {
        guard !trackIDs.isEmpty else { return }
        await queueController.setQueue(
            trackIDs: trackIDs,
            startIndex: min(max(startIndex, 0), trackIDs.count - 1),
            source: .history
        )
    }

    /// Restores a queue position without loading audio or starting playback.
    /// Used by `PlaybackRestorer` so a relaunch never begins making noise.
    public func restorePausedState(trackID: String, position: TimeInterval) {
        // Duration is resolved lazily by the player view model from the
        // library; a restored queue must not block launch on metadata reads.
        let state = setState(.paused(trackID: trackID, position: position, duration: 0))
        eventBus.publish(.playbackStateChanged(state: snapshot(from: state)))
    }

    func publishError(_ error: Error, context: String) {
        #if DEBUG
        debugPrint("[AstryxAudioEngine] \(context) failed: \(error)")
        #endif
    }

    // MARK: - Snapshot

    func snapshot(from state: AstryxPlaybackState) -> PlaybackStateSnapshot {
        let queue = currentQueue
        let queueVersion = queue.version
        let shuffleEnabled = queue.shuffleEnabled
        let repeatMode = mapRepeatMode(queue.repeatMode)
        switch state {
        case .idle, .stopped, .failed:
            return PlaybackStateSnapshot(
                trackID: state.currentTrackID,
                isPlaying: false,
                position: 0,
                duration: 0,
                queueVersion: queueVersion,
                shuffleEnabled: shuffleEnabled,
                repeatMode: repeatMode
            )
        case .loading(let id):
            return PlaybackStateSnapshot(
                trackID: id,
                isPlaying: false,
                position: 0,
                duration: 0,
                queueVersion: queueVersion,
                shuffleEnabled: shuffleEnabled,
                repeatMode: repeatMode
            )
        case .playing(let id, let pos, let dur):
            return PlaybackStateSnapshot(
                trackID: id,
                isPlaying: true,
                position: pos,
                duration: dur,
                queueVersion: queueVersion,
                shuffleEnabled: shuffleEnabled,
                repeatMode: repeatMode
            )
        case .paused(let id, let pos, let dur):
            return PlaybackStateSnapshot(
                trackID: id,
                isPlaying: false,
                position: pos,
                duration: dur,
                queueVersion: queueVersion,
                shuffleEnabled: shuffleEnabled,
                repeatMode: repeatMode
            )
        }
    }

    func publishState() {
        eventBus.publish(.playbackStateChanged(state: snapshot(from: playbackState)))
    }

    func mapRepeatMode(_ mode: AstryxRepeatMode) -> RepeatModeSnapshot {
        switch mode {
        case .off: return .off
        case .all: return .all
        case .one: return .one
        }
    }

}
