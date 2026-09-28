// QELORYX — DesignSystem
// AstryxColors.swift
// Midnight Aurora Theme

import SwiftUI

// MARK: - AstryxColors

public struct AstryxColors {
    
    // MARK: - Core Tokens (from Bible)
    public static let auroraBlue = Color(hex: "#3B82F6")
    public static let midnight = Color(hex: "#050816")
    public static let emerald = Color(hex: "#10B981")
    public static let sunset = Color(hex: "#F97316")
    public static let iceWhite = Color(hex: "#F8FAFC")
    
    // MARK: - Midnight Variants
    public struct Midnight {
        public static let _900 = Color(hex: "#050816") // Primary background
        public static let _800 = Color(hex: "#0F172A")
        public static let _700 = Color(hex: "#1E293B")
        public static let _600 = Color(hex: "#334155")
        public static let _500 = Color(hex: "#475569")
    }
    
    // MARK: - Aurora Blue Variants
    public struct Aurora {
        public static let _600 = Color(hex: "#2563EB")
        public static let _500 = Color(hex: "#3B82F6") // Primary
        public static let _400 = Color(hex: "#60A5FA")
        public static let _300 = Color(hex: "#93C5FD")
        public static let _200 = Color(hex: "#BFDBFE")
        public static let _100 = Color(hex: "#DBEAFE")
    }
    
    // MARK: - Semantic
    public struct Semantic {
        public static let background = Midnight._900
        public static let backgroundSecondary = Midnight._800
        public static let surface = Midnight._700
        public static let surfaceElevated = Midnight._600
        
        public static let foreground = Color(hex: "#F8FAFC")
        public static let foregroundSecondary = Color(hex: "#CBD5E1")
        public static let foregroundTertiary = Color(hex: "#94A3B8")
        
        public static let border = Color(hex: "#1E293B")
        public static let borderStrong = Color(hex: "#334155")
        
        public static let primary = Aurora._500
        public static let primaryHover = Aurora._400
        public static let primaryActive = Aurora._600
        
        public static let success = Color(hex: "#10B981")
        public static let warning = Color(hex: "#F97316")
        public static let error = Color(hex: "#EF4444")
        
        public static let muted = Color(hex: "#64748B")
    }
    
    // MARK: - Gradients
    public struct Gradients {
        public static let aurora = LinearGradient(
            colors: [Color(hex: "#3B82F6"), Color(hex: "#8B5CF6"), Color(hex: "#06B6D4")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        public static let midnight = LinearGradient(
            colors: [Color(hex: "#050816"), Color(hex: "#0F172A")],
            startPoint: .top,
            endPoint: .bottom
        )
        
        public static let card = LinearGradient(
            colors: [Color(hex: "#1E293B"), Color(hex: "#0F172A")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        public static let artworkOverlay = LinearGradient(
            colors: [Color.clear, Color.black.opacity(0.8)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Color Hex Extension

public extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview Helper

#if DEBUG
public extension AstryxColors {
    static var previewPalette: [(String, Color)] {
        [
            ("Aurora Blue", auroraBlue),
            ("Midnight", midnight),
            ("Emerald", emerald),
            ("Sunset", sunset),
            ("Ice White", iceWhite),
            ("Midnight 800", Midnight._800),
            ("Midnight 700", Midnight._700),
            ("Aurora 400", Aurora._400)
        ]
    }
}
#endif
