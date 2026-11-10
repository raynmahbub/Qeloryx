// QELORYX — DesignSystem
// AstryxTypography.swift

#if canImport(QeloryxCore)
import QeloryxCore
#endif

import SwiftUI

// MARK: - AstryxTypography

public struct AstryxTypography {
    
    // MARK: - Logo
    // Space Grotesk per spec — fallback to system if not bundled yet
    public struct Logo {
        public static let large = Font.custom("SpaceGrotesk-Bold", size: 32, relativeTo: .largeTitle)
        public static let medium = Font.custom("SpaceGrotesk-Bold", size: 24, relativeTo: .title)
        public static let small = Font.custom("SpaceGrotesk-Medium", size: 18, relativeTo: .headline)
        
        // Fallback system fonts
        public static let largeSystem = Font.system(size: 32, weight: .bold, design: .rounded)
        public static let mediumSystem = Font.system(size: 24, weight: .bold, design: .rounded)
    }
    
    // MARK: - Heading (SF Pro Display)
    public struct Heading {
        public static let h1 = Font.system(size: 34, weight: .bold, design: .default) // Large Title
        public static let h2 = Font.system(size: 28, weight: .bold, design: .default) // Title1
        public static let h3 = Font.system(size: 22, weight: .semibold, design: .default) // Title2
        public static let h4 = Font.system(size: 20, weight: .semibold, design: .default) // Title3
        public static let h5 = Font.system(size: 17, weight: .semibold, design: .default) // Headline
    }
    
    // MARK: - Body (SF Pro Text)
    public struct Body {
        public static let large = Font.system(size: 17, weight: .regular, design: .default)
        public static let medium = Font.system(size: 15, weight: .regular, design: .default)
        public static let small = Font.system(size: 13, weight: .regular, design: .default)
        public static let caption = Font.system(size: 12, weight: .regular, design: .default)
        public static let caption2 = Font.system(size: 11, weight: .regular, design: .default)
    }
    
    // MARK: - Label
    public struct Label {
        public static let large = Font.system(size: 17, weight: .medium, design: .default)
        public static let medium = Font.system(size: 15, weight: .medium, design: .default)
        public static let small = Font.system(size: 13, weight: .medium, design: .default)
        public static let tiny = Font.system(size: 11, weight: .semibold, design: .default)
    }
    
    // MARK: - Mono (for Audio Lab diagnostics)
    public struct Mono {
        public static let medium = Font.system(size: 13, weight: .regular, design: .monospaced)
        public static let small = Font.system(size: 11, weight: .regular, design: .monospaced)
    }
}

// MARK: - Text Styles Extension

public extension Text {
    func astrixHeading1() -> some View {
        self.font(AstryxTypography.Heading.h1).foregroundColor(AstryxColors.Semantic.foreground)
    }
    
    func astrixHeading2() -> some View {
        self.font(AstryxTypography.Heading.h2).foregroundColor(AstryxColors.Semantic.foreground)
    }
    
    func astrixBody() -> some View {
        self.font(AstryxTypography.Body.medium).foregroundColor(AstryxColors.Semantic.foregroundSecondary)
    }
    
    func astrixCaption() -> some View {
        self.font(AstryxTypography.Body.caption).foregroundColor(AstryxColors.Semantic.foregroundTertiary)
    }
}
