// QELORYX — Services/Player
// AstryxAudioEngine+Actions.swift
//
// Transport actions that move between tracks, plus the crossfade commit.
// BUG-11: repeat-one seeks to zero instead of reloading the file.

import Foundation

extension AstryxAudioEngine {

    func playQueue(trackIDs: [String], startIndex: Int) async throws {
        guard !trackIDs.isEmpty else { throw PlaybackError.nothingToResume }
        let safeIndex = min(max(0, startIndex), trackIDs.count - 1)
        await queueController.setQueue(trackIDs: trackIDs, startIndex: safeIndex, source: .manual)
        try await startPlayback(trackID: trackIDs[safeIndex])
    }

    func next() async throws {
        hapticEngine.trigger(.light)

        // Repeat-one must loop the current file, not re-load it. Re-loading
        // creates an audible gap and re-runs every side effect (now playing,
        // live activity, play counting) for the same track.
        if currentQueue.repeatMode == .one, let current = currentQueue.currentItem {
            try await seek(to: 0)
            _ = current
            return
        }

        guard let nextItem = await queueController.next() else {
            let lastTrackID = playbackState.currentTrackID
            try await stop()
            if let lastTrackID {
                eventBus.publish(.trackEnded(trackID: lastTrackID, reason: .queueEnded))
            }
            return
        }

        // A track change is an explicit user/system action, so the play counter
        // resets for the new track.
        playRecordedTrackID = nil
        try await startPlayback(trackID: nextItem.trackID)
    }

    func previous() async throws {
        hapticEngine.trigger(.light)

        if playbackState.position > 3 {
            try await seek(to: 0)
            return
        }

        if let prevItem = await queueController.previous() {
            playRecordedTrackID = nil
            try await startPlayback(trackID: prevItem.trackID)
        } else {
            try await seek(to: 0)
        }
    }

    /// Executes a committed crossfade: advances the queue, stages the next
    /// track on the adapter's idle deck, and swaps decks over the configured
    /// fade. Any staging failure disarms the transition so the incoming
    /// natural track-end drives the classic hard `next()` instead.
    func performCrossfade(fromTrackID: String) async {
        guard let crossfader = avAdapter as? any CrossfadeCapableAudioPlayer else {
            transitionArmedTrackID = nil
            return
        }
        guard crossfadeConfiguration.isEnabled else {
            transitionArmedTrackID = nil
            return
        }
        guard let nextItem = await queueController.next() else {
            transitionArmedTrackID = nil
            return
        }
        guard let resolver = sourceResolver,
              let source = await resolver.resolvePlaybackSource(trackID: nextItem.trackID) else {
            // No source: let the natural end fall back to the hard transition,
            // which will surface a typed failure instead of silence.
            transitionArmedTrackID = nil
            // The queue already advanced; put it back so `next()` is consistent.
            await restoreCurrentIndex(to: fromTrackID)
            return
        }

        do {
            try crossfader.prepareNext(url: source.url)
        } catch {
            transitionArmedTrackID = nil
            await restoreCurrentIndex(to: fromTrackID)
            return
        }

        crossfader.activatePreparedNext(
            fadeDuration: crossfadeConfiguration.duration,
            curve: crossfadeConfiguration.curve
        )

        currentTrackCache = source.track
        playRecordedTrackID = nil
        let duration = source.track.duration > 0 ? source.track.duration : avAdapter.duration()
        let state = setState(.playing(trackID: nextItem.trackID, position: 0, duration: duration))

        hapticEngine.trigger(.selection)
        nowPlayingManager.updateNowPlaying(
            track: source.track,
            isPlaying: true,
            position: 0,
            duration: duration,
            artworkData: source.track.artworkData
        )
        liveActivityManager.updateLiveActivity(
            track: source.track,
            isPlaying: true,
            position: 0,
            duration: duration
        )

        let queueID = currentQueue.id
        eventBus.publish(.trackEnded(trackID: fromTrackID, reason: .natural))
        eventBus.publish(.trackStarted(trackID: nextItem.trackID, queueID: queueID))
        eventBus.publish(.playbackStateChanged(state: snapshot(from: state)))
        startPositionTimer()
    }

    /// Puts the queue back on `trackID` after a failed pre-stage.
    private func restoreCurrentIndex(to trackID: String) async {
        let queue = currentQueue
        if let index = queue.items.firstIndex(where: { $0.trackID == trackID }) {
            await queueController.setCurrentIndex(index)
        }
    }
}
