// QELORYX — LibraryEngine
// FileSystemArtworkCache.swift
// QEL-024 Library — Artwork cache with file system + LRU memory, size limit, eviction

import Foundation

public final class AstryxFileSystemArtworkCache: ArtworkCacheProtocol, @unchecked Sendable {
    
    // MARK: - Configuration
    private let memoryCache: AstryxArtworkCache // Existing LRU memory cache
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let maxDiskSize: Int64 = 500 * 1024 * 1024 // 500 MB
    private let maxMemoryItems: Int = 200
    
    private let lock = NSLock()
    private var diskSize: Int64 = 0
    
    // MARK: - Init
    
    public init(cacheDirectory: URL? = nil) {
        self.memoryCache = AstryxArtworkCache()
        
        if let dir = cacheDirectory {
            self.cacheDirectory = dir
        } else {
            // Use caches directory
            let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
            self.cacheDirectory = caches.appendingPathComponent("com.qeloryx.artwork", isDirectory: true)
        }
        
        createCacheDirectory()
        calculateDiskSize()
    }
    
    private func createCacheDirectory() {
        do {
            try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        } catch {
            #if DEBUG
            debugPrint("[ArtworkCache] Failed to create cache directory: \(error)")
            #endif
        }
    }
    
    private func calculateDiskSize() {
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])
            var size: Int64 = 0
            for file in files {
                let values = try file.resourceValues(forKeys: [.fileSizeKey])
                size += Int64(values.fileSize ?? 0)
            }
            diskSize = size
        } catch {
            diskSize = 0
        }
    }
    
    // MARK: - ArtworkCacheProtocol
    
    public func cachedArtwork(for trackID: String) -> Data? {
        // Check memory first (fast path)
        if let memData = memoryCache.cachedArtwork(for: trackID) {
            return memData
        }
        
        // Check disk
        let fileURL = cacheFileURL(for: trackID)
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        
        do {
            let data = try Data(contentsOf: fileURL)
            // Populate memory cache
            memoryCache.cacheArtwork(data, for: trackID)
            return data
        } catch {
            #if DEBUG
            debugPrint("[ArtworkCache] Failed to read disk cache for \(trackID): \(error)")
            #endif
            return nil
        }
    }
    
    public func cacheArtwork(_ data: Data, for trackID: String) {
        // Memory cache
        memoryCache.cacheArtwork(data, for: trackID)
        
        // Disk cache
        let fileURL = cacheFileURL(for: trackID)
        
        lock.lock()
        defer { lock.unlock() }
        
        do {
            try data.write(to: fileURL, options: [.atomic])
            diskSize += Int64(data.count)
            
            // Evict if over limit
            if diskSize > maxDiskSize {
                evictOldFiles()
            }
        } catch {
            #if DEBUG
            debugPrint("[ArtworkCache] Failed to write disk cache for \(trackID): \(error)")
            #endif
        }
    }
    
    public func clearCache() {
        memoryCache.clearCache()
        
        lock.lock()
        defer { lock.unlock() }
        
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [])
            for file in files {
                try fileManager.removeItem(at: file)
            }
            diskSize = 0
        } catch {
            #if DEBUG
            debugPrint("[ArtworkCache] Failed to clear cache: \(error)")
            #endif
        }
    }
    
    public func cacheSize() -> Int64 {
        lock.lock()
        let memSize = memoryCache.cacheSize()
        let disk = diskSize
        lock.unlock()
        return memSize + disk
    }
    
    // MARK: - Additional QEL-024 Methods
    
    public func cachedArtworkURL(for trackID: String) -> URL? {
        let fileURL = cacheFileURL(for: trackID)
        return fileManager.fileExists(atPath: fileURL.path) ? fileURL : nil
    }
    
    public func removeArtwork(for trackID: String) {
        memoryCache.clearCache() // Simplified: clear all memory for now, or we need remove method
        
        let fileURL = cacheFileURL(for: trackID)
        lock.lock()
        defer { lock.unlock() }
        
        do {
            let values = try fileURL.resourceValues(forKeys: [.fileSizeKey])
            let size = Int64(values.fileSize ?? 0)
            try fileManager.removeItem(at: fileURL)
            diskSize = max(0, diskSize - size)
        } catch {
            // File may not exist
        }
    }
    
    public func diskCacheSize() -> Int64 {
        lock.lock()
        defer { lock.unlock() }
        return diskSize
    }
    
    public func memoryCacheSize() -> Int64 {
        memoryCache.cacheSize()
    }
    
    // MARK: - Private
    
    private func cacheFileURL(for trackID: String) -> URL {
        // Use trackID as filename, sanitized
        let sanitized = trackID.replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: ":", with: "_")
        return cacheDirectory.appendingPathComponent("\(sanitized).jpg")
    }
    
    private func evictOldFiles() {
        // LRU eviction based on modification date
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey])
            
            // Sort by modification date (oldest first)
            let sorted = try files.sorted { url1, url2 in
                let values1 = try url1.resourceValues(forKeys: [.contentModificationDateKey])
                let values2 = try url2.resourceValues(forKeys: [.contentModificationDateKey])
                let date1 = values1.contentModificationDate ?? .distantPast
                let date2 = values2.contentModificationDate ?? .distantPast
                return date1 < date2
            }
            
            // Evict until under 80% of max
            let targetSize = Int64(Double(maxDiskSize) * 0.8)
            var currentSize = diskSize
            
            for file in sorted {
                if currentSize <= targetSize { break }
                
                do {
                    let values = try file.resourceValues(forKeys: [.fileSizeKey])
                    let size = Int64(values.fileSize ?? 0)
                    try fileManager.removeItem(at: file)
                    currentSize -= size
                } catch {
                    continue
                }
            }
            
            diskSize = currentSize
            
        } catch {
            #if DEBUG
            debugPrint("[ArtworkCache] Failed to evict: \(error)")
            #endif
        }
    }
}
