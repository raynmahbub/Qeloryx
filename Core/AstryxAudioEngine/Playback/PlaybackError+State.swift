// QELORYX — AstryxAudioEngine
// PlaybackError+State.swift
//
// Small extension so transport methods can signal "I have already transitioned
// the engine into `.failed`" without duplicating the failure handling.
// The engine is still the only owner of playback state.

import Foundation

extension PlaybackError {
    /// Wraps the engine state that was already published for this failure so a
    /// caller's `catch` does not transition the engine a second time.
    static func failedState(_ state: AstryxPlaybackState) -> PlaybackError {
        if case .failed(_, let message) = state {
            return .loadFailed(trackID: state.currentTrackID ?? "", reason: message)
        }
        return .nothingToResume
    }
}
