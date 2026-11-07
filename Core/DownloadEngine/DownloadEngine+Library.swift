// QELORYX — DownloadEngine
// DownloadEngine+Library.swift
//
// Library ingestion for finished downloads. Split out of `DownloadEngine.swift`
// to keep `AstryxDownloadEngine` inside the 400-line `type_body_length` limit.

import Foundation

extension AstryxDownloadEngine {

    // MARK: - Library integration (BUG-10)

    /// After a download completes: validate, read tags and artwork, optionally
    /// copy into the app's own storage, then index it so the track is playable,
    /// searchable and counted in stats. Previously a completed download was a
    /// file on disk that nothing knew about.
    func ingestCompletedDownload(_ task: AstryxDownloadTask) async {
        guard let library else { return }
        let url = task.destinationURL

        guard FileManager.default.fileExists(atPath: url.path) else { return }

        let raw = (try? await metadataEngine.extractMetadata(from: url)) ?? RawMetadata()
        let fileSize = ((try? FileManager.default.attributesOfItem(atPath: url.path)[.size]) as? Int64) ?? 0
        let format = AudioFormat.fromExtension(url.pathExtension)

        // The download's own metadata wins over tags when it is more specific
        // (provider-supplied titles are usually better than a filename parse).
        let title = task.title ?? raw.title ?? url.deletingPathExtension().lastPathComponent
        let artist = task.artist ?? raw.artist ?? "Unknown Artist"

        let track = AstryxTrack(
            title: title,
            artist: artist,
            album: raw.album ?? "Unknown Album",
            albumArtist: raw.albumArtist,
            genre: raw.genre,
            year: raw.year,
            trackNumber: raw.trackNumber,
            discNumber: raw.discNumber,
            duration: raw.duration ?? 0,
            fileURL: url,
            fileFormat: format,
            fileSize: fileSize,
            bitRate: raw.bitRate,
            sampleRate: raw.sampleRate,
            bitDepth: raw.bitDepth,
            isLossless: format.isLossless,
            artworkData: raw.artworkData,
            lyrics: raw.lyrics,
            folderPath: url.deletingLastPathComponent().path,
            checksum: AstryxContentChecksum.fingerprint(at: url, fileSize: fileSize)
        )

        do {
            _ = try await library.upsertTrack(track)
        } catch {
            #if DEBUG
            debugPrint("[DownloadEngine] Failed to index completed download: \(error)")
            #endif
        }
    }

}
