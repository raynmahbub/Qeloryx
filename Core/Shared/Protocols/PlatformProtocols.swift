// QELORYX — Core
// PlatformProtocols.swift
// QEL-012 — Protocols for Platform adapters to keep Core independent per clean architecture

import Foundation

// MARK: - Haptic Type (Core)

public enum HapticType: Sendable {
    case light
    case medium
    case heavy
    case selection
    case success
    case warning
    case error
}

// MARK: - AVFoundation Adapter Delegate

public protocol AVFoundationAdapterDelegate: AnyObject {
    func adapterDidFinishPlaying()
    func adapterDidFail(error: Error)
    func adapterTimeDidUpdate(time: TimeInterval)
    func adapterDidChangeStatus(isReady: Bool)
}

// MARK: - Audio Player Adapter Protocol

public protocol AudioPlayerAdapterProtocol: AnyObject, Sendable {
    var delegate: AVFoundationAdapterDelegate? { get set }
    
    func load(url: URL) throws
    func load(track: AstryxTrack) throws
    func play()
    func pause()
    func stop()
    func seek(to time: TimeInterval, completion: ((Bool) -> Void)?)
    func setVolume(_ volume: Float)
    func setRate(_ rate: Float)
    func currentTime() -> TimeInterval
    func duration() -> TimeInterval
    func isPlaying() -> Bool
    
    var isAirPlayActive: Bool { get }
    var allowsExternalPlayback: Bool { get set }
}

// MARK: - Now Playing Protocol

public protocol NowPlayingManagerProtocol: AnyObject, Sendable {
    func configure(handler: AnyObject?)
    func updateNowPlaying(track: AstryxTrack?, isPlaying: Bool, position: TimeInterval, duration: TimeInterval?, artworkData: Data?)
    func updatePlaybackState(isPlaying: Bool, position: TimeInterval)
    func clear()
}

// MARK: - Live Activity Protocol

public protocol LiveActivityManagerProtocol: AnyObject, Sendable {
    func startLiveActivity(track: AstryxTrack, isPlaying: Bool, position: TimeInterval)
    func updateLiveActivity(track: AstryxTrack?, isPlaying: Bool, position: TimeInterval, duration: TimeInterval?)
    func endLiveActivity()
}

// MARK: - Haptic Protocol

public protocol HapticEngineProtocol: AnyObject, Sendable {
    func trigger(_ type: HapticType)
    func triggerPlay()
    func triggerPause()
    func triggerFavorite()
}

// MARK: - Fallback Implementations for Core-only builds (Linux/SPM without Platform)

public final class FallbackAudioPlayerAdapter: AudioPlayerAdapterProtocol, @unchecked Sendable {
    public weak var delegate: AVFoundationAdapterDelegate?
    public init() {}
    public func load(url: URL) throws {}
    public func load(track: AstryxTrack) throws {}
    public func play() {}
    public func pause() {}
    public func stop() {}
    public func seek(to time: TimeInterval, completion: ((Bool) -> Void)?) { completion?(true) }
    public func setVolume(_ volume: Float) {}
    public func setRate(_ rate: Float) {}
    public func currentTime() -> TimeInterval { 0 }
    public func duration() -> TimeInterval { 180 }
    public func isPlaying() -> Bool { false }
    public var isAirPlayActive: Bool { false }
    public var allowsExternalPlayback: Bool {
        get { true }
        set {}
    }
}

public final class FallbackNowPlayingManager: NowPlayingManagerProtocol, @unchecked Sendable {
    public init() {}
    public func configure(handler: AnyObject?) {}
    public func updateNowPlaying(track: AstryxTrack?, isPlaying: Bool, position: TimeInterval, duration: TimeInterval?, artworkData: Data?) {}
    public func updatePlaybackState(isPlaying: Bool, position: TimeInterval) {}
    public func clear() {}
}

public final class FallbackLiveActivityManager: LiveActivityManagerProtocol, @unchecked Sendable {
    public init() {}
    public func startLiveActivity(track: AstryxTrack, isPlaying: Bool, position: TimeInterval) {}
    public func updateLiveActivity(track: AstryxTrack?, isPlaying: Bool, position: TimeInterval, duration: TimeInterval?) {}
    public func endLiveActivity() {}
}

public final class FallbackHapticEngine: HapticEngineProtocol, @unchecked Sendable {
    public init() {}
    public func trigger(_ type: HapticType) {}
    public func triggerPlay() {}
    public func triggerPause() {}
    public func triggerFavorite() {}
}
