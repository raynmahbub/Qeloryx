// QELORYX — Platform
// GaplessAudioPlayerAdapter.swift
// Sprint "Seamless Playback" — dual-deck AVPlayer implementation of
// CrossfadeCapableAudioPlayer. Clean-room design:
//   • ACTIVE deck plays at full gain; STANDBY deck pre-buffers at gain 0.
//   • When the engine commits a crossfade, a 30 Hz ramp drives both decks'
//     gains through the configured CrossfadeCurve, then the roles swap.
//   • The retiring deck's natural end notification is suppressed so the
//     audio engine is never asked to double-advance the queue.
// With crossfades disabled this behaves exactly like AVFoundationAdapter:
// a single active deck with hard transitions.
// AVFoundation stays isolated here per architecture rules.

#if canImport(AVFoundation)

#if canImport(QeloryxCore)
import QeloryxCore
#endif

import Foundation
import AVFoundation

public final class GaplessAudioPlayerAdapter: AudioPlayerAdapterProtocol,
    CrossfadeCapableAudioPlayer, @unchecked Sendable {

    public weak var delegate: AVFoundationAdapterDelegate?

    private let lock = NSLock()

    // MARK: Decks

    private var activePlayer: AVPlayer?
    private var activeItem: AVPlayerItem?
    private var activeStatusObserver: NSKeyValueObservation?
    private var activeEndObserver: NSObjectProtocol?
    private var activeTimeObserver: Any?

    private var standbyPlayer: AVPlayer?
    private var standbyItem: AVPlayerItem?
    private var standbyEndObserver: NSObjectProtocol?
    private var standbyStatusObserver: NSKeyValueObservation?

    // MARK: Fade state

    private var fadeTimer: DispatchSourceTimer?
    private var fadeStartTime: Date?
    private var fadeDuration: TimeInterval = 0
    private var fadeCurve: CrossfadeCurve = .equalPower
    /// True while a commit is in flight; the retiring deck's end-of-item
    /// notification must not reach the delegate during this window.
    private var isCrossfading = false

    private let fadeQueue = DispatchQueue(label: "com.qeloryx.audio.crossfade", qos: .userInitiated)
    private static let fadeStep: TimeInterval = 1.0 / 30.0

    public init() {}

    // MARK: - AudioPlayerAdapterProtocol

    public func load(url: URL) throws {
        lock.lock()
        defer { lock.unlock() }
        cancelFadeLocked()
        teardownStandbyLocked()
        teardownActiveLocked()
        let (player, item) = makeDeck(url: url)
        activePlayer = player
        activeItem = item
        activeStatusObserver = observeStatus(of: item)
        activeEndObserver = observeEnd(of: item, isStandby: false)
        attachTimeObserver(to: player)
    }

    public func load(track: AstryxTrack) throws {
        try load(url: track.fileURL)
    }

    public func play() {
        lock.lock()
        let player = activePlayer
        lock.unlock()
        player?.play()
    }

    public func pause() {
        lock.lock()
        let needsInstantSwap = isCrossfading
        lock.unlock()
        if needsInstantSwap {
            // Pausing mid-fade would freeze the mix at a blended volume.
            // Complete the transition instantly so resume starts clean.
            completeCrossfade()
        }
        lock.lock()
        let player = activePlayer
        lock.unlock()
        player?.pause()
    }

    public func stop() {
        lock.lock()
        let player = activePlayer
        lock.unlock()
        player?.pause()
        player?.seek(to: .zero)
        lock.lock()
        cancelFadeLocked()
        teardownStandbyLocked()
        teardownActiveLocked()
        lock.unlock()
    }

    public func seek(to time: TimeInterval, completion: ((Bool) -> Void)? = nil) {
        lock.lock()
        let player = activePlayer
        lock.unlock()
        let cmTime = CMTime(seconds: time, preferredTimescale: 1000)
        player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero) { finished in
            completion?(finished)
        } ?? completion?(false)
    }

    public func setVolume(_ volume: Float) {
        lock.lock()
        let player = activePlayer
        lock.unlock()
        player?.volume = max(0, min(1, volume))
    }

    public func setRate(_ rate: Float) {
        lock.lock()
        let player = activePlayer
        lock.unlock()
        player?.rate = rate
    }

    public func currentTime() -> TimeInterval {
        lock.lock()
        let player = activePlayer
        lock.unlock()
        guard let seconds = player?.currentTime().seconds, seconds.isFinite else { return 0 }
        return seconds
    }

    public func duration() -> TimeInterval {
        lock.lock()
        let item = activeItem
        lock.unlock()
        guard let item = item else { return 0 }
        let assetDuration = item.asset.duration
        if assetDuration.isIndefinite || assetDuration.seconds.isNaN {
            return item.duration.seconds.isNaN ? 0 : item.duration.seconds
        }
        return assetDuration.seconds
    }

    public func isPlaying() -> Bool {
        lock.lock()
        let player = activePlayer
        lock.unlock()
        return (player?.rate ?? 0) != 0 && player?.error == nil
    }

    public var isAirPlayActive: Bool {
        lock.lock()
        let player = activePlayer
        lock.unlock()
        return player?.isExternalPlaybackActive ?? false
    }

    public var allowsExternalPlayback: Bool {
        get {
            lock.lock()
            let value = activePlayer?.allowsExternalPlayback ?? true
            lock.unlock()
            return value
        }
        set {
            lock.lock()
            activePlayer?.allowsExternalPlayback = newValue
            standbyPlayer?.allowsExternalPlayback = newValue
            lock.unlock()
        }
    }

    // MARK: - CrossfadeCapableAudioPlayer

    public var hasPreparedNext: Bool {
        lock.lock()
        let prepared = standbyPlayer != nil
        lock.unlock()
        return prepared
    }

    public func prepareNext(url: URL) throws {
        lock.lock()
        defer { lock.unlock() }
        teardownStandbyLocked()
        let (player, item) = makeDeck(url: url)
        player.volume = 0
        standbyPlayer = player
        standbyItem = item
        standbyEndObserver = observeEnd(of: item, isStandby: true)
        standbyStatusObserver = observeStatus(of: item, isStandby: true)
    }

    public func activatePreparedNext(fadeDuration: TimeInterval, curve: CrossfadeCurve) {
        lock.lock()
        guard let incoming = standbyPlayer else {
            lock.unlock()
            return
        }
        isCrossfading = true
        self.fadeDuration = max(fadeDuration, 0)
        self.fadeCurve = curve
        self.fadeStartTime = Date()
        incoming.volume = 0
        lock.unlock()

        incoming.play()
        startFadeRamp()
    }

    public func cancelPreparedNext() {
        lock.lock()
        cancelFadeLocked()
        teardownStandbyLocked()
        activePlayer?.volume = 1
        lock.unlock()
    }

    // MARK: - Fade machinery

    private func startFadeRamp() {
        let timer = DispatchSource.makeTimerSource(queue: fadeQueue)
        timer.schedule(deadline: .now(), repeating: GaplessAudioPlayerAdapter.fadeStep)
        timer.setEventHandler { [weak self] in
            self?.stepFadeRamp()
        }
        lock.lock()
        fadeTimer?.cancel()
        fadeTimer = timer
        lock.unlock()
        timer.resume()
    }

    private func stepFadeRamp() {
        lock.lock()
        guard isCrossfading,
              let start = fadeStartTime,
              let outgoing = activePlayer,
              let incoming = standbyPlayer else {
            lock.unlock()
            return
        }
        let elapsed = Date().timeIntervalSince(start)
        let duration = fadeDuration
        let curve = fadeCurve
        let progress = duration > 0 ? elapsed / duration : 1
        if progress >= 1 {
            lock.unlock()
            completeCrossfade()
            return
        }
        lock.unlock()
        outgoing.volume = Float(curve.fadeOutLevel(at: progress))
        incoming.volume = Float(curve.fadeInLevel(at: progress))
    }

    /// Runs once the ramp completes: retires the old deck and promotes the
    /// incoming one. The promoted deck's observers are rebound with
    /// active-deck semantics — the standby guards (suppressed end
    /// notifications, swallowed failures) must not follow the deck once it
    /// owns playback. The retired deck is torn down before it can emit a
    /// stale end notification.
    private func completeCrossfade() {
        lock.lock()
        cancelFadeLocked()

        let retired = activePlayer
        let retiredEnd = activeEndObserver
        let retiredStatus = activeStatusObserver
        let retiredTime = activeTimeObserver

        activePlayer = standbyPlayer
        activeItem = standbyItem
        if let promotedEnd = standbyEndObserver {
            NotificationCenter.default.removeObserver(promotedEnd)
        }
        standbyStatusObserver?.invalidate()
        activeEndObserver = activeItem.map { observeEnd(of: $0, isStandby: false) }
        activeStatusObserver = activeItem.map { observeStatus(of: $0) }
        activeTimeObserver = nil

        standbyPlayer = nil
        standbyItem = nil
        standbyEndObserver = nil
        standbyStatusObserver = nil

        if let active = activePlayer {
            attachTimeObserver(to: active)
            active.volume = 1
        }
        isCrossfading = false
        lock.unlock()

        // Retire the outgoing deck outside the lock.
        retired?.pause()
        retired?.seek(to: .zero)
        if let end = retiredEnd { NotificationCenter.default.removeObserver(end) }
        retiredStatus?.invalidate()
        if let observer = retiredTime { retired?.removeTimeObserver(observer) }
    }

    // MARK: - Deck construction

    private func makeDeck(url: URL) -> (AVPlayer, AVPlayerItem) {
        let asset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        let item = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: item)
        player.automaticallyWaitsToMinimizeStalling = false
        player.actionAtItemEnd = .pause
        player.allowsExternalPlayback = allowsExternalPlayback
        return (player, item)
    }

    private func observeEnd(of item: AVPlayerItem, isStandby: Bool) -> NSObjectProtocol {
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: nil
        ) { [weak self] _ in
            guard let self = self else { return }
            self.lock.lock()
            let shouldNotify = isStandby ? (self.standbyPlayer === nil && !self.isCrossfading) : !self.isCrossfading
            self.lock.unlock()
            // Natural finish only matters for the deck that is still active
            // and not being faded out; a retiring deck is silenced by the
            // fade ramp and its end is intentionally swallowed.
            if shouldNotify {
                self.delegate?.adapterDidFinishPlaying()
            }
        }
    }

    private func observeStatus(of item: AVPlayerItem, isStandby: Bool = false) -> NSKeyValueObservation {
        item.observe(\.status, options: [.new]) { [weak self] observed, _ in
            guard let self = self else { return }
            switch observed.status {
            case .readyToPlay:
                self.delegate?.adapterDidChangeStatus(isReady: true)
            case .failed:
                if isStandby {
                    // A staged deck that fails to load must not fail the
                    // current track; drop it so natural end falls back to
                    // the classic hard transition.
                    self.lock.lock()
                    self.teardownStandbyLocked()
                    self.lock.unlock()
                } else {
                    let failure = observed.error ?? NSError(domain: "GaplessAudioPlayerAdapter", code: -1)
                    self.delegate?.adapterDidFail(error: failure)
                }
            default:
                break
            }
        }
    }

    private func attachTimeObserver(to player: AVPlayer) {
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        activeTimeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: nil) { [weak self] time in
            self?.delegate?.adapterTimeDidUpdate(time: time.seconds.isFinite ? time.seconds : 0)
        }
    }

    // MARK: - Teardown helpers (must hold lock)

    private func cancelFadeLocked() {
        fadeTimer?.cancel()
        fadeTimer = nil
        fadeStartTime = nil
        isCrossfading = false
    }

    private func teardownStandbyLocked() {
        standbyPlayer?.pause()
        if let observer = standbyEndObserver {
            NotificationCenter.default.removeObserver(observer)
            standbyEndObserver = nil
        }
        standbyStatusObserver?.invalidate()
        standbyStatusObserver = nil
        standbyPlayer = nil
        standbyItem = nil
    }

    private func teardownActiveLocked() {
        activePlayer?.pause()
        if let observer = activeEndObserver {
            NotificationCenter.default.removeObserver(observer)
            activeEndObserver = nil
        }
        activeStatusObserver?.invalidate()
        activeStatusObserver = nil
        if let player = activePlayer, let observer = activeTimeObserver {
            player.removeTimeObserver(observer)
            activeTimeObserver = nil
        }
        activePlayer = nil
        activeItem = nil
    }
}

#endif
