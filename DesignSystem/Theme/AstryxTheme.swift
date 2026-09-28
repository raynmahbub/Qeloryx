// QELORYX — DesignSystem
// AstryxTheme.swift
// Composition of Midnight Aurora theme

import SwiftUI

// MARK: - AstryxTheme

public struct AstryxTheme {
    public let colors: AstryxColors.Type
    public let typography: AstryxTypography.Type
    public let spacing: AstryxSpacing.Type
    public let cornerRadius: AstryxCornerRadius.Type
    
    public static let midnightAurora = AstryxTheme(
        colors: AstryxColors.self,
        typography: AstryxTypography.self,
        spacing: AstryxSpacing.self,
        cornerRadius: AstryxCornerRadius.self
    )
}

// MARK: - Environment

private struct AstryxThemeKey: EnvironmentKey {
    static let defaultValue = AstryxTheme.midnightAurora
}

public extension EnvironmentValues {
    var astrixTheme: AstryxTheme {
        get { self[AstryxThemeKey.self] }
        set { self[AstryxThemeKey.self] = newValue }
    }
}

// MARK: - Theme View Modifier

public struct AstryxThemeModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .preferredColorScheme(.dark) // Midnight Aurora is dark-first
            .tint(AstryxColors.auroraBlue)
    }
}

public extension View {
    func astrixTheme() -> some View {
        modifier(AstryxThemeModifier())
    }
}
