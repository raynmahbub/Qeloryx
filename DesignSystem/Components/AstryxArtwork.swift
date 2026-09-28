// QELORYX — DesignSystem
// AstryxArtwork.swift
// Album artwork is primary visual anchor per spec

#if canImport(QeloryxCore)
import QeloryxCore
#endif

import SwiftUI

public struct AstryxArtwork: View {
    
    let data: Data?
    let size: CGFloat
    let cornerRadius: CGFloat
    
    public init(data: Data? = nil, size: CGFloat = 56, cornerRadius: CGFloat = AstryxCornerRadius.artwork) {
        self.data = data
        self.size = size
        self.cornerRadius = cornerRadius
    }
    
    public var body: some View {
        Group {
            if let data = data, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                // Placeholder with gradient
                ZStack {
                    AstryxColors.Gradients.aurora
                    Image(systemName: "music.note")
                        .font(.system(size: size * 0.4))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(AstryxColors.Semantic.border, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Artwork with Transition

public struct AstryxArtworkTransition: View {
    let currentData: Data?
    let size: CGFloat
    
    @State private var isTransitioning = false
    
    public init(currentData: Data?, size: CGFloat = 300) {
        self.currentData = currentData
        self.size = size
    }
    
    public var body: some View {
        AstryxArtwork(data: currentData, size: size, cornerRadius: AstryxCornerRadius.lg)
            .scaleEffect(isTransitioning ? 0.95 : 1.0)
            .animation(AstryxAnimation.artwork, value: isTransitioning)
            .onChange(of: currentData) { _ in
                isTransitioning = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isTransitioning = false
                }
            }
    }
}
