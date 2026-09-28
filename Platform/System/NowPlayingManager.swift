// QELORYX — Platform
// NowPlayingManager.swift
// QEL-012 Player — Full Lock Screen + Remote Commands + AirPlay

import Foundation

#if canImport(MediaPlayer)
import MediaPlayer
#if canImport(UIKit)
import UIKit
#endif

public protocol NowPlayingCommandHandler: AnyObject {
    func handlePlay() -> MPRemoteCommandHandlerStatus
    func handlePause() -> MPRemoteCommandHandlerStatus
    func handleNext() -> MPRemoteCommandHandlerStatus
    func handlePrevious() -> MPRemoteCommandHandlerStatus
    func handleSeek(to time: TimeInterval) -> MPRemoteCommandHandlerStatus
    func handleTogglePlayPause() -> MPRemoteCommandHandlerStatus
}

public final class AstryxNowPlayingManager: @unchecked Sendable {
    
    public static let shared = AstryxNowPlayingManager()
    
    private var isConfigured = false
    private var commandHandler: NowPlayingCommandHandler?
    private let lock = NSLock()
    
    public init() {}
    
    public func configure(handler: NowPlayingCommandHandler? = nil) {
        lock.lock()
        defer { lock.unlock() }
        if let handler = handler { self.commandHandler = handler }
        guard !isConfigured else { return }
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.preferredIntervals = [15]
        commandCenter.skipBackwardCommand.preferredIntervals = [15]
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
        commandCenter.togglePlayPauseCommand.removeTarget(nil)
        commandCenter.nextTrackCommand.removeTarget(nil)
        commandCenter.previousTrackCommand.removeTarget(nil)
        commandCenter.changePlaybackPositionCommand.removeTarget(nil)
        commandCenter.skipForwardCommand.removeTarget(nil)
        commandCenter.skipBackwardCommand.removeTarget(nil)
        commandCenter.playCommand.addTarget { [weak self] _ in self?.commandHandler?.handlePlay() ?? .commandFailed }
        commandCenter.pauseCommand.addTarget { [weak self] _ in self?.commandHandler?.handlePause() ?? .commandFailed }
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in self?.commandHandler?.handleTogglePlayPause() ?? .commandFailed }
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in self?.commandHandler?.handleNext() ?? .commandFailed }
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in self?.commandHandler?.handlePrevious() ?? .commandFailed }
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            return self?.commandHandler?.handleSeek(to: event.positionTime) ?? .commandFailed
        }
        commandCenter.skipForwardCommand.addTarget { [weak self] _ in self?.commandHandler?.handleSeek(to: -1) ?? .commandFailed }
        commandCenter.skipBackwardCommand.addTarget { [weak self] _ in self?.commandHandler?.handleSeek(to: -2) ?? .commandFailed }
        isConfigured = true
    }
    
    public func configure(handler: AnyObject?) {
        if let h = handler as? NowPlayingCommandHandler { configure(handler: h) }
        else { configure(handler: nil as NowPlayingCommandHandler?) }
    }
    
    public func updateNowPlaying(track: AstryxTrack?, isPlaying: Bool, position: TimeInterval, duration: TimeInterval? = nil, artworkData: Data? = nil) {
        var info: [String: Any] = [:]
        if let track = track {
            info[MPMediaItemPropertyTitle] = track.title
            info[MPMediaItemPropertyArtist] = track.artist
            info[MPMediaItemPropertyAlbumTitle] = track.album
            info[MPMediaItemPropertyAlbumArtist] = track.albumArtist ?? track.artist
            info[MPMediaItemPropertyGenre] = track.genre ?? ""
            let dur = duration ?? track.duration
            info[MPMediaItemPropertyPlaybackDuration] = dur
            info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = position
            info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
            info[MPNowPlayingInfoPropertyDefaultPlaybackRate] = 1.0
            let artwork: Data? = artworkData ?? track.artworkData
            if let data = artwork, let image = UIImage(data: data) {
                info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            }
            info[MPNowPlayingInfoPropertyIsLiveStream] = false
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
    
    public func updatePlaybackState(isPlaying: Bool, position: TimeInterval) {
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = position
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
    
    public func clear() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
}

extension AstryxNowPlayingManager: NowPlayingManagerProtocol {}

#else

public protocol NowPlayingCommandHandler: AnyObject {
    func handlePlay() -> Int
    func handlePause() -> Int
    func handleNext() -> Int
    func handlePrevious() -> Int
    func handleSeek(to time: TimeInterval) -> Int
    func handleTogglePlayPause() -> Int
}

public final class AstryxNowPlayingManager: NowPlayingManagerProtocol, @unchecked Sendable {
    public static let shared = AstryxNowPlayingManager()
    public init() {}
    public func configure(handler: AnyObject?) {}
    public func configure(handler: NowPlayingCommandHandler? = nil) {}
    public func updateNowPlaying(track: AstryxTrack?, isPlaying: Bool, position: TimeInterval, duration: TimeInterval?, artworkData: Data?) {}
    public func updateNowPlaying(track: AstryxTrack?, isPlaying: Bool, position: TimeInterval, duration: TimeInterval? = nil, artworkData: Data? = nil) {}
    public func updatePlaybackState(isPlaying: Bool, position: TimeInterval) {}
    public func clear() {}
}

#endif
