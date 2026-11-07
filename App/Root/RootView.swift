// QELORYX — App
// RootView.swift
// 1.0.0 Stable — Production root with 5 tabs, mini player, player sheet, performance monitoring

import SwiftUI

public struct RootView: View {

    @StateObject private var coordinator = AppCoordinator()
    @StateObject private var playerViewModel: AstryxPlayerViewModel

    /// The player view model is mandatory: it carries the app's real engines.
    /// The previous optional/`AstryxPlayerViewModel()` fallback built a second
    /// engine graph whenever the caller omitted it (BUG-19).
    public init(viewModel: AstryxPlayerViewModel) {
        _playerViewModel = StateObject(wrappedValue: viewModel)
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
        // `.astrixTheme()` is applied once, by `QeloryxApp`, around this view.
        .background(AstryxColors.Semantic.background.ignoresSafeArea())
        .sheet(isPresented: $coordinator.isPlayerPresented) {
            AstryxPlayerView(viewModel: playerViewModel)
        }
        // Non-tab destinations (settings, album, artist, audio lab, lyrics…).
        // The coordinator used to append these to a `NavigationPath` that no
        // view rendered, so navigating did nothing (BUG-18).
        .sheet(item: $coordinator.presentedRoute) { route in
            RouteDestinationView(route: route, coordinator: coordinator, playerViewModel: playerViewModel)
        }
        // The coordinator already observes `trackStarted` on its own event-bus
        // subscription, so a second subscription here was redundant (and the
        // `Task.sleep(nanoseconds: .max)` used to keep it alive can trap on
        // deadline overflow). Nothing to do in `.task` now.
        .task {
            await coordinator.refreshFromEngine()
        }
    }
}

// MARK: - Route destination

/// Maps a non-tab `AppRoute` to a screen.
///
/// Only the routes with a real screen are handled; the rest render an explicit
/// "not available" placeholder rather than a blank sheet pretending to work.
private struct RouteDestinationView: View {
    let route: AppRoute
    /// `@ObservedObject` (not a plain `let`): the sheet's Done button mutates
    /// the coordinator, and a non-observed reference would not refresh.
    @ObservedObject var coordinator: AppCoordinator
    @ObservedObject var playerViewModel: AstryxPlayerViewModel

    @Environment(\.dspEngine) private var dspEngine
    @Environment(\.lyricsEngine) private var lyricsEngine
    @Environment(\.libraryEngine) private var libraryEngine
    @Environment(\.audioEngine) private var audioEngine
    @Environment(\.tasteEngine) private var tasteEngine

    var body: some View {
        NavigationStack {
            content
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { coordinator.dismissRoute() }
                    }
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch route {
        case .audioLab:
            AudioLabView(dspEngine: dspEngine)
        case .lyrics(let trackID):
            // The track is looked up by the player view model; the sheet only
            // needs the engine pair plus a stable identity.
            LyricsView(
                track: playerViewModel.currentTrack?.id == trackID ? playerViewModel.currentTrack : nil,
                lyricsEngine: lyricsEngine,
                playerEngine: audioEngine
            )
            .id(trackID)
        case .tasteDNA:
            TasteDNAView(tasteEngine: tasteEngine, libraryEngine: libraryEngine)
        case .timeCapsule:
            TimeCapsuleView(libraryEngine: libraryEngine)
        case .album(_), .artist(_), .settings, .spaces, .player(_), .library, .search,
             .discovery, .dashboard, .downloads:
            NotAvailableView(route: route)
        }
    }
}

/// Honest placeholder for destinations that do not exist yet.
private struct NotAvailableView: View {
    let route: AppRoute

    var body: some View {
        VStack(spacing: AstryxSpacing.md) {
            Image(systemName: "hammer")
                .font(.system(size: 40))
                .foregroundColor(AstryxColors.Semantic.foregroundTertiary)
            Text(routeTitle)
                .font(AstryxTypography.Heading.h4)
                .foregroundColor(AstryxColors.Semantic.foreground)
            Text("This screen isn't built yet.")
                .font(AstryxTypography.Body.small)
                .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AstryxColors.Semantic.background.ignoresSafeArea())
    }

    private var routeTitle: String {
        switch route {
        case .album(_): return "Album"
        case .artist(_): return "Artist"
        case .settings: return "Settings"
        case .spaces: return "Spaces"
        default: return "Coming soon"
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

// MARK: - Tabs
//
// Each tab reads its engines from the environment injected by
// `QeloryxApp` (the composition root) and hands them to the view. No tab
// constructs its own engine, so all five tabs share one library, one audio
// engine and one download engine.

private struct LibraryRootTab: View {
    @Environment(\.libraryEngine) private var libraryEngine
    @Environment(\.audioEngine) private var audioEngine

    var body: some View {
        NavigationStack {
            LibraryView(libraryEngine: libraryEngine, audioEngine: audioEngine)
        }
    }
}

private struct SearchTab: View {
    @Environment(\.searchEngine) private var searchEngine

    var body: some View {
        NavigationStack {
            SearchView(searchEngine: searchEngine)
        }
    }
}

private struct DiscoveryTab: View {
    @Environment(\.tasteEngine) private var tasteEngine
    @Environment(\.libraryEngine) private var libraryEngine
    @Environment(\.dspEngine) private var dspEngine

    var body: some View {
        NavigationStack {
            DiscoveryView(
                tasteEngine: tasteEngine,
                libraryEngine: libraryEngine,
                dspEngine: dspEngine
            )
        }
    }
}

private struct DashboardTab: View {
    @Environment(\.libraryEngine) private var libraryEngine
    @Environment(\.downloadEngine) private var downloadEngine
    @Environment(\.tasteEngine) private var tasteEngine
    @Environment(\.audioEngine) private var audioEngine

    var body: some View {
        NavigationStack {
            DashboardView(
                libraryEngine: libraryEngine,
                downloadEngine: downloadEngine,
                tasteEngine: tasteEngine,
                audioEngine: audioEngine
            )
        }
    }
}

private struct DownloadsTab: View {
    @Environment(\.downloadEngine) private var downloadEngine

    var body: some View {
        NavigationStack {
            DownloadsView(downloadEngine: downloadEngine)
        }
    }
}
