// QELORYX — Platform
// AVFoundationAdapter.swift
// QEL-012 Player Milestone — Production AVFoundation implementation
// Isolates AVFoundation — only place where AVFoundation is imported per architecture rules

#if canImport(QeloryxCore)
import QeloryxCore
#endif

import Foundation

#if canImport(AVFoundation)
import AVFoundation

// MARK: - AVFoundationAdapter

public final class AVFoundationAdapter: AudioPlayerAdapterProtocol, @unchecked Sendable {
    
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    private var statusObserver: NSKeyValueObservation?
    private var endObserver: NSObjectProtocol?
    
    public weak var delegate: AVFoundationAdapterDelegate?
    
    private let lock = NSLock()
    
    public init() {}
    
    public func load(url: URL) throws {
        lock.lock()
        defer { lock.unlock() }
        cleanup()
        let asset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)
        player?.automaticallyWaitsToMinimizeStalling = false
        player?.actionAtItemEnd = .pause
        observePlayerItem()
        observeEnd()
        addPeriodicObserver()
    }
    
    public func load(track: AstryxTrack) throws {
        try load(url: track.fileURL)
    }
    
    public func play() {
        lock.lock()
        let p = player
        lock.unlock()
        p?.play()
    }
    
    public func pause() {
        lock.lock()
        let p = player
        lock.unlock()
        p?.pause()
    }
    
    public func stop() {
        lock.lock()
        let p = player
        lock.unlock()
        p?.pause()
        p?.seek(to: .zero)
        cleanup()
    }
    
    public func seek(to time: TimeInterval, completion: ((Bool) -> Void)? = nil) {
        lock.lock()
        let p = player
        lock.unlock()
        let cmTime = CMTime(seconds: time, preferredTimescale: 1000)
        p?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero) { finished in
            completion?(finished)
        }
    }
    
    public func setVolume(_ volume: Float) {
        lock.lock()
        let p = player
        lock.unlock()
        p?.volume = max(0, min(1, volume))
    }
    
    public func setRate(_ rate: Float) {
        lock.lock()
        let p = player
        lock.unlock()
        p?.rate = rate
    }
    
    public func currentTime() -> TimeInterval {
        lock.lock()
        let p = player
        lock.unlock()
        return p?.currentTime().seconds ?? 0
    }
    
    public func duration() -> TimeInterval {
        lock.lock()
        let item = playerItem
        lock.unlock()
        guard let item = item else { return 0 }
        let duration = item.asset.duration
        if duration.isIndefinite || duration.seconds.isNaN {
            return item.duration.seconds.isNaN ? 0 : item.duration.seconds
        }
        return duration.seconds
    }
    
    public func isPlaying() -> Bool {
        lock.lock()
        let p = player
        lock.unlock()
        return p?.rate != 0 && p?.error == nil
    }
    
    private func observePlayerItem() {
        statusObserver = playerItem?.observe(\.status, options: [.new, .initial]) { [weak self] item, _ in
            let isReady = item.status == .readyToPlay
            DispatchQueue.main.async {
                self?.delegate?.adapterDidChangeStatus(isReady: isReady)
            }
            if item.status == .failed, let error = item.error {
                DispatchQueue.main.async {
                    self?.delegate?.adapterDidFail(error: error)
                }
            }
        }
    }
    
    private func observeEnd() {
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            self?.delegate?.adapterDidFinishPlaying()
        }
    }
    
    private func addPeriodicObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: 1000)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.delegate?.adapterTimeDidUpdate(time: time.seconds)
        }
    }
    
    private func cleanup() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        statusObserver?.invalidate()
        statusObserver = nil
        if let endObserver = endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
        playerItem = nil
        player = nil
    }
    
    deinit { cleanup() }
}

extension AVFoundationAdapter {
    public var isAirPlayActive: Bool {
        #if canImport(UIKit)
        let session = AVAudioSession.sharedInstance()
        let outputs = session.currentRoute.outputs
        return outputs.contains { $0.portType == .airPlay }
        #else
        return false
        #endif
    }
    public var allowsExternalPlayback: Bool {
        get { player?.allowsExternalPlayback ?? true }
        set { player?.allowsExternalPlayback = newValue }
    }
    #if canImport(UIKit)
    public var usesExternalPlaybackWhileExternalScreenIsActive: Bool {
        get { player?.usesExternalPlaybackWhileExternalScreenIsActive ?? false }
        set { player?.usesExternalPlaybackWhileExternalScreenIsActive = newValue }
    }
    #else
    public var usesExternalPlaybackWhileExternalScreenIsActive: Bool {
        get { false }
        set {}
    }
    #endif
}

#else

public final class AVFoundationAdapter: AudioPlayerAdapterProtocol, @unchecked Sendable {
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
    public var usesExternalPlaybackWhileExternalScreenIsActive: Bool {
        get { false }
        set {}
    }
}

#endif
