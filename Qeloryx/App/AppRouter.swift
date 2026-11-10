// QELORYX — App
// AppRouter.swift
// The single navigation coordinator: 5 tabs, non-tab destinations as sheets,
// player sheet, performance monitoring. (Formerly AppCoordinator.)

import SwiftUI
import Combine

public enum AppRoute: Hashable, Sendable, Identifiable {
    /// Stable identity for `sheet(item:)`. One destination per route kind, so
    /// opening a different album replaces the sheet instead of stacking.
    public var id: String {
        switch self {
        case .library: return "library"
        case .search: return "search"
        case .discover: return "discover"
        case .home: return "home"
        case .downloads: return "downloads"
        case .player(let trackID): return "player-\(trackID)"
        case .album(let id): return "album-\(id)"
        case .artist(let id): return "artist-\(id)"
        case .settings: return "settings"
        case .audioLab: return "audioLab"
        case .tasteDNA: return "tasteDNA"
        case .social: return "social"
        case .statistics: return "statistics"
        case .lyrics(let id): return "lyrics-\(id)"
        case .queue: return "queue"
        }
    }

    case library
    case search
    case discover
    case home
    case downloads
    case player(trackID: String)
    case album(id: String)
    case artist(id: String)
    case settings
    case audioLab
    case tasteDNA
    case social
    case statistics
    case lyrics(trackID: String)
    case queue
}

@MainActor
public final class AppRouter: ObservableObject {
    
    @Published public var selectedTab: AppTab = .library
    /// Routes that are not a tab. Presented as a sheet from `RootView`.
    ///
    /// This replaced a `@Published var navigationPath = NavigationPath()`
    /// that was appended to and never read by any view, so `navigate(to:
    /// .settings)` silently did nothing (BUG-18).
    @Published public var presentedRoute: AppRoute?
    @Published public var isPlayerPresented = false
    @Published public var currentTrackID: String?
    
    private let eventBus: any EventBusProtocol
    private var cancellables = Set<AnyCancellable>()
    private var subscriptionStore = EventSubscriptionStore()
    private let performanceMonitor = AstryxPerformanceMonitor.shared
    
    public init(eventBus: any EventBusProtocol = AstryxEventBus.shared) {
        self.eventBus = eventBus
        observeEvents()
    }
    
    private func observeEvents() {
        let sub = eventBus.subscribe(to: QeloryxEvent.trackStarted(trackID: "", queueID: "").name) { [weak self] event in
            Task { @MainActor in
                if case .trackStarted(let trackID, _) = event {
                    self?.currentTrackID = trackID
                }
            }
        }
        subscriptionStore.store(sub)
    }
    
    public func navigate(to route: AppRoute) {
        // Performance: track navigation <50ms
        performanceMonitor.measure(name: "Navigation", target: 50) {
            switch route {
            case .library:
                selectedTab = .library
            case .search:
                selectedTab = .search
            case .discover:
                selectedTab = .discover
            case .home:
                selectedTab = .home
            case .downloads:
                selectedTab = .downloads
            case .player(let trackID):
                currentTrackID = trackID
                isPlayerPresented = true
            case .album(_), .artist(_), .settings, .audioLab, .tasteDNA, .social, .statistics, .lyrics(_), .queue:
                presentedRoute = route
            }
        }
        AstryxHapticEngine.shared.triggerTabChange()
    }
    
    public func presentPlayer(trackID: String? = nil) {
        if let id = trackID {
            currentTrackID = id
        }
        isPlayerPresented = true
        AstryxHapticEngine.shared.triggerPlay()
    }
    
    public func dismissPlayer() {
        isPlayerPresented = false
    }

    public func dismissRoute() {
        presentedRoute = nil
    }

    /// Seeds `currentTrackID` from whatever is already playing. Called once
    /// when the root appears, so a restored queue (or a relaunch mid-track)
    /// shows the mini player without waiting for the next `trackStarted`.
    public func refreshFromEngine(engine: (any AstryxAudioEngineProtocol)? = nil) async {
        if let trackID = engine?.playbackState.currentTrackID {
            currentTrackID = trackID
        }
    }
}

public enum AppTab: String, CaseIterable, Sendable {
    case library = "Library"
    case search = "Search"
    case discover = "Discover"
    case home = "Home"
    case downloads = "Downloads"
    
    public var icon: String {
        switch self {
        case .library: return "music.note.list"
        case .search: return "magnifyingglass"
        case .discover: return "sparkles"
        case .home: return "square.grid.2x2"
        case .downloads: return "arrow.down.circle"
        }
    }
}
