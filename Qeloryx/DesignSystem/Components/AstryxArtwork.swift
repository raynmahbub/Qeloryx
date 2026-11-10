// QELORYX — DesignSystem
// AstryxArtwork.swift
// Album artwork is primary visual anchor per spec

#if canImport(QeloryxCore)
import QeloryxCore
#endif

import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public struct AstryxArtwork: View {
    
    let data: Data?
    let size: CGFloat
    let cornerRadius: CGFloat
    
    public init(data: Data? = nil, size: CGFloat = 56, cornerRadius: CGFloat = AstryxCornerRadius.artwork) {
        self.data = data
        self.size = size
        self.cornerRadius = cornerRadius
    }

    private static func makeImage(from data: Data) -> Image? {
        #if canImport(UIKit)
        guard let uiImage = UIImage(data: data) else { return nil }
        return Image(uiImage: uiImage)
        #elseif canImport(AppKit)
        guard let nsImage = NSImage(data: data) else { return nil }
        return Image(nsImage: nsImage)
        #else
        return nil
        #endif
    }

    public var body: some View {
        Group {
            if let data = data, let image = Self.makeImage(from: data) {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                placeholder
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

    // Placeholder with gradient
    private var placeholder: some View {
        ZStack {
            AstryxColors.Gradients.aurora
            Image(systemName: "music.note")
                .font(.system(size: size * 0.4))
                .foregroundColor(.white.opacity(0.8))
        }
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
