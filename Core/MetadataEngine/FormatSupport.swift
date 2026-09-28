// QELORYX — MetadataEngine
// FormatSupport.swift

import Foundation

public struct FormatSupportInfo: Sendable {
    public let format: AudioFormat
    public let isSupported: Bool
    public let canExtractMetadata: Bool
    public let canExtractArtwork: Bool
    public let isLossless: Bool
    public let description: String
    
    public init(format: AudioFormat, isSupported: Bool = true, canExtractMetadata: Bool = true, canExtractArtwork: Bool = true, isLossless: Bool, description: String) {
        self.format = format
        self.isSupported = isSupported
        self.canExtractMetadata = canExtractMetadata
        self.canExtractArtwork = canExtractArtwork
        self.isLossless = isLossless
        self.description = description
    }
}

public final class AstryxFormatSupport {
    public static let all: [FormatSupportInfo] = [
        FormatSupportInfo(format: .mp3, isLossless: false, description: "MPEG Audio Layer III"),
        FormatSupportInfo(format: .aac, isLossless: false, description: "Advanced Audio Coding"),
        FormatSupportInfo(format: .m4a, isLossless: false, description: "MPEG-4 Audio"),
        FormatSupportInfo(format: .alac, isLossless: true, description: "Apple Lossless"),
        FormatSupportInfo(format: .flac, isLossless: true, description: "Free Lossless Audio Codec"),
        FormatSupportInfo(format: .wav, isLossless: true, description: "Waveform Audio"),
        FormatSupportInfo(format: .aiff, isLossless: true, description: "Audio Interchange File Format"),
        FormatSupportInfo(format: .ogg, isLossless: false, description: "Ogg Vorbis"),
        FormatSupportInfo(format: .opus, isLossless: false, description: "Opus Interactive Audio")
    ]
    
    public static func info(for format: AudioFormat) -> FormatSupportInfo? {
        all.first { $0.format == format }
    }
}
