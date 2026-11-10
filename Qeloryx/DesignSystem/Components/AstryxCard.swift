// QELORYX — DesignSystem
// AstryxCard.swift

#if canImport(QeloryxCore)
import QeloryxCore
#endif

import SwiftUI

public enum AstryxCardStyle {
    case album
    case track
    case playlist
    case elevated
}

public struct AstryxCard<Content: View>: View {
    
    let style: AstryxCardStyle
    let content: Content
    
    public init(style: AstryxCardStyle = .album, @ViewBuilder content: () -> Content) {
        self.style = style
        self.content = content()
    }
    
    public var body: some View {
        content
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AstryxCornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: AstryxCornerRadius.card)
                    .stroke(AstryxColors.Semantic.border, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    private var cardBackground: some View {
        switch style {
        case .album, .track, .playlist:
            return AnyView(AstryxColors.Gradients.card)
        case .elevated:
            return AnyView(AstryxColors.Semantic.surfaceElevated)
        }
    }
}

// MARK: - Album Card (Artwork is primary visual anchor per spec)

public struct AstryxAlbumCard: View {
    let title: String
    let artist: String
    let artworkData: Data?
    
    public init(title: String, artist: String, artworkData: Data? = nil) {
        self.title = title
        self.artist = artist
        self.artworkData = artworkData
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: AstryxSpacing.sm) {
            AstryxArtwork(data: artworkData, size: 160)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AstryxTypography.Label.medium)
                    .foregroundColor(AstryxColors.Semantic.foreground)
                    .lineLimit(1)
                
                Text(artist)
                    .font(AstryxTypography.Body.small)
                    .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, AstryxSpacing.sm)
            .padding(.bottom, AstryxSpacing.sm)
        }
        .background(AstryxColors.Semantic.surface)
        .clipShape(RoundedRectangle(cornerRadius: AstryxCornerRadius.card))
    }
}
