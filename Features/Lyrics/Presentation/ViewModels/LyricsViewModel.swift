// QELORYX — Features — Lyrics
// LyricsViewModel.swift
// QEL-032 Lyrics++ — Production with synced, karaoke, translation-ready, fullscreen

import Foundation
import Combine

#if canImport(SwiftUI)
import SwiftUI
#endif

public enum LyricsDisplayMode: String, CaseIterable, Sendable {
    case synced = "Synced"
    case karaoke = "Karaoke"
    case plain = "Plain"
    case fullscreen = "Fullscreen"
    
    public var icon: String {
        switch self {
        case .synced: return "music.note.list"
        case .karaoke: return "mic.fill"
        case .plain: return "text.alignleft"
        case .fullscreen: return "arrow.up.left.and.arrow.down.right"
        }
    }
}

@MainActor
public final class LyricsViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published public var lyrics: AstryxLyrics?
    @Published public var currentLineIndex: Int?
    @Published public var currentWordIndex: Int?
    @Published public var currentTime: TimeInterval = 0
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    @Published public var displayMode: LyricsDisplayMode = .synced
    @Published public var selectedLanguage: String = "en"
    @Published public var availableLanguages: [String] = []
    @Published public var showTranslation: Bool = false
    @Published public var translationLanguage: String = "en"
    @Published public var isFullscreen: Bool = false
    @Published public var autoScroll: Bool = true
    
    // MARK: - Dependencies
    
    private let lyricsEngine: any LyricsEngineProtocol
    private let playerEngine: any PlayerEngineProtocol
    private let eventBus: any EventBusProtocol
    
    private var cancellables = Set<AnyCancellable>()
    private var timerCancellable: AnyCancellable?
    private var currentTrack: AstryxTrack?
    
    public init(
        lyricsEngine: any LyricsEngineProtocol = AstryxLyricsEngine(),
        playerEngine: any PlayerEngineProtocol = AstryxAudioEngine(),
        eventBus: any EventBusProtocol = AstryxEventBus.shared
    ) {
        self.lyricsEngine = lyricsEngine
        self.playerEngine = playerEngine
        self.eventBus = eventBus
        
        observeEvents()
        startPlaybackTracking()
    }
    
    private func observeEvents() {
        // Track changed -> load lyrics
        let sub1 = eventBus.subscribe(to: QeloryxEvent.trackStarted(trackID: "", queueID: "").name) { [weak self] event in
            Task { @MainActor in
                if case .trackStarted(let trackID, _) = event {
                    self?.handleTrackStarted(trackID: trackID)
                }
            }
        }
        
        // Playback state -> sync
        let sub2 = eventBus.subscribe(to: QeloryxEvent.playbackStateChanged(state: .stopped).name) { [weak self] _ in
            Task { @MainActor in
                self?.updateCurrentPosition()
            }
        }
        
        cancellables.insert(AnyCancellable { sub1.cancel(); sub2.cancel() })
    }
    
    private func startPlaybackTracking() {
        // Poll current time every 100ms for smooth synced lyrics — karaoke needs <100ms
        timerCancellable = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateCurrentPosition()
            }
    }
    
    private func handleTrackStarted(trackID: String) {
        // In production, fetch track from library
        // For now, clear and wait for explicit load
        clear()
    }
    
    private func updateCurrentPosition() {
        currentTime = playerEngine.currentTime
        
        guard let lyrics = lyrics else { return }
        
        if let index = lyrics.currentLineIndex(at: currentTime) {
            if currentLineIndex != index {
                currentLineIndex = index
                
                // Auto-scroll handled by view via scrollTo
                if autoScroll {
                    // Publish event for UI
                }
            }
        }
        
        // Karaoke word-level
        if displayMode == .karaoke, let lineIdx = currentLineIndex {
            let line = lyrics.lines[lineIdx]
            if line.isKaraoke {
                for (wordIdx, word) in line.words.enumerated() {
                    let nextStart = wordIdx + 1 < line.words.count ? line.words[wordIdx + 1].startTime : line.endTime ?? .infinity
                    if word.startTime <= currentTime && currentTime < nextStart {
                        if currentWordIndex != wordIdx {
                            currentWordIndex = wordIdx
                        }
                        break
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    public func loadLyrics(for track: AstryxTrack) {
        currentTrack = track
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                if let loaded = try await lyricsEngine.loadLyrics(for: track) {
                    self.lyrics = loaded
                    self.availableLanguages = lyricsEngine.availableLanguages()
                    self.selectedLanguage = loaded.language
                    
                    // Auto-select display mode
                    if loaded.isKaraoke {
                        self.displayMode = .karaoke
                    } else if loaded.isSynced {
                        self.displayMode = .synced
                    } else {
                        self.displayMode = .plain
                    }
                    
                    self.isLoading = false
                } else {
                    self.lyrics = nil
                    self.errorMessage = "No lyrics found"
                    self.isLoading = false
                }
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    public func loadTranslation(language: String) {
        guard let track = currentTrack else { return }
        
        Task {
            do {
                if let translated = try await lyricsEngine.loadLyrics(for: track, language: language) {
                    // Show translation alongside original or switch
                    self.translationLanguage = language
                    self.showTranslation = true
                    
                    // If we have base lyrics, merge translation into display
                    if var base = self.lyrics {
                        // For QEL-032, we keep base and show translation as secondary
                        // In future, we could merge line-by-line
                        self.lyrics = base
                    } else {
                        self.lyrics = translated
                    }
                }
            } catch {
                self.errorMessage = "Translation not available for \(language)"
            }
        }
    }
    
    public func toggleTranslation() {
        showTranslation.toggle()
    }
    
    public func setDisplayMode(_ mode: LyricsDisplayMode) {
        if mode == .fullscreen {
            isFullscreen.toggle()
        } else {
            displayMode = mode
        }
    }
    
    public func seekToLine(_ line: AstryxLyricLine) {
        Task {
            try? await playerEngine.seek(to: line.startTime)
        }
    }
    
    public func seekToWord(_ word: AstryxLyricWord) {
        Task {
            try? await playerEngine.seek(to: word.startTime)
        }
    }
    
    public func toggleAutoScroll() {
        autoScroll.toggle()
    }
    
    public func clear() {
        lyrics = nil
        currentLineIndex = nil
        currentWordIndex = nil
        currentTime = 0
        errorMessage = nil
        availableLanguages = []
    }
    
    public func formattedTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
}
