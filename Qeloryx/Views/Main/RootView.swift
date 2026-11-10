// QELORYX — Views/Main
// RootView.swift
// 1.0.0 Stable — Production root with 5 tabs, mini player, player sheet, performance monitoring

import SwiftUI

public struct RootView: View {

    @StateObject private var coordinator = AppRouter()
    @StateObject private var playerViewModel: PlayerViewModel

    /// The player view model is mandatory: it carries the app's real engines.
    /// The previous optional/`PlayerViewModel()` fallback built a second
    /// engine graph whenever the caller omitted it (BUG-19).
    public init(viewModel: PlayerViewModel) {
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
                
                DiscoverTab()
                    .tabItem { Label(AppTab.discover.rawValue, systemImage: AppTab.discover.icon) }
                    .tag(AppTab.discover)
                
                HomeTab()
                    .tabItem { Label(AppTab.home.rawValue, systemImage: AppTab.home.icon) }
                    .tag(AppTab.home)
                
                DownloadsTab()
                    .tabItem { Label(AppTab.downloads.rawValue, systemImage: AppTab.downloads.icon) }
                    .tag(AppTab.downloads)
            }
            .tint(AstryxColors.auroraBlue)
            
            if playerViewModel.playbackState.currentTrackID != nil {
                MiniPlayerView(viewModel: playerViewModel) {
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
            PlayerView(viewModel: playerViewModel)
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
    @ObservedObject var coordinator: AppRouter
    @ObservedObject var playerViewModel: PlayerViewModel

    @Environment(\.dspEngine) private var dspEngine
    @Environment(\.lyricsEngine) private var lyricsEngine
    @Environment(\.libraryEngine) private var libraryEngine
    @Environment(\.audioEngine) private var audioEngine
    @Environment(\.tasteEngine) private var tasteEngine
    @Environment(\.settings) private var settings
    @Environment(\.queueController) private var queueController

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
        case .statistics:
            StatisticsView(libraryEngine: libraryEngine)
        case .settings:
            SettingsView(settings: settings)
        case .social:
            SocialView()
        case .queue:
            QueueView(queueController: queueController, libraryEngine: libraryEngine)
        case .album(_), .artist(_), .player(_), .library, .search,
             .discover, .home, .downloads:
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
        default: return "Coming soon"
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

private struct DiscoverTab: View {
    @Environment(\.tasteEngine) private var tasteEngine
    @Environment(\.libraryEngine) private var libraryEngine
    @Environment(\.dspEngine) private var dspEngine

    var body: some View {
        NavigationStack {
            DiscoverView(
                tasteEngine: tasteEngine,
                libraryEngine: libraryEngine,
                dspEngine: dspEngine
            )
        }
    }
}

private struct HomeTab: View {
    @Environment(\.libraryEngine) private var libraryEngine
    @Environment(\.downloadEngine) private var downloadEngine
    @Environment(\.tasteEngine) private var tasteEngine
    @Environment(\.audioEngine) private var audioEngine
    @Environment(\.dspEngine) private var dspEngine

    var body: some View {
        NavigationStack {
            HomeView(
                libraryEngine: libraryEngine,
                downloadEngine: downloadEngine,
                tasteEngine: tasteEngine,
                audioEngine: audioEngine,
                dspEngine: dspEngine
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
