// QELORYX — Platform
// MetadataExtractor.swift
// QEL-024 Library — Real AVAsset metadata extraction, isolated in Platform per architecture

import Foundation

#if canImport(AVFoundation)
import AVFoundation

public final class AstryxMetadataExtractor: @unchecked Sendable {
    
    public init() {}
    
    public func extractMetadata(from url: URL) async throws -> RawMetadata {
        let asset = AVURLAsset(url: url)
        
        // Load duration
        let duration = try await asset.load(.duration)
        let durationSeconds = duration.seconds.isNaN ? 0 : duration.seconds
        
        // Load common metadata
        let commonMetadata = try await asset.load(.commonMetadata)
        
        var title: String?
        var artist: String?
        var album: String?
        var albumArtist: String?
        var genre: String?
        var year: Int?
        var trackNumber: Int?
        var artworkData: Data?
        
        for item in commonMetadata {
            guard let key = item.commonKey?.rawValue else { continue }
            let value = try? await item.load(.stringValue)
            
            switch key {
            case "title":
                title = value
            case "artist":
                artist = value
            case "albumName":
                album = value
            case "type":
                genre = value
            default:
                break
            }
            
            // Artwork
            if item.commonKey == .artwork {
                if let data = try? await item.load(.dataValue) {
                    artworkData = data
                }
            }
        }
        
        // Load ID3 or iTunes metadata for more details
        let availableFormats = asset.availableMetadataFormats
        for format in availableFormats {
            let metadata = try await asset.loadMetadata(for: format)
            for item in metadata {
                guard let identifier = item.identifier?.rawValue else { continue }
                
                if identifier.contains("albumArtist") || identifier == "com.apple.iTunes:AlbumArtist" {
                    albumArtist = try? await item.load(.stringValue)
                }
                if identifier.contains("trackNumber") {
                    if let str = try? await item.load(.stringValue), let num = Int(str.components(separatedBy: "/").first ?? "") {
                        trackNumber = num
                    }
                }
                if identifier.contains("year") || identifier == "com.apple.iTunes:Year" {
                    if let str = try? await item.load(.stringValue), let y = Int(str) {
                        year = y
                    }
                }
            }
        }
        
        return RawMetadata(
            title: title,
            artist: artist,
            album: album,
            albumArtist: albumArtist,
            genre: genre,
            year: year,
            trackNumber: trackNumber,
            duration: durationSeconds,
            artworkData: artworkData
        )
    }
    
    public func extractArtwork(from url: URL) async throws -> Data? {
        let metadata = try await extractMetadata(from: url)
        return metadata.artworkData
    }
}

#else

public final class AstryxMetadataExtractor: @unchecked Sendable {
    public init() {}
    public func extractMetadata(from url: URL) async throws -> RawMetadata {
        return RawMetadata(title: url.deletingPathExtension().lastPathComponent)
    }
    public func extractArtwork(from url: URL) async throws -> Data? { nil }
}

#endif
