// QELORYX — App
// RootView.swift
// 1.0.0 Stable — Production root with 5 tabs, mini player, player sheet, performance monitoring

import SwiftUI

public struct RootView: View {
    
    @StateObject private var coordinator = AppCoordinator()
    @StateObject private var playerViewModel: AstryxPlayerViewModel
    @Environment(\.audioEngine) private var audioEngine
    @Environment(\.eventBus) private var eventBus
    @Environment(\.libraryEngine) private var libraryEngine
    
    public init(viewModel: AstryxPlayerViewModel? = nil) {
        if let vm = viewModel {
            _playerViewModel = StateObject(wrappedValue: vm)
        } else {
            _playerViewModel = StateObject(wrappedValue: AstryxPlayerViewModel())
        }
    }
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $coordinator.selectedTab) {
                LibraryRootTab()
                    .tabItem { Label(AppTab.library.rawValue, systemImage: AppTab.library.icon) }
                    .tag(AppTab.library)
                
                SearchTab()
                    .tabItem { Label(AppTab.search.rawValue, systemImage: AppTab.search.icon) }
                    .tag(AppTab.search)
                
                DiscoveryTab()
                    .tabItem { Label(AppTab.discovery.rawValue, systemImage: AppTab.discovery.icon) }
                    .tag(AppTab.discovery)
                
                DashboardTab()
                    .tabItem { Label(AppTab.dashboard.rawValue, systemImage: AppTab.dashboard.icon) }
                    .tag(AppTab.dashboard)
                
                DownloadsTab()
                    .tabItem { Label(AppTab.downloads.rawValue, systemImage: AppTab.downloads.icon) }
                    .tag(AppTab.downloads)
            }
            .tint(AstryxColors.auroraBlue)
            
            if playerViewModel.playbackState.currentTrackID != nil {
                EnhancedMiniPlayer(viewModel: playerViewModel) {
                    coordinator.presentPlayer()
                }
                .padding(.horizontal, AstryxSpacing.sm)
                .padding(.bottom, 49 + AstryxSpacing.sm)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(AstryxAnimations.cardAppear, value: playerViewModel.playbackState.currentTrackID)
            }
        }
        .background(AstryxColors.Semantic.background.ignoresSafeArea())
        .astrixTheme()
        .sheet(isPresented: $coordinator.isPlayerPresented) {
            AstryxPlayerView(viewModel: playerViewModel)
        }
        .task {
            let _ = eventBus.subscribe { event in
                if case .trackStarted(let trackID, _) = event {
                    Task { @MainActor in coordinator.currentTrackID = trackID }
                }
            }
        }
    }
}

// MARK: - Enhanced Mini Player — Production with artwork transition + haptics

private struct EnhancedMiniPlayer: View {
    @ObservedObject var viewModel: AstryxPlayerViewModel
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: AstryxSpacing.sm) {
                ZStack {
                    if let prev = viewModel.previousArtworkData, viewModel.isArtworkTransitioning {
                        AstryxArtwork(data: prev, size: 48).opacity(0.5)
                    }
                    AstryxArtwork(data: viewModel.currentArtworkData, size: 48)
                        .scaleEffect(viewModel.isArtworkTransitioning ? 0.95 : 1.0)
                        .animation(AstryxAnimations.artwork, value: viewModel.isArtworkTransitioning)
                }
                .astrixAccessible(label: "Album artwork for \(viewModel.currentTrack?.title ?? "current track")")
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.currentTrack?.title ?? "No Track")
                        .font(AstryxTypography.Label.medium)
                        .foregroundColor(AstryxColors.Semantic.foreground)
                        .lineLimit(1)
                    HStack(spacing: 4) {
                        Text(viewModel.currentTrack?.artist ?? "Unknown Artist")
                            .font(AstryxTypography.Body.small)
                            .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                            .lineLimit(1)
                        if viewModel.currentTrack?.isLossless == true {
                            Image(systemName: "waveform")
                                .font(.system(size: 8))
                                .foregroundColor(AstryxColors.emerald)
                        }
                    }
                }
                
                Spacer()
                
                Button {
                    Task { await viewModel.playPause() }
                    AstryxHapticEngine.shared.triggerPlay()
                } label: {
                    Image(systemName: viewModel.playbackState.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(AstryxColors.Semantic.foreground)
                        .frame(width: 36, height: 36)
                        .background(AstryxColors.Semantic.surface.opacity(0.6))
                        .clipShape(Circle())
                }
                .astrixAccessible(label: viewModel.playbackState.isPlaying ? "Pause" : "Play", isButton: true)
                
                Button {
                    Task { await viewModel.next() }
                    AstryxHapticEngine.shared.trigger(.light)
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AstryxColors.Semantic.foreground)
                        .frame(width: 36, height: 36)
                }
                .astrixAccessible(label: "Next track", isButton: true)
            }
            .padding(AstryxSpacing.sm)
            .background(.ultraThinMaterial)
            .background(AstryxColors.Semantic.backgroundSecondary.opacity(0.8))
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(AstryxColors.Semantic.surface)
                        .frame(height: 2)
                    Rectangle()
                        .fill(AstryxColors.auroraBlue)
                        .frame(width: geo.size.width * viewModel.progress, height: 2)
                        .animation(AstryxAnimations.quick, value: viewModel.progress)
                }
            }
            .frame(height: 2)
        }
        .clipShape(RoundedRectangle(cornerRadius: AstryxCornerRadius.md))
        .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: -4)
        .onTapGesture {
            onTap()
            AstryxHapticEngine.shared.trigger(.light)
        }
    }
}

// MARK: - Tabs — Production with real views

private struct LibraryRootTab: View {
    var body: some View {
        NavigationStack {
            LibraryView()
        }
    }
}

private struct SearchTab: View {
    var body: some View {
        NavigationStack {
            SearchView()
        }
    }
}

private struct DiscoveryTab: View {
    var body: some View {
        NavigationStack {
            DiscoveryView()
        }
    }
}

private struct DashboardTab: View {
    var body: some View {
        NavigationStack {
            DashboardView()
        }
    }
}

private struct DownloadsTab: View {
    var body: some View {
        NavigationStack {
            DownloadsView()
        }
    }
}
