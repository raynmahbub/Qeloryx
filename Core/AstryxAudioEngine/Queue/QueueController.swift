// QELORYX — AstryxAudioEngine
// QueueController.swift
// Isolated queue controller per spec

import Foundation

public protocol QueueControllerProtocol: Sendable {
    func currentQueue() -> AstryxQueue
    func setQueue(trackIDs: [String], startIndex: Int, source: QueueSource) async
    func addToQueue(trackID: String, at position: QueuePosition) async
    func removeFromQueue(itemID: String) async
    func moveItem(from: Int, to: Int) async
    func next() async -> AstryxQueueItem?
    func previous() async -> AstryxQueueItem?
    func setCurrentIndex(_ index: Int) async
    func setShuffle(_ enabled: Bool) async
    func setRepeatMode(_ mode: AstryxRepeatMode) async
    func clear() async
}

public enum QueuePosition: Sendable {
    case next
    case end
    case at(Int)
}

public final class AstryxQueueController: QueueControllerProtocol, @unchecked Sendable {
    
    private var queue: AstryxQueue
    private let eventBus: any EventBusProtocol
    private let lock = NSLock()
    
    public init(initialQueue: AstryxQueue = AstryxQueue(), eventBus: any EventBusProtocol = AstryxEventBus.shared) {
        self.queue = initialQueue
        self.eventBus = eventBus
    }
    
    public func currentQueue() -> AstryxQueue {
        lock.lock()
        defer { lock.unlock() }
        return queue
    }
    
    public func setQueue(trackIDs: [String], startIndex: Int, source: QueueSource) async {
        let items = trackIDs.enumerated().map { idx, trackID in
            AstryxQueueItem(trackID: trackID, order: idx, isCurrent: idx == startIndex, source: source)
        }
        
        lock.lock()
        queue.items = items
        queue.currentIndex = startIndex < items.count ? startIndex : nil
        queue.version += 1
        let snapshot = queue
        lock.unlock()
        
        eventBus.publish(.queueChanged(queueID: snapshot.id, version: snapshot.version))
    }
    
    public func addToQueue(trackID: String, at position: QueuePosition) async {
        lock.lock()
        let newItem: AstryxQueueItem
        switch position {
        case .next:
            let insertIndex = (queue.currentIndex ?? -1) + 1
            newItem = AstryxQueueItem(trackID: trackID, order: insertIndex, source: .manual)
            queue.items.insert(newItem, at: min(insertIndex, queue.items.count))
            // Reorder
            for i in 0..<queue.items.count { queue.items[i].order = i }
        case .end:
            newItem = AstryxQueueItem(trackID: trackID, order: queue.items.count, source: .manual)
            queue.items.append(newItem)
        case .at(let idx):
            let safeIdx = min(max(0, idx), queue.items.count)
            newItem = AstryxQueueItem(trackID: trackID, order: safeIdx, source: .manual)
            queue.items.insert(newItem, at: safeIdx)
            for i in 0..<queue.items.count { queue.items[i].order = i }
        }
        queue.version += 1
        let snapshot = queue
        lock.unlock()
        
        eventBus.publish(.queueChanged(queueID: snapshot.id, version: snapshot.version))
    }
    
    public func removeFromQueue(itemID: String) async {
        lock.lock()
        queue.items.removeAll { $0.id == itemID }
        for i in 0..<queue.items.count { queue.items[i].order = i }
        if let current = queue.currentIndex, current >= queue.items.count {
            queue.currentIndex = queue.items.isEmpty ? nil : max(0, queue.items.count - 1)
        }
        queue.version += 1
        let snapshot = queue
        lock.unlock()
        
        eventBus.publish(.queueChanged(queueID: snapshot.id, version: snapshot.version))
    }
    
    public func moveItem(from: Int, to: Int) async {
        lock.lock()
        guard from != to, from >= 0, from < queue.items.count, to >= 0, to < queue.items.count else {
            lock.unlock()
            return
        }
        let item = queue.items.remove(at: from)
        queue.items.insert(item, at: to)
        for i in 0..<queue.items.count { queue.items[i].order = i }
        queue.version += 1
        let snapshot = queue
        lock.unlock()
        
        eventBus.publish(.queueChanged(queueID: snapshot.id, version: snapshot.version))
    }
    
    public func next() async -> AstryxQueueItem? {
        lock.lock()
        defer { lock.unlock() }
        
        guard let currentIdx = queue.currentIndex else {
            if !queue.items.isEmpty {
                queue.currentIndex = 0
                queue.version += 1
                return queue.items[0]
            }
            return nil
        }
        
        if queue.repeatMode == .one {
            return queue.items[currentIdx]
        }
        
        let nextIdx = currentIdx + 1
        if nextIdx < queue.items.count {
            queue.currentIndex = nextIdx
            queue.version += 1
            return queue.items[nextIdx]
        } else if queue.repeatMode == .all, !queue.items.isEmpty {
            queue.currentIndex = 0
            queue.version += 1
            return queue.items[0]
        }
        
        return nil
    }
    
    public func previous() async -> AstryxQueueItem? {
        lock.lock()
        defer { lock.unlock() }
        
        guard let currentIdx = queue.currentIndex else { return nil }
        
        let prevIdx = currentIdx - 1
        if prevIdx >= 0 {
            queue.currentIndex = prevIdx
            queue.version += 1
            return queue.items[prevIdx]
        } else if queue.repeatMode == .all, !queue.items.isEmpty {
            queue.currentIndex = queue.items.count - 1
            queue.version += 1
            return queue.items.last
        }
        
        return nil
    }
    
    public func setCurrentIndex(_ index: Int) async {
        lock.lock()
        guard index >= 0, index < queue.items.count else {
            lock.unlock()
            return
        }
        queue.currentIndex = index
        queue.version += 1
        let snapshot = queue
        lock.unlock()
        
        eventBus.publish(.queueChanged(queueID: snapshot.id, version: snapshot.version))
    }
    
    public func setShuffle(_ enabled: Bool) async {
        lock.lock()
        guard queue.shuffleEnabled != enabled else {
            lock.unlock()
            return
        }
        
        if enabled {
            // Save original order
            queue.originalOrder = queue.items
            // Shuffle, but keep current item first if exists
            var toShuffle = queue.items
            var current: AstryxQueueItem?
            if let idx = queue.currentIndex, idx < toShuffle.count {
                current = toShuffle.remove(at: idx)
            }
            toShuffle.shuffle()
            if let cur = current {
                toShuffle.insert(cur, at: 0)
                queue.currentIndex = 0
            }
            queue.items = toShuffle
            for i in 0..<queue.items.count { queue.items[i].order = i }
        } else {
            // Restore original order
            if let original = queue.originalOrder {
                let currentTrackID = queue.currentItem?.trackID
                queue.items = original
                if let trackID = currentTrackID {
                    queue.currentIndex = queue.items.firstIndex { $0.trackID == trackID }
                }
                queue.originalOrder = nil
            }
        }
        
        queue.shuffleEnabled = enabled
        queue.version += 1
        let snapshot = queue
        lock.unlock()
        
        eventBus.publish(.queueChanged(queueID: snapshot.id, version: snapshot.version))
    }
    
    public func setRepeatMode(_ mode: AstryxRepeatMode) async {
        lock.lock()
        queue.repeatMode = mode
        queue.version += 1
        let snapshot = queue
        lock.unlock()
        
        eventBus.publish(.queueChanged(queueID: snapshot.id, version: snapshot.version))
    }
    
    public func clear() async {
        lock.lock()
        queue.items.removeAll()
        queue.currentIndex = nil
        queue.version += 1
        queue.originalOrder = nil
        let snapshot = queue
        lock.unlock()
        
        eventBus.publish(.queueChanged(queueID: snapshot.id, version: snapshot.version))
    }
}
