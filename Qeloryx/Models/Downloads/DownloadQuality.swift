// QELORYX — Models/Downloads
// DownloadQuality.swift

import Foundation

/// Quality ladder for offline downloads. `.original` never re-encodes;
/// `.lossless` picks the best lossless copy the source offers; the lossy rungs
/// are bitrate targets for future transcode support.
public enum AstryxDownloadQuality: String, Sendable, CaseIterable, Codable, Equatable, Hashable {
    case low
    case standard
    case high
    case lossless
    case original

    public var displayName: String {
        switch self {
        case .low: return "Low"
        case .standard: return "Standard"
        case .high: return "High"
        case .lossless: return "Lossless"
        case .original: return "Original"
        }
    }

    /// Approximate AAC bitrate in kbps for the lossy rungs; `nil` for lossless
    /// and original, which are not bitrate-bound.
    public var approximateBitrateKbps: Int? {
        switch self {
        case .low: return 96
        case .standard: return 160
        case .high: return 256
        case .lossless, .original: return nil
        }
    }

    public var prefersLosslessContainer: Bool {
        self == .lossless || self == .original
    }
}
