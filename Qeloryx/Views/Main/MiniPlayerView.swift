// QELORYX — Views/Main
// MiniPlayerView.swift
// The persistent mini player shown above the tab bar while a track is loaded.
// Extracted from RootView.swift; unchanged behaviour.

import SwiftUI

// MARK: - Mini Player


struct MiniPlayerView: View {
    @ObservedObject var viewModel: PlayerViewModel
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
