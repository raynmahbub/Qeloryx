// QELORYX — AstryxAudioEngine
// GaplessPlayback.swift
// Feature benchmark: gapless playback + crossfade (Petrichor, koan, eko-web)
// Original Qeloryx implementation — pure overlap/gain math, no copied code

import Foundation

// MARK: - Playback Settings

/// User-configurable gapless / crossfade behavior.
public struct AstryxPlaybackSettings: Sendable, Equatable {
    /// Preload and seamlessly chain the next queue item (no silence between tracks).
    public var gaplessEnabled: Bool
    /// Crossfade length in seconds. 0 disables crossfading even when gapless is on.
    public var crossfadeDuration: TimeInterval
    
    public static let `default` = AstryxPlaybackSettings(gaplessEnabled: true, crossfadeDuration: 0)
    public static let maxCrossfadeDuration: TimeInterval = 12.0
    
    public init(gaplessEnabled: Bool = true, crossfadeDuration: TimeInterval = 0) {
        self.gaplessEnabled = gaplessEnabled
        self.crossfadeDuration = min(max(crossfadeDuration, 0), AstryxPlaybackSettings.maxCrossfadeDuration)
    }
    
    /// True when tracks actually overlap (gapless on AND a positive crossfade length).
    public var isCrossfadeActive: Bool {
        gaplessEnabled && crossfadeDuration > 0
    }
}

// MARK: - Crossfade Curve

public enum AstryxCrossfadeCurve: String, Sendable, CaseIterable, Equatable {
    /// Linear amplitude ramp — simple, can dip in perceived loudness mid-fade.
    case linear
    /// Equal-power (cosine/sine) ramp — constant perceived loudness across the fade.
    case equalPower
    
    public var displayName: String {
        switch self {
        case .linear: return "Linear"
        case .equalPower: return "Equal Power"
        }
    }
}

// MARK: - Crossfade Plan

/// Describes a single crossfade between an outgoing and an incoming track.
/// Pure value type — the platform adapter renders it with actual audio.
public struct AstryxCrossfadePlan: Sendable, Equatable {
    /// Overlap length in seconds.
    public let overlap: TimeInterval
    public let curve: AstryxCrossfadeCurve
    
    public init(overlap: TimeInterval, curve: AstryxCrossfadeCurve = .equalPower) {
        self.overlap = max(0, overlap)
        self.curve = curve
    }
    
    public static func plan(settings: AstryxPlaybackSettings, curve: AstryxCrossfadeCurve = .equalPower) -> AstryxCrossfadePlan? {
        guard settings.isCrossfadeActive else { return nil }
        return AstryxCrossfadePlan(overlap: settings.crossfadeDuration, curve: curve)
    }
    
    /// Normalized progress of the fade at time `t` (0 at fade start, 1 at fade end).
    public var progress: (TimeInterval) -> Double {
        { [overlap] t in
            guard overlap > 0 else { return 1 }
            return min(1, max(0, t / overlap))
        }
    }
    
    /// Gain pair (outgoing, incoming) at time `t` within the overlap window.
    public func gains(at t: TimeInterval) -> (outgoing: Float, incoming: Float) {
        let p = progress(t)
        switch curve {
        case .linear:
            return (Float(1 - p), Float(p))
        case .equalPower:
            let angle = p * Double.pi / 2
            return (Float(cos(angle)), Float(sin(angle)))
        }
    }
}
