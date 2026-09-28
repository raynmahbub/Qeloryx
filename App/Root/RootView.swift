// QELORYX — App
// RootView.swift
// QEL-012 Player — Production root with enhanced mini player, queue, player sheet

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
                LibraryRootView()
                    .tabItem { Label(AppTab.library.rawValue, systemImage: AppTab.library.icon) }
                    .tag(AppTab.library)
                SearchRootView()
                    .tabItem { Label(AppTab.search.rawValue, systemImage: AppTab.search.icon) }
                    .tag(AppTab.search)
                DashboardRootView()
                    .tabItem { Label(AppTab.dashboard.rawValue, systemImage: AppTab.dashboard.icon) }
                    .tag(AppTab.dashboard)
            }
            .tint(AstryxColors.auroraBlue)
            
            if playerViewModel.playbackState.currentTrackID != nil {
                EnhancedMiniPlayer(viewModel: playerViewModel) {
                    coordinator.presentPlayer()
                }
                .padding(.horizontal, AstryxSpacing.sm)
                .padding(.bottom, 49 + AstryxSpacing.sm)
                .transition(.move(edge: .bottom).combined(with: .opacity))
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
                        .animation(AstryxAnimation.artwork, value: viewModel.isArtworkTransitioning)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.currentTrack?.title ?? "No Track").font(AstryxTypography.Label.medium).foregroundColor(AstryxColors.Semantic.foreground).lineLimit(1)
                    HStack(spacing: 4) {
                        Text(viewModel.currentTrack?.artist ?? "Unknown Artist").font(AstryxTypography.Body.small).foregroundColor(AstryxColors.Semantic.foregroundSecondary).lineLimit(1)
                        if viewModel.currentTrack?.isLossless == true {
                            Image(systemName: "waveform").font(.system(size: 8)).foregroundColor(AstryxColors.emerald)
                        }
                    }
                }
                Spacer()
                Button { Task { await viewModel.playPause() } } label: {
                    Image(systemName: viewModel.playbackState.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 20, weight: .semibold)).foregroundColor(AstryxColors.Semantic.foreground)
                        .frame(width: 36, height: 36).background(AstryxColors.Semantic.surface.opacity(0.6)).clipShape(Circle())
                }
                Button { Task { await viewModel.next() } } label: {
                    Image(systemName: "forward.fill").font(.system(size: 18)).foregroundColor(AstryxColors.Semantic.foreground).frame(width: 36, height: 36)
                }
            }
            .padding(AstryxSpacing.sm)
            .background(.ultraThinMaterial).background(AstryxColors.Semantic.backgroundSecondary.opacity(0.8))
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(AstryxColors.Semantic.surface).frame(height: 2)
                    Rectangle().fill(AstryxColors.auroraBlue).frame(width: geo.size.width * viewModel.progress, height: 2).animation(AstryxAnimation.quick, value: viewModel.progress)
                }
            }
            .frame(height: 2)
        }
        .clipShape(RoundedRectangle(cornerRadius: AstryxCornerRadius.md))
        .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: -4)
        .onTapGesture(perform: onTap)
    }
}

private struct LibraryRootView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: AstryxSpacing.lg) {
                AstryxLargeNavigationBar(title: "Library", subtitle: "Offline-first • \(AppConfiguration.current.version)")
                VStack(spacing: AstryxSpacing.md) {
                    Image(systemName: "music.note.list").font(.system(size: 48)).foregroundColor(AstryxColors.auroraBlue)
                    Text("Library DNA").font(AstryxTypography.Heading.h2).foregroundColor(AstryxColors.Semantic.foreground)
                    Text("Multi-library • Album grouping • Artist grouping • Genre • Folder view • Favorites • History • Recently Added").font(AstryxTypography.Body.small).foregroundColor(AstryxColors.Semantic.foregroundSecondary).multilineTextAlignment(.center).padding(.horizontal)
                    AstryxButton(title: "Start Indexing", style: .secondary, icon: "arrow.triangle.2.circlepath") {}
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
                AstryxLargeNavigationBar(title: "Search", subtitle: "Instant • <50ms target • QEL-012")
                VStack(spacing: AstryxSpacing.md) {
                    Image(systemName: "magnifyingglass").font(.system(size: 48)).foregroundColor(AstryxColors.auroraBlue)
                    Text("Universal Search").font(AstryxTypography.Heading.h2).foregroundColor(AstryxColors.Semantic.foreground)
                    Text("Song • Artist • Album • Playlist • Folder • Lyrics • Command palette").font(AstryxTypography.Body.small).foregroundColor(AstryxColors.Semantic.foregroundSecondary)
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
            ScrollView {
                VStack(spacing: AstryxSpacing.lg) {
                    AstryxLargeNavigationBar(title: "QELORYX", subtitle: "Hear Beyond. Build Beyond. • Player Milestone")
                    VStack(spacing: AstryxSpacing.md) {
                        Text("QELORYX").font(AstryxTypography.Logo.largeSystem).foregroundColor(AstryxColors.auroraBlue)
                        Text("Midnight Aurora").font(AstryxTypography.Heading.h4).foregroundColor(AstryxColors.Semantic.foreground)
                        Text("\(AppConfiguration.current.version) • QEL-012 Player • AVFoundation + Now Playing + Live Activity + AirPlay").font(AstryxTypography.Body.caption).foregroundColor(AstryxColors.Semantic.foregroundTertiary).multilineTextAlignment(.center).padding(.horizontal)
                        HStack(spacing: AstryxSpacing.sm) {
                            AstryxButton(title: "Audio Lab", style: .secondary, icon: "waveform") {}
                            AstryxButton(title: "Taste DNA", style: .secondary, icon: "heart") {}
                        }
                        .padding(.horizontal)
                    }
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AstryxSpacing.md) {
                        ForEach(playerCapabilities, id: \.title) { cap in
                            AstryxCard {
                                VStack(spacing: AstryxSpacing.xs) {
                                    Image(systemName: cap.icon).font(.system(size: 24)).foregroundColor(AstryxColors.auroraBlue)
                                    Text(cap.title).font(AstryxTypography.Label.small)
                                    Text(cap.status).font(AstryxTypography.Body.caption2).foregroundColor(AstryxColors.Semantic.foregroundTertiary)
                                }
                                .frame(height: 80).frame(maxWidth: .infinity).padding(AstryxSpacing.sm)
                            }
                        }
                    }
                    .padding(.horizontal, AstryxSpacing.screenPadding)
                }
            }
            .background(AstryxColors.Semantic.background)
        }
    }
    private var playerCapabilities: [(title: String, icon: String, status: String)] {
        [
            ("Play/Pause", "playpause.fill", "✅ Implemented"),
            ("Seek", "waveform", "✅ Implemented"),
            ("Queue", "list.bullet", "✅ Implemented"),
            ("Shuffle", "shuffle", "✅ Implemented"),
            ("Repeat", "repeat", "✅ Implemented"),
            ("Background", "moon.fill", "✅ Implemented"),
            ("Lock Screen", "lock.display", "✅ Implemented"),
            ("Dynamic Island", "iphone", "✅ Implemented"),
            ("AirPlay", "airplayaudio", "✅ Implemented"),
            ("Haptics", "hand.tap.fill", "✅ Implemented"),
            ("Artwork Trans.", "photo.transition", "✅ Implemented"),
            ("Now Playing", "dot.radiowaves.left.and.right", "✅ Implemented")
        ]
    }
}
