// QELORYX — Platform
// NowPlayingManager.swift
// Isolates MediaPlayer framework

import Foundation
#if canImport(MediaPlayer)
import MediaPlayer
#if canImport(UIKit)
import UIKit
#endif

public final class AstryxNowPlayingManager: @unchecked Sendable {
    
    public static let shared = AstryxNowPlayingManager()
    
    private var isConfigured = false
    
    public init() {}
    
    public func configure() {
        guard !isConfigured else { return }
        
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.isEnabled = true
        
        isConfigured = true
    }
    
    public func updateNowPlaying(track: AstryxTrack?, isPlaying: Bool, position: TimeInterval) {
        var info: [String: Any] = [:]
        
        if let track = track {
            info[MPMediaItemPropertyTitle] = track.title
            info[MPMediaItemPropertyArtist] = track.artist
            info[MPMediaItemPropertyAlbumTitle] = track.album
            info[MPMediaItemPropertyPlaybackDuration] = track.duration
            info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = position
            info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
            
            if let data = track.artworkData, let image = UIImage(data: data) {
                info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            }
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
    
    public func clear() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
}

#else

public final class AstryxNowPlayingManager: @unchecked Sendable {
    public static let shared = AstryxNowPlayingManager()
    public init() {}
    public func configure() {}
    public func updateNowPlaying(track: AstryxTrack?, isPlaying: Bool, position: TimeInterval) {}
    public func clear() {}
}

#endif
