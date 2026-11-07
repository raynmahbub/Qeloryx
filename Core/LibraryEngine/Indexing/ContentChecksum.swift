// QELORYX — LibraryEngine
// ContentChecksum.swift
//
// BUG-14. The previous "checksum" was `"\(fileSize)_\(fileName)"`:
//   • two different songs named `01 - Intro.mp3` with the same size collided
//   • renaming a file created a phantom duplicate
//   • identical audio saved under two names was never detected
//
// A fingerprint is now derived from file *content*: size plus a bounded
// head/tail sample. Hashing the whole file would be more precise but would mean
// reading every byte of a large library during indexing; the sample is cheap,
// stable across renames and good enough for duplicate detection.
//
// The algorithm is versioned (`v2`) so existing records can be recognised and
// re-fingerprinted by a migration instead of being silently mismatched.

import Foundation

public enum AstryxContentChecksum {

    /// Bump when the sampling or hashing strategy changes.
    public static let version = "v2"

    /// Number of bytes read from the start and end of the file.
    public static let sampleBytes = 64 * 1024

    /// 64-bit FNV-1a. Deterministic across process launches, unlike
    /// `Hasher`, which is randomly seeded per process.
    private static let fnvOffsetBasis: UInt64 = 0xcbf2_9ce4_8422_2325
    private static let fnvPrime: UInt64 = 0x0000_0100_0000_01b3

    /// Returns a stable fingerprint, or `nil` when the file cannot be read.
    /// A `nil` fingerprint means "unknown"; callers must not treat two `nil`
    /// values as a duplicate match.
    public static func fingerprint(at url: URL, fileSize: Int64) -> String? {
        guard fileSize > 0 else { return nil }

        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }

        var hash = fnvOffsetBasis

        func mix(_ data: Data) {
            for byte in data {
                hash ^= UInt64(byte)
                hash = hash &* fnvPrime
            }
        }

        if let head = try? handle.read(upToCount: sampleBytes), !head.isEmpty {
            mix(head)
        } else {
            return nil
        }

        // For files larger than two samples, also read the tail. Files smaller
        // than that are fully covered by the head read.
        if fileSize > Int64(sampleBytes * 2) {
            let tailOffset = UInt64(fileSize - Int64(sampleBytes))
            if (try? handle.seek(toOffset: tailOffset)) != nil,
               let tail = try? handle.read(upToCount: sampleBytes),
               !tail.isEmpty {
                mix(tail)
            }
        }

        return String(format: "%@-%016llx-%lld", version, hash, fileSize)
    }

    /// True when a stored fingerprint was produced by the current algorithm.
    public static func isCurrent(_ checksum: String) -> Bool {
        checksum.hasPrefix("\(version)-")
    }
}
