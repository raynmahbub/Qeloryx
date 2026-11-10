// QELORYX — Services/Player
// QueueController.swift
// Isolated queue controller per spec.
//
// Shuffle semantics (BUG-04): when shuffle is on, playback order is driven by
// an explicit shuffle bag rather than array order, so `next()` visits every
// remaining track exactly once before repeating. `previous()` walks the
// shuffle history, so going back retraces what the listener actually heard.
// Turning shuffle off restores the queue's original order and keeps the
// currently playing track selected.

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
    /// Non-mutating look-ahead: the item `next()` would advance to.
    /// Used by the engine to decide whether a crossfade can be staged.
    func previewNext() -> AstryxQueueItem?
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

    // MARK: Shuffle state (not part of the value type so the persisted
    // AstryxQueue snapshot stays small and stable)

    /// Remaining shuffled indices, drawn from the end.
    private var shuffleBag: [Int] = []
    /// Indices visited by shuffle, used by `previous()`.
    private var shuffleHistory: [Int] = []

    public init(initialQueue: AstryxQueue = AstryxQueue(), eventBus: any EventBusProtocol = AstryxEventBus.shared) {
        self.queue = initialQueue
        self.eventBus = eventBus
    }

    public func currentQueue() -> AstryxQueue {
        lock.lock()
        defer { lock.unlock() }
        return queue
    }

    // MARK: - Mutations

    public func setQueue(trackIDs: [String], startIndex: Int, source: QueueSource) async {
        let items = trackIDs.enumerated().map { idx, trackID in
            AstryxQueueItem(trackID: trackID, order: idx, source: source)
        }

        lock.lock()
        queue.items = items
        queue.currentIndex = startIndex < items.count ? startIndex : nil
        queue.version += 1
        // A new queue invalidates any in-flight shuffle walk.
        shuffleBag.removeAll()
        shuffleHistory.removeAll()
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
        // Index-based shuffle state is invalid once positions shift.
        shuffleBag.removeAll()
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
        shuffleBag.removeAll()
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
        shuffleBag.removeAll()
        queue.version += 1
        let snapshot = queue
        lock.unlock()

        eventBus.publish(.queueChanged(queueID: snapshot.id, version: snapshot.version))
    }

    // MARK: - Navigation

    public func next() async -> AstryxQueueItem? {
        lock.lock()
        defer { lock.unlock() }

        guard !queue.items.isEmpty else { return nil }

        guard let currentIdx = queue.currentIndex else {
            queue.currentIndex = 0
            queue.version += 1
            return queue.items[0]
        }

        // Repeat-one is resolved by the engine (it seeks instead of reloading),
        // so the controller reports the same item rather than advancing.
        if queue.repeatMode == .one {
            return queue.items[currentIdx]
        }

        if queue.shuffleEnabled {
            if shuffleBag.isEmpty {
                refillShuffleBagLocked(excluding: currentIdx)
                if shuffleBag.isEmpty {
                    // Single-track queue under shuffle.
                    return queue.repeatMode == .all ? queue.items[currentIdx] : nil
                }
            }
            guard let nextIdx = shuffleBag.popLast() else { return nil }
            shuffleHistory.append(currentIdx)
            queue.currentIndex = nextIdx
            queue.version += 1
            return queue.items[nextIdx]
        }

        let nextIdx = currentIdx + 1
        if nextIdx < queue.items.count {
            queue.currentIndex = nextIdx
            queue.version += 1
            return queue.items[nextIdx]
        } else if queue.repeatMode == .all {
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

        if queue.shuffleEnabled, let last = shuffleHistory.popLast() {
            // Return the index we are leaving to the bag, otherwise a
            // back-then-forward gesture could never revisit the track the user
            // just skipped away from (BUG-04).
            shuffleBag.append(currentIdx)
            queue.currentIndex = last
            queue.version += 1
            return queue.items[last]
        }

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

    public func previewNext() -> AstryxQueueItem? {
        lock.lock()
        defer { lock.unlock() }

        guard !queue.items.isEmpty else { return nil }
        guard let currentIdx = queue.currentIndex else { return queue.items.first }
        if queue.repeatMode == .one { return queue.items[currentIdx] }

        if queue.shuffleEnabled {
            if let candidate = shuffleBag.last { return queue.items[candidate] }
            // Bag is exhausted: the next shuffle cycle will start over.
            return queue.repeatMode == .all ? queue.items.first : nil
        }

        let nextIdx = currentIdx + 1
        if nextIdx < queue.items.count { return queue.items[nextIdx] }
        return queue.repeatMode == .all ? queue.items.first : nil
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

    // MARK: - Modes

    public func setShuffle(_ enabled: Bool) async {
        lock.lock()
        guard queue.shuffleEnabled != enabled else {
            lock.unlock()
            return
        }

        if enabled {
            queue.originalOrder = queue.items
            // Keep the current track selected; the play order is now the bag.
            shuffleBag.removeAll()
            shuffleHistory.removeAll()
            if let idx = queue.currentIndex {
                refillShuffleBagLocked(excluding: idx)
            }
        } else {
            if let original = queue.originalOrder {
                let currentTrackID = queue.currentItem?.trackID
                queue.items = original
                if let trackID = currentTrackID {
                    queue.currentIndex = queue.items.firstIndex { $0.trackID == trackID }
                }
                queue.originalOrder = nil
            }
            shuffleBag.removeAll()
            shuffleHistory.removeAll()
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
        shuffleBag.removeAll()
        shuffleHistory.removeAll()
        let snapshot = queue
        lock.unlock()

        eventBus.publish(.queueChanged(queueID: snapshot.id, version: snapshot.version))
    }

    // MARK: - Private

    /// Rebuilds the shuffle bag with every index except `excluded`.
    /// Must be called with `lock` held.
    private func refillShuffleBagLocked(excluding excluded: Int) {
        shuffleBag = queue.items.indices.filter { $0 != excluded }
        shuffleBag.shuffle()
    }
}
