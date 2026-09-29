// QELORYX — AstryxAudioEngine
// CrossfadeCurve.swift
// Sprint "Seamless Playback" — fade curves and configuration for gapless
// transitions. Independent clean-room implementation; the equal-power
// variant keeps total acoustic power constant through the overlap so the
// transition has no perceived loudness dip.

import Foundation

// MARK: - Fade Curve

public enum CrossfadeCurve: String, Sendable, CaseIterable, Equatable {
    case linear
    case equalPower
    case sCurve

    /// Outgoing deck gain for normalized progress (0...1). 1 → full, 0 → silent.
    public func fadeOutLevel(at progress: Double) -> Double {
        let p = CrossfadeCurve.clampProgress(progress)
        switch self {
        case .linear:
            return 1.0 - p
        case .equalPower:
            return cos(p * .pi / 2.0)
        case .sCurve:
            let smooth = p * p * (3.0 - 2.0 * p)
            return 1.0 - smooth
        }
    }

    /// Incoming deck gain for normalized progress (0...1). 0 → silent, 1 → full.
    public func fadeInLevel(at progress: Double) -> Double {
        let p = CrossfadeCurve.clampProgress(progress)
        switch self {
        case .linear:
            return p
        case .equalPower:
            return sin(p * .pi / 2.0)
        case .sCurve:
            return p * p * (3.0 - 2.0 * p)
        }
    }

    private static func clampProgress(_ progress: Double) -> Double {
        guard progress.isFinite else { return 0 }
        return min(max(progress, 0), 1)
    }
}

// MARK: - Configuration

public struct CrossfadeConfiguration: Sendable, Equatable {
    /// Below this the overlap is acoustically meaningless; treat as disabled.
    public static let minimumDuration: TimeInterval = 1.0
    /// Longest supported crossfade, in seconds.
    public static let maximumDuration: TimeInterval = 12.0

    public var duration: TimeInterval
    public var curve: CrossfadeCurve

    public init(duration: TimeInterval, curve: CrossfadeCurve = .equalPower) {
        let finite = duration.isFinite ? duration : 0
        let clamped = min(max(finite, 0), CrossfadeConfiguration.maximumDuration)
        self.duration = clamped < CrossfadeConfiguration.minimumDuration ? 0 : clamped
        self.curve = curve
    }

    public static let disabled = CrossfadeConfiguration(duration: 0)

    public var isEnabled: Bool { duration > 0 }
}
