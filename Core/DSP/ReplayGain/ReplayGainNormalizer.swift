// QELORYX — DSP
// ReplayGainNormalizer.swift
// Feature benchmark: ReplayGain / loudness normalization (Petrichor, WaveFlow, eko-web)
// Original Qeloryx implementation — idea-level inspiration only, no copied code

import Foundation

// MARK: - ReplayGain Tags

/// ReplayGain metadata as stored in audio file tags (e.g. `REPLAYGAIN_TRACK_GAIN`).
public struct ReplayGainTags: Sendable, Equatable {
    /// Track gain in dB (relative to reference loudness).
    public var trackGain: Double?
    /// Track peak as linear amplitude (0...1).
    public var trackPeak: Double?
    /// Album gain in dB.
    public var albumGain: Double?
    /// Album peak as linear amplitude (0...1).
    public var albumPeak: Double?
    
    public init(
        trackGain: Double? = nil,
        trackPeak: Double? = nil,
        albumGain: Double? = nil,
        albumPeak: Double? = nil
    ) {
        self.trackGain = trackGain
        self.trackPeak = trackPeak
        self.albumGain = albumGain
        self.albumPeak = albumPeak
    }
    
    public var hasTrackGain: Bool { trackGain != nil }
    public var hasAlbumGain: Bool { albumGain != nil }
}

// MARK: - ReplayGain Mode

public enum ReplayGainMode: String, Sendable, CaseIterable, Equatable {
    case off
    case track
    case album
    
    public var displayName: String {
        switch self {
        case .off: return "Off"
        case .track: return "Track"
        case .album: return "Album"
        }
    }
}

// MARK: - Normalizer

/// Applies ReplayGain volume normalization to playback volume.
/// Pure, deterministic math — safe to unit test without audio hardware.
public final class AstryxReplayGainNormalizer: @unchecked Sendable {
    
    /// Reference loudness in dB. ReplayGain 2.0 uses -89 dB SPL equivalent (89 dB reference).
    public var referenceLoudnessDB: Double
    /// User pre-amplification in dB, applied on top of the ReplayGain value.
    public var preAmpDB: Double
    /// When true, scale is reduced so the track peak never exceeds 1.0 (no clipping).
    public var preventClipping: Bool
    
    public init(
        referenceLoudnessDB: Double = 89.0,
        preAmpDB: Double = 0.0,
        preventClipping: Bool = true
    ) {
        self.referenceLoudnessDB = referenceLoudnessDB
        self.preAmpDB = preAmpDB
        self.preventClipping = preventClipping
    }
    
    /// The effective gain in dB for the given tags and mode. 0 dB when disabled or no tags.
    public func gainDB(for tags: ReplayGainTags?, mode: ReplayGainMode) -> Double {
        guard let tags else { return 0 }
        switch mode {
        case .off:
            return 0
        case .track:
            return tags.trackGain ?? tags.albumGain ?? 0
        case .album:
            return tags.albumGain ?? tags.trackGain ?? 0
        }
    }
    
    /// dB → linear amplitude multiplier.
    public func linearGain(for tags: ReplayGainTags?, mode: ReplayGainMode) -> Double {
        let db = gainDB(for: tags, mode: mode) + preAmpDB
        return pow(10.0, db / 20.0)
    }
    
    /// Linear gain after clipping prevention using the relevant peak.
    public func safeLinearGain(for tags: ReplayGainTags?, mode: ReplayGainMode) -> Double {
        var linear = linearGain(for: tags, mode: mode)
        guard preventClipping, let tags else { return linear }
        let peak: Double?
        switch mode {
        case .off: peak = nil
        case .track: peak = tags.trackPeak ?? tags.albumPeak
        case .album: peak = tags.albumPeak ?? tags.trackPeak
        }
        if let peak, peak > 0, linear * peak > 1.0 {
            linear = 1.0 / peak
        }
        return linear
    }
    
    /// Applies normalization to a raw volume (0...1) and returns the effective volume.
    public func apply(to volume: Float, tags: ReplayGainTags?, mode: ReplayGainMode) -> Float {
        guard mode != .off else { return volume }
        let linear = safeLinearGain(for: tags, mode: mode)
        let result = Double(volume) * linear
        return Float(min(1.0, max(0.0, result)))
    }
}
