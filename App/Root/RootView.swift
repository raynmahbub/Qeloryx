// QELORYX — App
// RootView.swift
// Root SwiftUI view per clean architecture — only Presentation layer uses SwiftUI

import SwiftUI

public struct RootView: View {
    
    @StateObject private var coordinator = AppCoordinator()
    @State private var playbackState: AstryxPlaybackState = .idle
    @Environment(\.audioEngine) private var audioEngine
    @Environment(\.eventBus) private var eventBus
    
    public init() {}
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $coordinator.selectedTab) {
                LibraryRootView()
                    .tabItem {
                        Label(AppTab.library.rawValue, systemImage: AppTab.library.icon)
                    }
                    .tag(AppTab.library)
                
                SearchRootView()
                    .tabItem {
                        Label(AppTab.search.rawValue, systemImage: AppTab.search.icon)
                    }
                    .tag(AppTab.search)
                
                DashboardRootView()
                    .tabItem {
                        Label(AppTab.dashboard.rawValue, systemImage: AppTab.dashboard.icon)
                    }
                    .tag(AppTab.dashboard)
            }
            .tint(AstryxColors.auroraBlue)
            
            // Mini Player overlay
            if let trackID = coordinator.currentTrackID {
                MiniPlayerContainer(trackID: trackID, playbackState: playbackState) {
                    coordinator.presentPlayer()
                }
                .padding(.horizontal, AstryxSpacing.sm)
                .padding(.bottom, 49 + AstryxSpacing.sm) // Tab bar height
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(AstryxColors.Semantic.background.ignoresSafeArea())
        .astrixTheme()
        .sheet(isPresented: $coordinator.isPlayerPresented) {
            PlayerRootView(trackID: coordinator.currentTrackID)
        }
        .onReceive(coordinator.$currentTrackID) { _ in
            // Update playback state
            playbackState = audioEngine.playbackState
        }
        .task {
            // Observe playback state changes
            let _ = eventBus.subscribe { event in
                if case .playbackStateChanged = event {
                    Task { @MainActor in
                        playbackState = audioEngine.playbackState
                    }
                }
            }
        }
    }
}

// MARK: - Placeholder Feature Root Views (to be implemented in respective features)

private struct LibraryRootView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: AstryxSpacing.lg) {
                AstryxLargeNavigationBar(title: "Library", subtitle: "Offline-first • Midnight Aurora")
                
                VStack(spacing: AstryxSpacing.md) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 48))
                        .foregroundColor(AstryxColors.auroraBlue)
                    
                    Text("Library DNA")
                        .font(AstryxTypography.Heading.h2)
                        .foregroundColor(AstryxColors.Semantic.foreground)
                    
                    Text("Multi-library • Album grouping • Artist grouping • Genre • Folder view • Favorites • History • Recently Added")
                        .font(AstryxTypography.Body.small)
                        .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(AstryxColors.Semantic.background)
        }
    }
}

private struct SearchRootView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: AstryxSpacing.lg) {
                AstryxLargeNavigationBar(title: "Search", subtitle: "Instant • <50ms target")
                
                VStack(spacing: AstryxSpacing.md) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(AstryxColors.auroraBlue)
                    
                    Text("Universal Search")
                        .font(AstryxTypography.Heading.h2)
                        .foregroundColor(AstryxColors.Semantic.foreground)
                    
                    Text("Song • Artist • Album • Playlist • Folder • Lyrics • Command palette")
                        .font(AstryxTypography.Body.small)
                        .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(AstryxColors.Semantic.background)
        }
    }
}

private struct DashboardRootView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: AstryxSpacing.lg) {
                AstryxLargeNavigationBar(title: "QELORYX", subtitle: "Hear Beyond. Build Beyond.")
                
                VStack(spacing: AstryxSpacing.md) {
                    Text("QELORYX")
                        .font(AstryxTypography.Logo.largeSystem)
                        .foregroundColor(AstryxColors.auroraBlue)
                    
                    Text("Midnight Aurora")
                        .font(AstryxTypography.Heading.h4)
                        .foregroundColor(AstryxColors.Semantic.foreground)
                    
                    Text("0.1.0-dev • Foundation")
                        .font(AstryxTypography.Body.caption)
                        .foregroundColor(AstryxColors.Semantic.foregroundTertiary)
                    
                    AstryxButton(title: "Astryx Audio Lab", style: .secondary, icon: "waveform") {}
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(AstryxColors.Semantic.background)
        }
    }
}

private struct MiniPlayerContainer: View {
    let trackID: String
    let playbackState: AstryxPlaybackState
    let onTap: () -> Void
    
    var body: some View {
        AstryxMiniPlayer(
            title: "Track \(trackID.prefix(8))",
            artist: "Unknown Artist",
            artworkData: nil,
            isPlaying: playbackState.isPlaying,
            progress: playbackState.duration > 0 ? playbackState.position / playbackState.duration : 0,
            onPlayPause: {},
            onNext: {},
            onTap: onTap
        )
    }
}

private struct PlayerRootView: View {
    let trackID: String?
    
    var body: some View {
        VStack {
            Text("Astryx Player")
                .font(AstryxTypography.Heading.h2)
            Text(trackID ?? "No track")
                .font(AstryxTypography.Body.medium)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AstryxColors.Semantic.background)
    }
}
