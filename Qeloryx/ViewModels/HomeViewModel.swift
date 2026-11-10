// QELORYX — ViewModels
// HomeViewModel.swift
// Extracted from the view file (Qeloryx/Views) — view models live here per the
// redesigned architecture.

import Foundation
import Combine

#if canImport(SwiftUI)
import SwiftUI
#endif

public final class HomeViewModel: ObservableObject {
    
    @Published public var favoriteCount: Int = 0
    @Published public var recentCount: Int = 0
    @Published public var downloadCount: Int = 0
    @Published public var queueCount: Int = 0
    @Published public var currentMood: String = "Chill"
    @Published public var tasteSummary: String = "Indie • Rock • Lo-Fi • Jazz"
    @Published public var recentTracks: [AstryxTrack] = []
    @Published public var greeting: String = "Good evening"
    @Published public var subGreeting: String = "Here's your music overview"
    @Published public var userInitial: String = "Q"
    
    private let libraryEngine: any LibraryEngineProtocol
    private let downloadEngine: any DownloadEngineProtocol
    private let tasteEngine: any TasteDNAEngineProtocol
    private let audioEngine: any AstryxAudioEngineProtocol
    
    public init(
        libraryEngine: any LibraryEngineProtocol,
        downloadEngine: any DownloadEngineProtocol,
        tasteEngine: any TasteDNAEngineProtocol,
        audioEngine: any AstryxAudioEngineProtocol
    ) {
        self.libraryEngine = libraryEngine
        self.downloadEngine = downloadEngine
        self.tasteEngine = tasteEngine
        self.audioEngine = audioEngine
        
        // Greeting based on time
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: greeting = "Good morning"
        case 12..<17: greeting = "Good afternoon"
        case 17..<22: greeting = "Good evening"
        default: greeting = "Good night"
        }
    }
    
    public func load() async {
        // Load stats
        let favorites = (try? await libraryEngine.fetchFavorites()) ?? []
        let history = (try? await libraryEngine.fetchHistory(limit: 10)) ?? []
        let downloads = await downloadEngine.allTasks()
        let profile = await tasteEngine.currentProfile()
        
        favoriteCount = favorites.count
        recentCount = history.count
        downloadCount = downloads.filter { $0.state == .completed }.count
        // `currentQueue` is a synchronous, view-facing snapshot; only this
        // read is taken on the main actor after the awaits above.
        queueCount = audioEngine.currentQueue.count
        
        if let profile = profile {
            currentMood = profile.mood.primary
            tasteSummary = profile.summary
        }
        
        recentTracks = history

        // An empty library shows zeros and an empty state. It used to report
        // 42 favourites, 12 recent and 8 downloads out of thin air, which made
        // a broken import look like a working library (BUG-17).
    }
    
    public func refresh() async {
        await load()
    }
}
