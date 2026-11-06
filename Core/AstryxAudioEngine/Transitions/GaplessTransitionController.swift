// QELORYX — AstryxAudioEngine
// GaplessTransitionController.swift
// Sprint "Seamless Playback" — pure decision logic for when a crossfade may
// be armed. Deterministic and fully unit-testable: no timers, no audio
// objects, just queue + timing in, decision out.

import Foundation

// MARK: - Gapless Transition Controller

public struct GaplessTransitionController: Sendable {

    public struct Decision: Sendable, Equatable {
        public var shouldCrossfade: Bool
        public var reason: Reason

        public enum Reason: String, Sendable, Equatable {
            /// Fade window reached — crossfade should start now.
            case armed
            /// Still earlier than (duration - fadeDuration).
            case outsideFadeWindow
            /// Configuration disabled.
            case crossfadeDisabled
            /// Track shorter than 1.5x the fade — fading would dominate it.
            case trackTooShort
            /// With shuffle the true next track is resolved at advance time,
            /// so a deck cannot be pre-staged safely.
            case shuffledQueueUnsupported
            /// Repeat-one restarts the same file; fading is pointless.
            case repeatOneUnsupported
            /// No upcoming queue item to fade into.
            case noNextItem
            /// Non-finite or non-positive timing values.
            case invalidTiming
        }
    }

    /// A track must outlast the fade by at least this factor, otherwise the
    /// overlap would cover nearly the whole song.
    public static let minimumTrackLengthFactor: Double = 1.5

    public init() {}

    public func evaluate(
        position: TimeInterval,
        duration: TimeInterval,
        configuration: CrossfadeConfiguration,
        queue: AstryxQueue
    ) -> Decision {
        func deny(_ reason: Decision.Reason) -> Decision {
            Decision(shouldCrossfade: false, reason: reason)
        }
        guard configuration.isEnabled else { return deny(.crossfadeDisabled) }
        guard position.isFinite, duration.isFinite, position > 0, duration > 0 else { return deny(.invalidTiming) }
        guard !queue.shuffleEnabled else { return deny(.shuffledQueueUnsupported) }
        guard queue.repeatMode != .one else { return deny(.repeatOneUnsupported) }
        let minimumViableLength = configuration.duration * GaplessTransitionController.minimumTrackLengthFactor
        guard duration > minimumViableLength else { return deny(.trackTooShort) }
        guard queue.nextItem != nil else { return deny(.noNextItem) }
        let remaining = duration - position
        guard remaining <= configuration.duration else { return deny(.outsideFadeWindow) }
        return Decision(shouldCrossfade: true, reason: .armed)
    }
}
