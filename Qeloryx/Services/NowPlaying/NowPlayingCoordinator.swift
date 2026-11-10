// QELORYX — Services/NowPlaying
// NowPlayingCoordinator.swift
//
// Bridges the event bus to the platform now-playing adapter. The platform
// manager owns MediaPlayer/remote commands; this coordinator only decides
// *when* to push coarse play/pause + position updates.
//
// Track-level metadata (title/artwork) is pushed by the audio engine itself —
// duplicating that path here would race the engine's own updates.

import Foundation

public final class NowPlayingCoordinator: @unchecked Sendable {

    private let eventBus: any EventBusProtocol
    private let nowPlayingManager: any NowPlayingManagerProtocol
    private var subscription: EventSubscription?

    public init(eventBus: any EventBusProtocol, nowPlayingManager: any NowPlayingManagerProtocol) {
        self.eventBus = eventBus
        self.nowPlayingManager = nowPlayingManager
    }

    /// Starts bridging. Safe to call once per app launch.
    public func start() {
        guard subscription == nil else { return }
        subscription = eventBus.subscribe { [weak self] event in
            guard case .playbackStateChanged(let snapshot) = event else { return }
            self?.nowPlayingManager.updatePlaybackState(
                isPlaying: snapshot.isPlaying,
                position: snapshot.position
            )
        }
    }

    public func stop() {
        subscription?.cancel()
        subscription = nil
    }
}
