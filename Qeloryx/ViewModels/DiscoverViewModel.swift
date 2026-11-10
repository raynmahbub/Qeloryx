// QELORYX — ViewModels
// DiscoverViewModel.swift
// Extracted from the view file (Qeloryx/Views) — view models live here per the
// redesigned architecture.

import Foundation
import Combine

#if canImport(SwiftUI)
import SwiftUI
#endif

public final class DiscoverViewModel: ObservableObject {
    
    @Published public var profile: AstryxTasteProfile?
    @Published public var recommendations: [AstryxRecommendation] = []
    @Published public var isLoading: Bool = false
    
    private let tasteEngine: any TasteDNAEngineProtocol
    private let libraryEngine: any LibraryEngineProtocol
    private let dspEngine: any DSPEngineProtocol
    
    public init(
        tasteEngine: any TasteDNAEngineProtocol,
        libraryEngine: any LibraryEngineProtocol,
        dspEngine: any DSPEngineProtocol
    ) {
        self.dspEngine = dspEngine
        self.tasteEngine = tasteEngine
        self.libraryEngine = libraryEngine
    }
    
    public func load() async {
        isLoading = true
        
        let tracks = (try? await libraryEngine.fetchAllTracks()) ?? []
        
        if tracks.isEmpty {
            // No tracks ⇒ no profile. The previous code substituted a
            // fabricated "Indie / Rock / Lo-Fi" profile with invented play
            // counts, so an empty library looked like a rich one (BUG-17).
            profile = nil
            recommendations = []
            isLoading = false
            return
        }
        
        let generated = await tasteEngine.generateProfile(from: tracks)
        profile = generated
        
        let recs = await tasteEngine.recommendations(for: generated, from: tracks, limit: 5)
        recommendations = recs
        
        isLoading = false
    }
    
    public func refresh() async {
        await load()
    }
    
}
