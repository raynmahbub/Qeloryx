// QELORYX — EventBus
// EventSubscription.swift
// Greenfield — Qeloryx Labs

import Foundation

// MARK: - EventSubscription

/// Cancellable token for EventBus subscriptions.
/// Holds a closure to remove observer on deinit or explicit cancel.
public final class EventSubscription: @unchecked Sendable {
    private let id: UUID
    private var onCancel: ((UUID) -> Void)?
    private let lock = NSLock()
    private var isCancelled = false
    
    init(id: UUID, onCancel: @escaping (UUID) -> Void) {
        self.id = id
        self.onCancel = onCancel
    }
    
    /// Cancel subscription and remove observer
    public func cancel() {
        lock.lock()
        defer { lock.unlock() }
        guard !isCancelled else { return }
        isCancelled = true
        onCancel?(id)
        onCancel = nil
    }
    
    deinit {
        cancel()
    }
}

// MARK: - Subscription Store

/// Helper to store multiple subscriptions and cancel all at once
public final class EventSubscriptionStore {
    private var subscriptions: [EventSubscription] = []
    private let lock = NSLock()
    
    public init() {}
    
    public func store(_ subscription: EventSubscription) {
        lock.lock()
        subscriptions.append(subscription)
        lock.unlock()
    }
    
    public func cancelAll() {
        lock.lock()
        let subs = subscriptions
        subscriptions.removeAll()
        lock.unlock()
        subs.forEach { $0.cancel() }
    }
    
    deinit {
        cancelAll()
    }
}

// MARK: - Convenience

public extension EventSubscription {
    func store(in store: EventSubscriptionStore) {
        store.store(self)
    }
}
