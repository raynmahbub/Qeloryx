// QELORYX — AstryxAudioEngine
// CrossfadeCapableAudioPlayer.swift
// Sprint "Seamless Playback" — optional adapter capability for dual-deck
// players. The engine casts to this protocol; adapters that lack it keep
// the classic hard-transition behavior, so gapless playback is purely
// additive.

import Foundation

// MARK: - Crossfade-Capable Adapter

public protocol CrossfadeCapableAudioPlayer: AudioPlayerAdapterProtocol {
    /// Whether a next-track deck is currently staged.
    var hasPreparedNext: Bool { get }
    /// Stages the next track on the idle deck, pre-buffered at zero gain,
    /// without disturbing the playing deck.
    func prepareNext(url: URL) throws
    /// Starts the staged track and runs the gain ramps: outgoing deck fades
    /// down, incoming deck fades up, over `fadeDuration` using `curve`.
    /// When the ramp completes, the idle-deck roles swap.
    func activatePreparedNext(fadeDuration: TimeInterval, curve: CrossfadeCurve)
    /// Discards the staged track (seek, pause, new queue, or user skip).
    func cancelPreparedNext()
}
