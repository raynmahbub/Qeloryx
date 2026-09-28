// QELORYX — Features/Player
// AstryxPlayerView.swift
// QEL-012 Player — Premium full-screen player with Midnight Aurora, artwork transitions, haptics

import SwiftUI

public struct AstryxPlayerView: View {
    
    @StateObject private var viewModel: AstryxPlayerViewModel
    @State private var showQueue = false
    @State private var showAirPlay = false
    @Environment(\.dismiss) private var dismiss
    
    public init(viewModel: AstryxPlayerViewModel = AstryxPlayerViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        ZStack {
            backgroundView
            VStack(spacing: 0) {
                navigationBar
                artworkSection.padding(.top, AstryxSpacing.lg)
                trackInfoSection.padding(.top, AstryxSpacing.xl)
                seekSection.padding(.top, AstryxSpacing.xl).padding(.horizontal, AstryxSpacing.screenPadding)
                controlsSection.padding(.top, AstryxSpacing.xl)
                secondaryControls.padding(.top, AstryxSpacing.xl)
                Spacer()
                if !viewModel.upNext.isEmpty { upNextSection }
            }
            .padding(.bottom, AstryxSpacing.xl)
        }
        .background(AstryxColors.Semantic.background.ignoresSafeArea())
        .sheet(isPresented: $showQueue) { AstryxQueueView(viewModel: viewModel) }
        .sheet(isPresented: $showAirPlay) { AirPlayView() }
    }
    
    private var backgroundView: some View {
        ZStack {
            AstryxColors.Semantic.background.ignoresSafeArea()
            if let data = viewModel.currentArtworkData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .blur(radius: 60)
                    .opacity(0.3)
                    .ignoresSafeArea()
                    .overlay(
                        LinearGradient(colors: [AstryxColors.Semantic.background.opacity(0.2), AstryxColors.Semantic.background], startPoint: .top, endPoint: .bottom)
                            .ignoresSafeArea()
                    )
            } else {
                AstryxColors.Gradients.midnight.ignoresSafeArea()
            }
        }
    }
    
    private var navigationBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AstryxColors.Semantic.foreground)
                    .frame(width: 36, height: 36)
                    .background(AstryxColors.Semantic.surface.opacity(0.6))
                    .clipShape(Circle())
            }
            Spacer()
            Text("Now Playing").font(AstryxTypography.Label.medium).foregroundColor(AstryxColors.Semantic.foregroundSecondary)
            Spacer()
            Menu {
                Button(action: {}) { Label("Share", systemImage: "square.and.arrow.up") }
                Button(action: {}) { Label("Add to Playlist", systemImage: "plus") }
                Button(action: {}) { Label("Go to Album", systemImage: "rectangle.stack") }
                Button(action: {}) { Label("Go to Artist", systemImage: "person") }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AstryxColors.Semantic.foreground)
                    .frame(width: 36, height: 36)
                    .background(AstryxColors.Semantic.surface.opacity(0.6))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, AstryxSpacing.screenPadding)
    }
    
    private var artworkSection: some View {
        ZStack {
            if let prevData = viewModel.previousArtworkData, viewModel.isArtworkTransitioning {
                AstryxArtwork(data: prevData, size: 320, cornerRadius: AstryxCornerRadius.lg)
                    .opacity(0.5).scaleEffect(0.95)
            }
            AstryxArtwork(data: viewModel.currentArtworkData, size: 320, cornerRadius: AstryxCornerRadius.lg)
                .scaleEffect(viewModel.isArtworkTransitioning ? 0.98 : 1.0)
                .animation(AstryxAnimation.artwork, value: viewModel.isArtworkTransitioning)
                .shadow(color: Color.black.opacity(0.4), radius: 24, x: 0, y: 12)
        }
        .frame(height: 320)
    }
    
    private var trackInfoSection: some View {
        VStack(spacing: AstryxSpacing.xs) {
            Text(viewModel.currentTrack?.title ?? "No Track")
                .font(AstryxTypography.Heading.h2)
                .foregroundColor(AstryxColors.Semantic.foreground)
                .lineLimit(1).multilineTextAlignment(.center)
            Text(viewModel.currentTrack?.artist ?? "Unknown Artist")
                .font(AstryxTypography.Body.large)
                .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                .lineLimit(1)
            if let album = viewModel.currentTrack?.album, !album.isEmpty {
                Text(album).font(AstryxTypography.Body.small).foregroundColor(AstryxColors.Semantic.foregroundTertiary).lineLimit(1)
            }
            if viewModel.currentTrack?.isLossless == true {
                HStack(spacing: 4) {
                    Image(systemName: "waveform").font(.system(size: 10))
                    Text(viewModel.currentTrack?.fileFormat.rawValue ?? "LOSSLESS").font(AstryxTypography.Label.tiny)
                }
                .foregroundColor(AstryxColors.emerald)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(AstryxColors.emerald.opacity(0.15))
                .clipShape(Capsule()).padding(.top, 4)
            }
        }
        .padding(.horizontal, AstryxSpacing.screenPadding)
    }
    
    private var seekSection: some View {
        VStack(spacing: AstryxSpacing.sm) {
            Slider(value: Binding(
                get: { viewModel.position },
                set: { newValue in
                    viewModel.isSeeking = true
                    viewModel.position = newValue
                }
            ), in: 0...(viewModel.duration > 0 ? viewModel.duration : 1), onEditingChanged: { editing in
                viewModel.isSeeking = editing
                if !editing { Task { await viewModel.seek(to: viewModel.position) } }
            })
            .tint(AstryxColors.auroraBlue)
            HStack {
                Text(viewModel.formattedPosition).font(AstryxTypography.Body.caption).foregroundColor(AstryxColors.Semantic.foregroundTertiary)
                Spacer()
                Text(viewModel.formattedDuration).font(AstryxTypography.Body.caption).foregroundColor(AstryxColors.Semantic.foregroundTertiary)
            }
        }
    }
    
    private var controlsSection: some View {
        HStack(spacing: AstryxSpacing.xl) {
            Button { Task { await viewModel.toggleShuffle() } } label: {
                Image(systemName: "shuffle").font(.system(size: 20, weight: .medium))
                    .foregroundColor(viewModel.isShuffleEnabled ? AstryxColors.auroraBlue : AstryxColors.Semantic.foregroundSecondary)
                    .frame(width: 44, height: 44)
            }
            Button { Task { await viewModel.previous() } } label: {
                Image(systemName: "backward.fill").font(.system(size: 28)).foregroundColor(AstryxColors.Semantic.foreground).frame(width: 56, height: 56)
            }
            Button { Task { await viewModel.playPause() } } label: {
                ZStack {
                    Circle().fill(AstryxColors.auroraBlue).frame(width: 72, height: 72).shadow(color: AstryxColors.auroraBlue.opacity(0.4), radius: 12, x: 0, y: 4)
                    Image(systemName: viewModel.playbackState.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 28, weight: .semibold)).foregroundColor(AstryxColors.iceWhite)
                        .offset(x: viewModel.playbackState.isPlaying ? 0 : 2)
                }
            }
            .scaleEffect(viewModel.playbackState.isPlaying ? 1.0 : 1.05).animation(AstryxAnimation.bouncy, value: viewModel.playbackState.isPlaying)
            Button { Task { await viewModel.next() } } label: {
                Image(systemName: "forward.fill").font(.system(size: 28)).foregroundColor(AstryxColors.Semantic.foreground).frame(width: 56, height: 56)
            }
            Button { Task { await viewModel.toggleRepeat() } } label: {
                ZStack {
                    Image(systemName: viewModel.repeatMode == .one ? "repeat.1" : "repeat")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(viewModel.repeatMode != .off ? AstryxColors.auroraBlue : AstryxColors.Semantic.foregroundSecondary)
                    if viewModel.repeatMode != .off {
                        Circle().fill(AstryxColors.auroraBlue).frame(width: 4, height: 4).offset(y: 12)
                    }
                }
                .frame(width: 44, height: 44)
            }
        }
    }
    
    private var secondaryControls: some View {
        HStack(spacing: AstryxSpacing.xl) {
            Button { showQueue = true } label: {
                VStack(spacing: 4) {
                    Image(systemName: "list.bullet").font(.system(size: 18))
                    Text("Queue").font(AstryxTypography.Body.caption2)
                }
                .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
            }
            Spacer()
            Button { showAirPlay = true } label: {
                VStack(spacing: 4) {
                    Image(systemName: "airplayaudio").font(.system(size: 18)).foregroundColor(viewModel.isAirPlayActive ? AstryxColors.auroraBlue : AstryxColors.Semantic.foregroundSecondary)
                    Text("AirPlay").font(AstryxTypography.Body.caption2)
                }
                .foregroundColor(viewModel.isAirPlayActive ? AstryxColors.auroraBlue : AstryxColors.Semantic.foregroundSecondary)
            }
            Spacer()
            Button {} label: {
                VStack(spacing: 4) {
                    Image(systemName: "waveform").font(.system(size: 18))
                    Text("Audio Lab").font(AstryxTypography.Body.caption2)
                }
                .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
            }
        }
        .padding(.horizontal, AstryxSpacing.xxl)
    }
    
    private var upNextSection: some View {
        VStack(alignment: .leading, spacing: AstryxSpacing.sm) {
            HStack {
                Text("Up Next").font(AstryxTypography.Label.small).foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                Spacer()
                Button("Queue") { showQueue = true }.font(AstryxTypography.Label.small).foregroundColor(AstryxColors.auroraBlue)
            }
            .padding(.horizontal, AstryxSpacing.screenPadding)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AstryxSpacing.sm) {
                    ForEach(viewModel.upNext, id: \.id) { track in
                        VStack(alignment: .leading, spacing: 4) {
                            AstryxArtwork(data: track.artworkData, size: 48)
                            Text(track.title).font(AstryxTypography.Body.caption).lineLimit(1).frame(width: 48)
                        }
                        .onTapGesture { Task { await viewModel.playTrack(id: track.id) } }
                    }
                }
                .padding(.horizontal, AstryxSpacing.screenPadding)
            }
        }
    }
}

public struct AstryxQueueView: View {
    @ObservedObject var viewModel: AstryxPlayerViewModel
    @Environment(\.dismiss) private var dismiss
    public init(viewModel: AstryxPlayerViewModel) { self.viewModel = viewModel }
    public var body: some View {
        NavigationStack {
            List {
                if let current = viewModel.currentTrack {
                    Section("Now Playing") {
                        HStack {
                            AstryxArtwork(data: current.artworkData, size: 48)
                            VStack(alignment: .leading) {
                                Text(current.title).font(AstryxTypography.Label.medium)
                                Text(current.artist).font(AstryxTypography.Body.small)
                            }
                            Spacer()
                            Image(systemName: "waveform").foregroundColor(AstryxColors.auroraBlue)
                        }
                    }
                }
                Section("Up Next (\(viewModel.queue.count) tracks)") {
                    ForEach(Array(viewModel.queue.items.enumerated()), id: \.element.id) { index, item in
                        HStack {
                            Text("\(index + 1)").font(AstryxTypography.Body.caption).foregroundColor(AstryxColors.Semantic.foregroundTertiary).frame(width: 20)
                            VStack(alignment: .leading) {
                                Text("Track \(item.trackID.prefix(8))").font(AstryxTypography.Label.small)
                                Text(item.source.rawValue).font(AstryxTypography.Body.caption2).foregroundColor(AstryxColors.Semantic.foregroundTertiary)
                            }
                            Spacer()
                            if viewModel.queue.currentIndex == index {
                                Image(systemName: "speaker.wave.2.fill").foregroundColor(AstryxColors.auroraBlue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { Task { await viewModel.playTrack(id: item.trackID) } }
                    }
                }
            }
            .navigationTitle("Queue").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() } }
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button("Clear Queue", role: .destructive) {}
                        Button("Shuffle Queue") { Task { await viewModel.toggleShuffle() } }
                    } label: { Image(systemName: "ellipsis") }
                }
            }
        }
    }
}

private struct AirPlayView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: AstryxSpacing.lg) {
                Image(systemName: "airplayaudio").font(.system(size: 48)).foregroundColor(AstryxColors.auroraBlue)
                Text("AirPlay").font(AstryxTypography.Heading.h3)
                Text("Stream to HomePod, Apple TV, and AirPlay-enabled speakers").font(AstryxTypography.Body.small).multilineTextAlignment(.center).foregroundColor(AstryxColors.Semantic.foregroundSecondary).padding(.horizontal)
                AstryxButton(title: "Open AirPlay", style: .secondary, icon: "airplayaudio") {}
                    .padding(.horizontal, AstryxSpacing.xl)
                Spacer()
            }
            .padding(.top, AstryxSpacing.xxl)
            .navigationTitle("AirPlay").navigationBarTitleDisplayMode(.inline)
        }
    }
}
