// QELORYX — Features/Player
// AstryxPlayerViewModel.swift
// Application layer — ViewModel per clean architecture, no SwiftUI import in Domain

import Foundation
import Combine

@MainActor
public final class AstryxPlayerViewModel: ObservableObject {
    
    // MARK: - Published State
    @Published public var playbackState: AstryxPlaybackState = .idle
    @Published public var currentTrack: AstryxTrack?
    @Published public var queue: AstryxQueue = AstryxQueue()
    @Published public var isShuffleEnabled = false
    @Published public var repeatMode: AstryxRepeatMode = .off
    @Published public var position: TimeInterval = 0
    @Published public var duration: TimeInterval = 0
    
    // MARK: - Dependencies
    private let audioEngine: any AstryxAudioEngineProtocol
    private let libraryEngine: any LibraryEngineProtocol
    private let eventBus: any EventBusProtocol
    private var subscriptionStore = EventSubscriptionStore()
    private var timer: AnyCancellable?
    
    public init(
        audioEngine: any AstryxAudioEngineProtocol = AstryxAudioEngine(),
        libraryEngine: any LibraryEngineProtocol = AstryxLibraryEngine(),
        eventBus: any EventBusProtocol = AstryxEventBus.shared
    ) {
        self.audioEngine = audioEngine
        self.libraryEngine = libraryEngine
        self.eventBus = eventBus
        
        observeEvents()
        startPositionTimer()
    }
    
    private func observeEvents() {
        let sub1 = eventBus.subscribe { [weak self] event in
            Task { @MainActor in
                guard let self = self else { return }
                switch event {
                case .playbackStateChanged(let snapshot):
                    self.playbackState = self.mapSnapshot(snapshot)
                    self.position = snapshot.position
                    self.duration = snapshot.duration
                    self.isShuffleEnabled = snapshot.shuffleEnabled
                    self.repeatMode = self.mapRepeatMode(snapshot.repeatMode)
                    
                    if let trackID = snapshot.trackID {
                        self.currentTrack = try? await self.libraryEngine.fetchTrack(id: trackID)
                    }
                    
                case .queueChanged:
                    self.queue = self.audioEngine.currentQueue
                    
                default:
                    break
                }
            }
        }
        subscriptionStore.store(sub1)
    }
    
    private func startPositionTimer() {
        timer = Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.playbackState.isPlaying {
                    self.position = self.audioEngine.playbackState.position
                }
            }
    }
    
    // MARK: - Actions (Presentation → Domain via Engine)
    
    public func playPause() async {
        do {
            try await audioEngine.handle(command: .togglePlayPause)
        } catch {
            #if DEBUG
            debugPrint("[PlayerVM] playPause failed: \(error)")
            #endif
        }
    }
    
    public func next() async {
        try? await audioEngine.handle(command: .next)
    }
    
    public func previous() async {
        try? await audioEngine.handle(command: .previous)
    }
    
    public func seek(to time: TimeInterval) async {
        try? await audioEngine.handle(command: .seek(to: time))
    }
    
    public func toggleShuffle() async {
        try? await audioEngine.handle(command: .setShuffle(!isShuffleEnabled))
    }
    
    public func toggleRepeat() async {
        try? await audioEngine.handle(command: .setRepeat(repeatMode.next))
    }
    
    // MARK: - Mappers
    
    private func mapSnapshot(_ snapshot: PlaybackStateSnapshot) -> AstryxPlaybackState {
        if snapshot.isPlaying, let id = snapshot.trackID {
            return .playing(trackID: id, position: snapshot.position, duration: snapshot.duration)
        } else if let id = snapshot.trackID {
            return .paused(trackID: id, position: snapshot.position, duration: snapshot.duration)
        } else {
            return .idle
        }
    }
    
    private func mapRepeatMode(_ mode: RepeatModeSnapshot) -> AstryxRepeatMode {
        switch mode {
        case .off: return .off
        case .all: return .all
        case .one: return .one
        }
    }
}
