// QELORYX — LibraryEngine
// FileScanner.swift
// QEL-024 Library — Production file scanner with incremental indexing at scale

import Foundation

// MARK: - FileScanner Protocol

public protocol FileScannerProtocol: Sendable {
    func scan(rootURLs: [URL]) async throws -> FileScanResult
    func scanIncremental(libraries: [AstryxLibrary], knownFiles: [String: Date]) async throws -> FileScanResult
}

public struct FileScanResult: Sendable {
    public let discoveredFiles: [DiscoveredFile]
    public let removedFiles: [String] // File paths that no longer exist
    public let duration: TimeInterval
    public let totalBytes: Int64
    
    public init(discoveredFiles: [DiscoveredFile], removedFiles: [String] = [], duration: TimeInterval, totalBytes: Int64 = 0) {
        self.discoveredFiles = discoveredFiles
        self.removedFiles = removedFiles
        self.duration = duration
        self.totalBytes = totalBytes
    }
}

public struct DiscoveredFile: Sendable, Equatable, Hashable {
    public let url: URL
    public let fileSize: Int64
    public let modificationDate: Date
    public let format: AudioFormat
    public let libraryID: String
    
    public init(url: URL, fileSize: Int64, modificationDate: Date, format: AudioFormat, libraryID: String) {
        self.url = url
        self.fileSize = fileSize
        self.modificationDate = modificationDate
        self.format = format
        self.libraryID = libraryID
    }
}

// MARK: - AstryxFileScanner

public final class AstryxFileScanner: FileScannerProtocol {
    
    private let supportedExtensions: Set<String>
    
    public init() {
        // Build set of supported extensions from AudioFormat
        var exts = Set<String>()
        for format in AudioFormat.supportedFormats {
            for fileExt in format.fileExtensions {
                exts.insert(fileExt.lowercased())
            }
        }
        self.supportedExtensions = exts
    }
    
    public func scan(rootURLs: [URL]) async throws -> FileScanResult {
        let start = Date()
        var discovered: [DiscoveredFile] = []
        var totalBytes: Int64 = 0
        
        for rootURL in rootURLs {
            let files = try await scanDirectory(at: rootURL, libraryID: rootURL.path)
            discovered.append(contentsOf: files)
            totalBytes += files.reduce(0) { $0 + $1.fileSize }
        }
        
        let duration = Date().timeIntervalSince(start)
        return FileScanResult(discoveredFiles: discovered, duration: duration, totalBytes: totalBytes)
    }
    
    public func scanIncremental(libraries: [AstryxLibrary], knownFiles: [String: Date]) async throws -> FileScanResult {
        let start = Date()
        var discovered: [DiscoveredFile] = []
        var removed: [String] = []
        var totalBytes: Int64 = 0
        var seenPaths = Set<String>()
        
        for library in libraries where library.isEnabled {
            let files = try await scanDirectory(at: library.rootURL, libraryID: library.id)
            
            for file in files {
                let path = file.url.path
                seenPaths.insert(path)
                
                // Check if file is new or modified
                if let knownDate = knownFiles[path] {
                    // If modification date is newer, re-index
                    if file.modificationDate > knownDate {
                        discovered.append(file)
                        totalBytes += file.fileSize
                    }
                } else {
                    // New file
                    discovered.append(file)
                    totalBytes += file.fileSize
                }
            }
        }
        
        // Find removed files
        for knownPath in knownFiles.keys {
            if !seenPaths.contains(knownPath) {
                removed.append(knownPath)
            }
        }
        
        let duration = Date().timeIntervalSince(start)
        return FileScanResult(discoveredFiles: discovered, removedFiles: removed, duration: duration, totalBytes: totalBytes)
    }
    
    private func scanDirectory(at url: URL, libraryID: String) async throws -> [DiscoveredFile] {
        var results: [DiscoveredFile] = []
        
        let fileManager = FileManager.default
        let resourceKeys: [URLResourceKey] = [.fileSizeKey, .contentModificationDateKey, .isRegularFileKey, .isDirectoryKey]
        
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: resourceKeys,
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return []
        }
        
        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
                
                // Skip directories
                if resourceValues.isDirectory == true { continue }
                guard resourceValues.isRegularFile == true else { continue }
                
                // Check extension
                let ext = fileURL.pathExtension.lowercased()
                guard supportedExtensions.contains(ext) else { continue }
                
                let format = AudioFormat.fromExtension(ext)
                guard format != .unknown else { continue }
                
                let fileSize = Int64(resourceValues.fileSize ?? 0)
                let modDate = resourceValues.contentModificationDate ?? Date()
                
                let discovered = DiscoveredFile(
                    url: fileURL,
                    fileSize: fileSize,
                    modificationDate: modDate,
                    format: format,
                    libraryID: libraryID
                )
                
                results.append(discovered)
                
                // Yield periodically for large libraries (10k+ tracks)
                if results.count % 500 == 0 {
                    await Task.yield()
                }
                
            } catch {
                #if DEBUG
                debugPrint("[FileScanner] Failed to scan \(fileURL): \(error)")
                #endif
                continue
            }
        }
        
        return results
    }
}
