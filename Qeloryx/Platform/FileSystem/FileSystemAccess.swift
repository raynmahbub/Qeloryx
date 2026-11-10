// QELORYX — Platform/FileSystem
// FileSystemAccess.swift
// Security-scoped file access helpers. Importing user-picked folders requires
// balancing start/stop calls; this wraps the dance so callers can't leak a scope.

import Foundation

public enum FileSystemAccess {

    /// Runs `body` with security-scoped access to `url`. Always stops accessing
    /// on exit, even when `body` throws.
    @discardableResult
    public static func withAccess<T>(to url: URL, _ body: () throws -> T) rethrows -> T {
        let scoped = url.startAccessingSecurityScopedResource()
        defer {
            if scoped { url.stopAccessingSecurityScopedResource() }
        }
        return try body()
    }

    /// Total size of all regular files under `directory`, in bytes.
    public static func sizeOfDirectory(at directory: URL) -> Int64 {
        var total: Int64 = 0
        let keys: [URLResourceKey] = [.isRegularFileKey, .fileSizeKey]
        if let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        ) {
            for case let fileURL as URL in enumerator {
                if let values = try? fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]),
                   values.isRegularFile == true {
                    total += Int64(values.fileSize ?? 0)
                }
            }
        }
        return total
    }
}
