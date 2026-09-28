// QELORYX — LibraryEngine
// ArtworkCache.swift

import Foundation

public protocol ArtworkCacheProtocol: Sendable {
    func cachedArtwork(for trackID: String) -> Data?
    func cacheArtwork(_ data: Data, for trackID: String)
    func clearCache()
    func cacheSize() -> Int64
}

public final class AstryxArtworkCache: ArtworkCacheProtocol, @unchecked Sendable {
    private var memoryCache: [String: Data] = [:]
    private let lock = NSLock()
    private let maxMemoryItems = 200
    private var accessOrder: [String] = [] // LRU
    
    public init() {}
    
    public func cachedArtwork(for trackID: String) -> Data? {
        lock.lock()
        defer { lock.unlock() }
        
        guard let data = memoryCache[trackID] else { return nil }
        
        // Move to end (most recently used)
        if let index = accessOrder.firstIndex(of: trackID) {
            accessOrder.remove(at: index)
        }
        accessOrder.append(trackID)
        
        return data
    }
    
    public func cacheArtwork(_ data: Data, for trackID: String) {
        lock.lock()
        defer { lock.unlock() }
        
        memoryCache[trackID] = data
        
        if let index = accessOrder.firstIndex(of: trackID) {
            accessOrder.remove(at: index)
        }
        accessOrder.append(trackID)
        
        // Evict if over limit
        while memoryCache.count > maxMemoryItems, let oldest = accessOrder.first {
            memoryCache.removeValue(forKey: oldest)
            accessOrder.removeFirst()
        }
    }
    
    public func clearCache() {
        lock.lock()
        memoryCache.removeAll()
        accessOrder.removeAll()
        lock.unlock()
    }
    
    public func cacheSize() -> Int64 {
        lock.lock()
        defer { lock.unlock() }
        return Int64(memoryCache.values.reduce(0) { $0 + $1.count })
    }
}
