// QELORYX — AstryxAudioEngine
// PlaybackCommand.swift

import Foundation

public enum AstryxPlaybackCommand: Sendable, Equatable {
    case play(trackID: String? = nil) // nil = resume current
    case pause
    case togglePlayPause
    case stop
    case seek(to: TimeInterval)
    case seekForward(interval: TimeInterval = 15)
    case seekBackward(interval: TimeInterval = 15)
    case next
    case previous
    case playQueue(queue: [String], startIndex: Int = 0)
    case setShuffle(_ enabled: Bool)
    case setRepeat(_ mode: AstryxRepeatMode)
    case setVolume(_ volume: Float)
    /// Enables or tunes gapless crossfades. `.disabled` (duration ≤ 0)
    /// restores the classic hard transition. Requires an adapter that
    /// conforms to `CrossfadeCapableAudioPlayer`; otherwise this is a no-op.
    case setCrossfade(_ configuration: CrossfadeConfiguration)
}
