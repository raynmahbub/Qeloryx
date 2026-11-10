// QELORYX — Models/Playback
// PlaybackQueue.swift

import Foundation

public struct AstryxQueue: Sendable, Equatable {
    public let id: String
    public var items: [AstryxQueueItem]
    public var currentIndex: Int?
    public var version: Int
    public var shuffleEnabled: Bool
    public var repeatMode: AstryxRepeatMode
    public var originalOrder: [AstryxQueueItem]? // For shuffle off restore
    
    public init(
        id: String = UUID().uuidString,
        items: [AstryxQueueItem] = [],
        currentIndex: Int? = nil,
        version: Int = 0,
        shuffleEnabled: Bool = false,
        repeatMode: AstryxRepeatMode = .off,
        originalOrder: [AstryxQueueItem]? = nil
    ) {
        self.id = id
        self.items = items
        self.currentIndex = currentIndex
        self.version = version
        self.shuffleEnabled = shuffleEnabled
        self.repeatMode = repeatMode
        self.originalOrder = originalOrder
    }
    
    public var currentItem: AstryxQueueItem? {
        guard let idx = currentIndex, idx >= 0, idx < items.count else { return nil }
        return items[idx]
    }
    
    public var nextItem: AstryxQueueItem? {
        guard let idx = currentIndex else { return items.first }
        let next = idx + 1
        if next < items.count {
            return items[next]
        } else if repeatMode == .all {
            return items.first
        }
        return nil
    }
    
    public var previousItem: AstryxQueueItem? {
        guard let idx = currentIndex else { return nil }
        let prev = idx - 1
        if prev >= 0 {
            return items[prev]
        } else if repeatMode == .all {
            return items.last
        }
        return nil
    }
    
    public var isEmpty: Bool { items.isEmpty }
    public var count: Int { items.count }
}
