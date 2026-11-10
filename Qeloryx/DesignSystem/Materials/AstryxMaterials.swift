// QELORYX — DesignSystem/Materials
// AstryxMaterials.swift
// Semantic material presets. Views pick a *role*, never a raw Material —
// this is what keeps translucency consistent across screens.

import SwiftUI

public enum AstryxMaterials {
    /// Raised surface: mini player, floating controls.
    public static let elevated: Material = .ultraThinMaterial
    /// Card background fill paired with `AstryxCard`.
    public static let card: Material = .thinMaterial
    /// Full-screen overlay behind player artwork and lyrics.
    public static let overlay: Material = .regularMaterial
    /// Dimming scrim for modals; use with a black opacity, not alone.
    public static let scrim: Material = .thickMaterial
}
