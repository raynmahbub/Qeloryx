// QELORYX — App
// AppCoordinator.swift
// 1.0.0 Stable — Production coordinator with 5 tabs, navigation, player sheet, performance monitoring

import SwiftUI
import Combine

public enum AppRoute: Hashable, Sendable {
    case library
    case search
    case discovery
    case dashboard
    case downloads
    case player(trackID: String)
    case album(id: String)
    case artist(id: String)
    case settings
    case audioLab
    case tasteDNA
    case spaces
    case timeCapsule
    case lyrics(trackID: String)
}

@MainActor
public final class AppCoordinator: ObservableObject {
    
    @Published public var selectedTab: AppTab = .library
    @Published public var navigationPath = NavigationPath()
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
            case .discovery:
                selectedTab = .discovery
            case .dashboard:
                selectedTab = .dashboard
            case .downloads:
                selectedTab = .downloads
            case .player(let trackID):
                currentTrackID = trackID
                isPlayerPresented = true
            case .album, .artist, .settings, .audioLab, .tasteDNA, .spaces, .timeCapsule, .lyrics:
                navigationPath.append(route)
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
}

public enum AppTab: String, CaseIterable, Sendable {
    case library = "Library"
    case search = "Search"
    case discovery = "Discovery"
    case dashboard = "Home"
    case downloads = "Downloads"
    
    public var icon: String {
        switch self {
        case .library: return "music.note.list"
        case .search: return "magnifyingglass"
        case .discovery: return "sparkles"
        case .dashboard: return "square.grid.2x2"
        case .downloads: return "arrow.down.circle"
        }
    }
}
