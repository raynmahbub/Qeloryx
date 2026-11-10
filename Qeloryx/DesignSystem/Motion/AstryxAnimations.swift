// QELORYX — DesignSystem — Animations
// AstryxAnimations.swift
// QEL-051 Polish — Production animations, artwork transitions, haptics integration

#if canImport(QeloryxCore)
import QeloryxCore
#endif

import SwiftUI

public struct AstryxAnimations {
    
    // MARK: - Core Animations — Performance <16ms per frame (60fps)
    
    public static let quick = Animation.spring(response: 0.3, dampingFraction: 0.8)
    public static let smooth = Animation.spring(response: 0.5, dampingFraction: 0.8)
    public static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)
    public static let artwork = Animation.spring(response: 0.6, dampingFraction: 0.75)
    public static let gentle = Animation.easeInOut(duration: 0.3)
    public static let instant = Animation.linear(duration: 0.1)
    
    // MARK: - Semantic Animations
    
    public static let playPause = Animation.spring(response: 0.25, dampingFraction: 0.7)
    public static let tabChange = Animation.easeInOut(duration: 0.2)
    public static let cardAppear = Animation.spring(response: 0.4, dampingFraction: 0.8)
    public static let listInsert = Animation.spring(response: 0.35, dampingFraction: 0.75)
    public static let lyricHighlight = Animation.easeInOut(duration: 0.3)
    public static let karaokeWord = Animation.easeInOut(duration: 0.2)
    public static let downloadProgress = Animation.linear(duration: 0.3)
    public static let tasteDNA = Animation.spring(response: 0.6, dampingFraction: 0.7)
}

// MARK: - View Modifiers — Accessibility + Haptics

public struct AstryxAccessibleModifier: ViewModifier {
    let label: String
    let hint: String?
    let isButton: Bool
    
    public func body(content: Content) -> some View {
        content
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(isButton ? .isButton : [])
    }
}

public extension View {
    func astrixAccessible(label: String, hint: String? = nil, isButton: Bool = false) -> some View {
        modifier(AstryxAccessibleModifier(label: label, hint: hint, isButton: isButton))
    }
    
    func astrixCardAppear(delay: Double = 0) -> some View {
        self
            .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
            .animation(AstryxAnimations.cardAppear.delay(delay), value: UUID())
    }
    
    func astrixListRow() -> some View {
        self
            .animation(AstryxAnimations.listInsert, value: UUID())
    }
}

// MARK: - Artwork Transition — QEL-012 + QEL-051 Polish

public struct AstryxArtworkTransitionModifier: ViewModifier {
    let isActive: Bool
    
    public func body(content: Content) -> some View {
        content
            .scaleEffect(isActive ? 1.0 : 0.95)
            .opacity(isActive ? 1.0 : 0.8)
            .animation(AstryxAnimations.artwork, value: isActive)
    }
}

public extension View {
    func astrixArtworkTransition(isActive: Bool) -> some View {
        modifier(AstryxArtworkTransitionModifier(isActive: isActive))
    }
}

// MARK: - Shimmer — Loading states

public struct AstryxShimmerModifier: ViewModifier {
    @State private var isAnimating = false
    
    public func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [Color.clear, Color.white.opacity(0.2), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 2)
                    .offset(x: isAnimating ? geo.size.width : -geo.size.width * 2)
                }
            )
            .clipped()
            .onAppear {
                withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

public extension View {
    func astrixShimmer() -> some View {
        modifier(AstryxShimmerModifier())
    }
}
