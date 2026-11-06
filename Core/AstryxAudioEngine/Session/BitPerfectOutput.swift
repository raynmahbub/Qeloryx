// QELORYX — AstryxAudioEngine
// BitPerfectOutput.swift
// Feature benchmark: bit-perfect / USB DAC output mode (Echo Music, HiFidelity, Petrichor)
// Original Qeloryx implementation — output settings model (platform adapter applies them)

import Foundation

// MARK: - Audio Output Settings

/// Audiophile output configuration. When bit-perfect is enabled the audio session
/// requests the device's native sample rate and disables system mixing.
public struct AstryxAudioOutputSettings: Sendable, Equatable {
    /// Bypass system volume/mixing for the DAC's native rate (bit-perfect).
    public var bitPerfectEnabled: Bool
    /// Preferred hardware sample rate in Hz (0 = device default).
    public var preferredSampleRate: Double
    /// Allow the DAC exclusive access (no other apps' audio).
    public var exclusiveMode: Bool
    
    public static let `default` = AstryxAudioOutputSettings(bitPerfectEnabled: false, preferredSampleRate: 0, exclusiveMode: false)
    
    public static let commonSampleRates: [Double] = [44100, 48000, 88200, 96000, 176400, 192000, 352800, 384000]
    
    public init(bitPerfectEnabled: Bool = false, preferredSampleRate: Double = 0, exclusiveMode: Bool = false) {
        self.bitPerfectEnabled = bitPerfectEnabled
        self.preferredSampleRate = AstryxAudioOutputSettings.commonSampleRates.contains(preferredSampleRate) ? preferredSampleRate : 0
        self.exclusiveMode = exclusiveMode
    }
    
    /// The effective sample rate: preferred when bit-perfect, otherwise device default (0).
    public var effectiveSampleRate: Double {
        bitPerfectEnabled ? preferredSampleRate : 0
    }
}

// MARK: - Output Mode

public enum AstryxOutputMode: String, Sendable, CaseIterable, Equatable {
    /// Standard system output (speakers, headphones, AirPlay).
    case standard
    /// Bit-perfect to an external DAC (USB/Lightning).
    case bitPerfectDAC
    /// AirPlay / wireless casting.
    case airPlay
    
    public var displayName: String {
        switch self {
        case .standard: return "Device"
        case .bitPerfectDAC: return "USB DAC (Bit-Perfect)"
        case .airPlay: return "AirPlay"
        }
    }
    
    public var settings: AstryxAudioOutputSettings {
        switch self {
        case .standard: return .default
        case .bitPerfectDAC: return AstryxAudioOutputSettings(bitPerfectEnabled: true, preferredSampleRate: 0, exclusiveMode: true)
        case .airPlay: return AstryxAudioOutputSettings(bitPerfectEnabled: false, preferredSampleRate: 0, exclusiveMode: false)
        }
    }
}
