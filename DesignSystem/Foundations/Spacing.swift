// QELORYX — DesignSystem
// Spacing.swift
// 4pt grid

#if canImport(QeloryxCore)
import QeloryxCore
#endif

import SwiftUI

public struct AstryxSpacing {
    public static let xxs: CGFloat = 4
    public static let xs: CGFloat = 8
    public static let sm: CGFloat = 12
    public static let md: CGFloat = 16
    public static let lg: CGFloat = 20
    public static let xl: CGFloat = 24
    public static let xxl: CGFloat = 32
    public static let xxxl: CGFloat = 40
    public static let huge: CGFloat = 48
    
    // Semantic
    public static let cardPadding: CGFloat = 16
    public static let screenPadding: CGFloat = 20
    public static let sectionSpacing: CGFloat = 32
    public static let itemSpacing: CGFloat = 12
}

public struct AstryxCornerRadius {
    public static let xs: CGFloat = 8
    public static let sm: CGFloat = 12
    public static let md: CGFloat = 16
    public static let lg: CGFloat = 24
    public static let xl: CGFloat = 32
    public static let full: CGFloat = 9999
    
    // Semantic
    public static let card: CGFloat = 16
    public static let button: CGFloat = 12
    public static let artwork: CGFloat = 12
    public static let sheet: CGFloat = 24
}

public struct AstryxAnimation {
    public static let quick = Animation.spring(response: 0.3, dampingFraction: 0.8)
    public static let smooth = Animation.spring(response: 0.5, dampingFraction: 0.8)
    public static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)
    public static let artwork = Animation.spring(response: 0.6, dampingFraction: 0.75)
}
