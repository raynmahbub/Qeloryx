// QELORYX — Platform
// AVFoundationAdapter.swift
// Isolates AVFoundation — only place where AVFoundation is imported per architecture rules

import Foundation
#if canImport(AVFoundation)
import AVFoundation

public final class AVFoundationAdapter: @unchecked Sendable {
    
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    
    public init() {}
    
    public func load(url: URL) throws {
        let asset = AVAsset(url: url)
        playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)
    }
    
    public func play() {
        player?.play()
    }
    
    public func pause() {
        player?.pause()
    }
    
    public func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 1000)
        player?.seek(to: cmTime)
    }
    
    public func setVolume(_ volume: Float) {
        player?.volume = volume
    }
    
    public func currentTime() -> TimeInterval {
        player?.currentTime().seconds ?? 0
    }
    
    public func duration() -> TimeInterval {
        playerItem?.asset.duration.seconds ?? 0
    }
    
    public func addPeriodicObserver(interval: TimeInterval, handler: @escaping (TimeInterval) -> Void) {
        let cmInterval = CMTime(seconds: interval, preferredTimescale: 1000)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: cmInterval, queue: .main) { time in
            handler(time.seconds)
        }
    }
    
    public func removeObserver() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
    }
    
    deinit {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
    }
}

#else

// Fallback for non-Apple platforms / Linux sandbox
public final class AVFoundationAdapter {
    public init() {}
    public func load(url: URL) throws {}
    public func play() {}
    public func pause() {}
    public func seek(to time: TimeInterval) {}
    public func setVolume(_ volume: Float) {}
    public func currentTime() -> TimeInterval { 0 }
    public func duration() -> TimeInterval { 0 }
    public func addPeriodicObserver(interval: TimeInterval, handler: @escaping (TimeInterval) -> Void) {}
    public func removeObserver() {}
}

#endif
