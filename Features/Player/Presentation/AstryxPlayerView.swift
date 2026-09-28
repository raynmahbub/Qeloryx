// QELORYX — Features/Player
// AstryxPlayerView.swift
// Premium player UI with Midnight Aurora

import SwiftUI

public struct AstryxPlayerView: View {
    
    @StateObject private var viewModel: AstryxPlayerViewModel
    @State private var isSeeking = false
    @State private var seekPosition: TimeInterval = 0
    
    public init(viewModel: AstryxPlayerViewModel = AstryxPlayerViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        ZStack {
            AstryxColors.Semantic.background.ignoresSafeArea()
            
            VStack(spacing: AstryxSpacing.xl) {
                // Navigation
                AstryxNavigationBar(title: "Now Playing", actions: [
                    AstryxNavAction(icon: "ellipsis") {}
                ])
                
                // Artwork — primary visual anchor
                AstryxArtworkTransition(currentData: viewModel.currentTrack?.artworkData, size: 300)
                    .padding(.top, AstryxSpacing.xl)
                
                // Track Info
                VStack(spacing: AstryxSpacing.xs) {
                    Text(viewModel.currentTrack?.title ?? "No Track")
                        .font(AstryxTypography.Heading.h2)
                        .foregroundColor(AstryxColors.Semantic.foreground)
                        .lineLimit(1)
                    
                    Text(viewModel.currentTrack?.artist ?? "Unknown Artist")
                        .font(AstryxTypography.Body.large)
                        .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                        .lineLimit(1)
                    
                    Text(viewModel.currentTrack?.album ?? "")
                        .font(AstryxTypography.Body.small)
                        .foregroundColor(AstryxColors.Semantic.foregroundTertiary)
                        .lineLimit(1)
                }
                .padding(.horizontal, AstryxSpacing.screenPadding)
                
                // Seek
                AstryxSeekSlider(position: $viewModel.position, duration: viewModel.duration) { newPos in
                    Task {
                        await viewModel.seek(to: newPos)
                    }
                }
                .padding(.horizontal, AstryxSpacing.screenPadding)
                
                // Controls
                HStack(spacing: AstryxSpacing.xl) {
                    Button {
                        Task { await viewModel.toggleShuffle() }
                    } label: {
                        Image(systemName: "shuffle")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(viewModel.isShuffleEnabled ? AstryxColors.auroraBlue : AstryxColors.Semantic.foregroundSecondary)
                    }
                    
                    Button {
                        Task { await viewModel.previous() }
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 28))
                            .foregroundColor(AstryxColors.Semantic.foreground)
                    }
                    
                    Button {
                        Task { await viewModel.playPause() }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(AstryxColors.auroraBlue)
                                .frame(width: 72, height: 72)
                            
                            Image(systemName: viewModel.playbackState.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 28))
                                .foregroundColor(AstryxColors.iceWhite)
                                .offset(x: viewModel.playbackState.isPlaying ? 0 : 2)
                        }
                    }
                    
                    Button {
                        Task { await viewModel.next() }
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 28))
                            .foregroundColor(AstryxColors.Semantic.foreground)
                    }
                    
                    Button {
                        Task { await viewModel.toggleRepeat() }
                    } label: {
                        Image(systemName: viewModel.repeatMode == .one ? "repeat.1" : "repeat")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(viewModel.repeatMode != .off ? AstryxColors.auroraBlue : AstryxColors.Semantic.foregroundSecondary)
                    }
                }
                .padding(.top, AstryxSpacing.lg)
                
                Spacer()
            }
        }
    }
}
