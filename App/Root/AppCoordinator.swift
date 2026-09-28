// QELORYX — App
// AppCoordinator.swift

import SwiftUI
import Combine

public enum AppRoute: Hashable, Sendable {
    case library
    case search
    case player(trackID: String)
    case album(id: String)
    case artist(id: String)
    case settings
    case audioLab
    case tasteDNA
    case spaces
    case timeCapsule
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
        switch route {
        case .library:
            selectedTab = .library
        case .search:
            selectedTab = .search
        case .player(let trackID):
            currentTrackID = trackID
            isPlayerPresented = true
        case .album, .artist, .settings, .audioLab, .tasteDNA, .spaces, .timeCapsule:
            navigationPath.append(route)
        }
    }
    
    public func presentPlayer(trackID: String? = nil) {
        if let id = trackID {
            currentTrackID = id
        }
        isPlayerPresented = true
    }
    
    public func dismissPlayer() {
        isPlayerPresented = false
    }
}

public enum AppTab: String, CaseIterable, Sendable {
    case library = "Library"
    case search = "Search"
    case dashboard = "Home"
    
    public var icon: String {
        switch self {
        case .library: return "music.note.list"
        case .search: return "magnifyingglass"
        case .dashboard: return "square.grid.2x2"
        }
    }
}
