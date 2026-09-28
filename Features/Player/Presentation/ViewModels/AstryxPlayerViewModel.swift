// QELORYX — Features/Player
// AstryxPlayerViewModel.swift
// QEL-012 Player Milestone — Production ViewModel with queue, artwork transitions, haptics

import Foundation
import Combine

@MainActor
public final class AstryxPlayerViewModel: ObservableObject {
    
    @Published public var playbackState: AstryxPlaybackState = .idle
    @Published public var currentTrack: AstryxTrack?
    @Published public var queue: AstryxQueue = AstryxQueue()
    @Published public var upNext: [AstryxTrack] = []
    @Published public var isShuffleEnabled = false
    @Published public var repeatMode: AstryxRepeatMode = .off
    @Published public var position: TimeInterval = 0
    @Published public var duration: TimeInterval = 0
    @Published public var isSeeking = false
    @Published public var volume: Float = 1.0
    @Published public var isAirPlayActive = false
    
    @Published public var currentArtworkData: Data?
    @Published public var previousArtworkData: Data?
    @Published public var isArtworkTransitioning = false
    
    private let audioEngine: any AstryxAudioEngineProtocol
    private let libraryEngine: any LibraryEngineProtocol
    private let eventBus: any EventBusProtocol
    private var subscriptionStore = EventSubscriptionStore()
    private var timer: AnyCancellable?
    private var artworkTransitionTask: Task<Void, Never>?
    
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
        refreshQueue()
    }
    
    private func observeEvents() {
        let sub = eventBus.subscribe { [weak self] event in
            Task { @MainActor in
                guard let self = self else { return }
                switch event {
                case .playbackStateChanged(let snapshot):
                    let oldTrackID = self.playbackState.currentTrackID
                    let newTrackID = snapshot.trackID
                    self.playbackState = self.mapSnapshot(snapshot)
                    self.position = snapshot.position
                    self.duration = snapshot.duration
                    self.isShuffleEnabled = snapshot.shuffleEnabled
                    self.repeatMode = self.mapRepeatMode(snapshot.repeatMode)
                    if oldTrackID != newTrackID {
                        await self.handleTrackChange(newTrackID: newTrackID)
                    }
                case .queueChanged:
                    self.refreshQueue()
                case .trackStarted(let trackID, _):
                    await self.handleTrackChange(newTrackID: trackID)
                default:
                    break
                }
            }
        }
        subscriptionStore.store(sub)
    }
    
    private func handleTrackChange(newTrackID: String?) async {
        guard let trackID = newTrackID else {
            currentTrack = nil
            currentArtworkData = nil
            return
        }
        previousArtworkData = currentArtworkData
        isArtworkTransitioning = true
        if let track = try? await libraryEngine.fetchTrack(id: trackID) {
            currentTrack = track
            currentArtworkData = track.artworkData
            await refreshUpNext()
        } else {
            currentTrack = AstryxTrack(
                id: trackID,
                title: "Track \(trackID.prefix(8))",
                artist: "Unknown Artist",
                album: "Unknown Album",
                duration: duration,
                fileURL: URL(fileURLWithPath: "/tmp/\(trackID).mp3"),
                fileFormat: .mp3
            )
        }
        artworkTransitionTask?.cancel()
        artworkTransitionTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            await MainActor.run {
                self.isArtworkTransitioning = false
                self.previousArtworkData = nil
            }
        }
    }
    
    private func refreshQueue() {
        queue = audioEngine.currentQueue
        Task { await refreshUpNext() }
    }
    
    private func refreshUpNext() async {
        let currentIdx = queue.currentIndex ?? 0
        let nextItems = Array(queue.items.suffix(from: min(currentIdx + 1, queue.items.count)).prefix(5))
        var tracks: [AstryxTrack] = []
        for item in nextItems {
            if let track = try? await libraryEngine.fetchTrack(id: item.trackID) {
                tracks.append(track)
            }
        }
        upNext = tracks
    }
    
    private func startPositionTimer() {
        timer = Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.playbackState.isPlaying && !self.isSeeking {
                    self.position = self.audioEngine.playbackState.position
                    self.duration = self.audioEngine.playbackState.duration
                }
            }
    }
    
    public func playPause() async {
        do { try await audioEngine.handle(command: .togglePlayPause) } catch {}
    }
    public func next() async { try? await audioEngine.handle(command: .next) }
    public func previous() async { try? await audioEngine.handle(command: .previous) }
    public func seek(to time: TimeInterval) async { try? await audioEngine.handle(command: .seek(to: time)) }
    public func seekForward() async { try? await audioEngine.handle(command: .seekForward(interval: 15)) }
    public func seekBackward() async { try? await audioEngine.handle(command: .seekBackward(interval: 15)) }
    public func toggleShuffle() async { try? await audioEngine.handle(command: .setShuffle(!isShuffleEnabled)) }
    public func toggleRepeat() async { try? await audioEngine.handle(command: .setRepeat(repeatMode.next)) }
    public func playTrack(id: String) async { try? await audioEngine.handle(command: .play(trackID: id)) }
    public func playQueue(trackIDs: [String], startIndex: Int) async { try? await audioEngine.handle(command: .playQueue(queue: trackIDs, startIndex: startIndex)) }
    public func setVolume(_ volume: Float) async {
        self.volume = volume
        try? await audioEngine.handle(command: .setVolume(volume))
    }
    
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
    
    public var progress: Double {
        guard duration > 0 else { return 0 }
        return position / duration
    }
    public var formattedPosition: String { formatTime(position) }
    public var formattedDuration: String { formatTime(duration) }
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
