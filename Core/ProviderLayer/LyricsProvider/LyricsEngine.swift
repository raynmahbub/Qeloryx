// QELORYX — ProviderLayer
// LyricsEngine.swift
// QEL-032 Lyrics++ — Central engine for synced lyrics, karaoke, translation

import Foundation

public protocol LyricsEngineProtocol: Sendable {
    func loadLyrics(for track: AstryxTrack) async throws -> AstryxLyrics?
    func loadLyrics(for track: AstryxTrack, language: String) async throws -> AstryxLyrics?
    func currentLyrics() -> AstryxLyrics?
    func currentLine(at time: TimeInterval) -> AstryxLyricLine?
    func currentLineIndex(at time: TimeInterval) -> Int?
    func currentWord(at time: TimeInterval) -> AstryxLyricWord?
    func setLyrics(_ lyrics: AstryxLyrics)
    func clear()
    func isKaraokeAvailable() -> Bool
    func availableLanguages() -> [String]
}

public final class AstryxLyricsEngine: LyricsEngineProtocol, @unchecked Sendable {
    
    private var _currentLyrics: AstryxLyrics?
    private let lock = NSLock()
    
    private let providers: [any LyricsProviderProtocol]
    private let eventBus: any EventBusProtocol
    private var subscriptionStore = EventSubscriptionStore()
    
    public init(
        providers: [any LyricsProviderProtocol] = [AstryxLyricsProvider()],
        eventBus: any EventBusProtocol = AstryxEventBus.shared
    ) {
        self.providers = providers
        self.eventBus = eventBus
        
        observePlayback()
    }
    
    private func observePlayback() {
        // Auto-load lyrics when track starts
        let sub = eventBus.subscribe(to: QeloryxEvent.trackStarted(trackID: "", queueID: "").name) { [weak self] event in
            Task {
                if case .trackStarted(let trackID, _) = event {
                    // In real app, fetch track from library and load lyrics
                    // For QEL-032, we just clear and let UI load via explicit call
                    // This is placeholder for auto-loading
                    #if DEBUG
                    debugPrint("[LyricsEngine] Track started: \(trackID), ready to load lyrics")
                    #endif
                }
            }
        }
        subscriptionStore.store(sub)
    }
    
    public func loadLyrics(for track: AstryxTrack) async throws -> AstryxLyrics? {
        // Try each provider until one returns lyrics
        for provider in providers {
            if let lyrics = try await provider.fetchLyrics(for: track) {
                setLyrics(lyrics)
                
                // Try to load translations — translation-ready architecture
                var translations: [String: AstryxLyrics] = [:]
                let languageCodes = ["es", "fr", "de", "ja", "ko", "zh", "bn"] // Example: Spanish, French, German, Japanese, Korean, Chinese, Bengali (user location BD)
                
                for langCode in languageCodes {
                    if let translated = try? await provider.fetchLyrics(for: track, language: langCode) {
                        translations[langCode] = translated
                    }
                }
                
                if !translations.isEmpty {
                    let withTranslations = AstryxLyrics(
                        trackID: lyrics.trackID,
                        lines: lyrics.lines,
                        isSynced: lyrics.isSynced,
                        language: lyrics.language,
                        translations: translations,
                        source: lyrics.source,
                        isKaraoke: lyrics.isKaraoke,
                        metadata: lyrics.metadata
                    )
                    setLyrics(withTranslations)
                    return withTranslations
                }
                
                return lyrics
            }
        }
        return nil
    }
    
    public func loadLyrics(for track: AstryxTrack, language: String) async throws -> AstryxLyrics? {
        for provider in providers {
            if let lyrics = try await provider.fetchLyrics(for: track, language: language) {
                return lyrics
            }
        }
        return nil
    }
    
    public func currentLyrics() -> AstryxLyrics? {
        lock.lock()
        defer { lock.unlock() }
        return _currentLyrics
    }
    
    public func currentLine(at time: TimeInterval) -> AstryxLyricLine? {
        lock.lock()
        let lyrics = _currentLyrics
        lock.unlock()
        return lyrics?.currentLine(at: time)
    }
    
    public func currentLineIndex(at time: TimeInterval) -> Int? {
        lock.lock()
        let lyrics = _currentLyrics
        lock.unlock()
        return lyrics?.currentLineIndex(at: time)
    }
    
    public func currentWord(at time: TimeInterval) -> AstryxLyricWord? {
        guard let line = currentLine(at: time), line.isKaraoke else { return nil }
        
        // Find current word in line
        var currentWord: AstryxLyricWord?
        for word in line.words {
            if word.startTime <= time {
                currentWord = word
            } else {
                break
            }
        }
        return currentWord
    }
    
    public func setLyrics(_ lyrics: AstryxLyrics) {
        lock.lock()
        _currentLyrics = lyrics
        lock.unlock()
        
        #if DEBUG
        debugPrint("[LyricsEngine] Set lyrics for \(lyrics.trackID), \(lyrics.lines.count) lines, karaoke=\(lyrics.isKaraoke), translations=\(lyrics.translations.keys)")
        #endif
    }
    
    public func clear() {
        lock.lock()
        _currentLyrics = nil
        lock.unlock()
    }
    
    public func isKaraokeAvailable() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return _currentLyrics?.isKaraoke ?? false
    }
    
    public func availableLanguages() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        guard let lyrics = _currentLyrics else { return [] }
        var languages = [lyrics.language]
        languages.append(contentsOf: lyrics.translations.keys)
        return Array(Set(languages)).sorted()
    }
}
