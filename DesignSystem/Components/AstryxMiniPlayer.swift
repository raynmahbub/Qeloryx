// QELORYX — DesignSystem
// AstryxMiniPlayer.swift
// Persistent bottom player per spec

#if canImport(QeloryxCore)
import QeloryxCore
#endif

import SwiftUI

public struct AstryxMiniPlayer: View {
    
    let title: String
    let artist: String
    let artworkData: Data?
    let isPlaying: Bool
    let progress: Double // 0-1
    
    let onPlayPause: () -> Void
    let onNext: () -> Void
    let onTap: () -> Void
    
    public init(
        title: String,
        artist: String,
        artworkData: Data? = nil,
        isPlaying: Bool,
        progress: Double,
        onPlayPause: @escaping () -> Void,
        onNext: @escaping () -> Void,
        onTap: @escaping () -> Void
    ) {
        self.title = title
        self.artist = artist
        self.artworkData = artworkData
        self.isPlaying = isPlaying
        self.progress = progress
        self.onPlayPause = onPlayPause
        self.onNext = onNext
        self.onTap = onTap
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: AstryxSpacing.sm) {
                AstryxArtwork(data: artworkData, size: 48)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AstryxTypography.Label.medium)
                        .foregroundColor(AstryxColors.Semantic.foreground)
                        .lineLimit(1)
                    Text(artist)
                        .font(AstryxTypography.Body.small)
                        .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Button(action: onPlayPause) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AstryxColors.Semantic.foreground)
                }
                
                Button(action: onNext) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AstryxColors.Semantic.foreground)
                }
            }
            .padding(AstryxSpacing.sm)
            .background(.ultraThinMaterial)
            .background(AstryxColors.Semantic.backgroundSecondary.opacity(0.8))
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(AstryxColors.Semantic.surface)
                        .frame(height: 2)
                    Rectangle()
                        .fill(AstryxColors.auroraBlue)
                        .frame(width: geo.size.width * progress, height: 2)
                }
            }
            .frame(height: 2)
        }
        .clipShape(RoundedRectangle(cornerRadius: AstryxCornerRadius.md))
        .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: -4)
        .onTapGesture(perform: onTap)
    }
}
