// QELORYX — EventBus
// EventBus.swift
// Greenfield — Qeloryx Labs
// Actor-based typed event bus for loose coupling

import Foundation

// MARK: - EventBus Protocol

/// Protocol for EventBus to enable testability and dependency inversion
public protocol EventBusProtocol: AnyObject, Sendable {
    @discardableResult
    func subscribe(_ handler: @escaping @Sendable (QeloryxEvent) -> Void) -> EventSubscription
    
    @discardableResult
    func subscribe(to eventName: String, handler: @escaping @Sendable (QeloryxEvent) -> Void) -> EventSubscription
    
    func publish(_ event: QeloryxEvent)
}

// MARK: - AstryxEventBus

/// Central nervous system of QELORYX.
/// All cross-engine communication happens through this bus.
/// Thread-safe via internal serial queue and actor-like locking.
public final class AstryxEventBus: EventBusProtocol, @unchecked Sendable {
    
    // MARK: Singleton
    public static let shared = AstryxEventBus()
    
    // MARK: Private State
    private struct Observer {
        let id: UUID
        let eventNameFilter: String?
        let handler: @Sendable (QeloryxEvent) -> Void
    }
    
    private var observers: [Observer] = []
    private let queue = DispatchQueue(label: "com.qeloryx.eventbus", attributes: .concurrent)
    private var eventLog: [QeloryxEvent] = []
    private let maxLogSize = 100
    
    // MARK: Init
    public init() {}
    
    // MARK: Subscribe
    
    /// Subscribe to all events
    @discardableResult
    public func subscribe(_ handler: @escaping @Sendable (QeloryxEvent) -> Void) -> EventSubscription {
        let id = UUID()
        let observer = Observer(id: id, eventNameFilter: nil, handler: handler)
        
        queue.async(flags: .barrier) {
            self.observers.append(observer)
        }
        
        return EventSubscription(id: id) { [weak self] id in
            self?.removeObserver(id: id)
        }
    }
    
    /// Subscribe to specific event name only
    @discardableResult
    public func subscribe(to eventName: String, handler: @escaping @Sendable (QeloryxEvent) -> Void) -> EventSubscription {
        let id = UUID()
        let observer = Observer(id: id, eventNameFilter: eventName, handler: handler)
        
        queue.async(flags: .barrier) {
            self.observers.append(observer)
        }
        
        return EventSubscription(id: id) { [weak self] id in
            self?.removeObserver(id: id)
        }
    }
    
    private func removeObserver(id: UUID) {
        queue.async(flags: .barrier) {
            self.observers.removeAll { $0.id == id }
        }
    }
    
    // MARK: Publish
    
    /// Publish event to all matching observers
    public func publish(_ event: QeloryxEvent) {
        // Debug logging
        #if DEBUG
        debugPrint("[AstryxEventBus] Publishing: \(event.name)")
        #endif
        
        // Store in log for debugging
        queue.async(flags: .barrier) {
            self.eventLog.append(event)
            if self.eventLog.count > self.maxLogSize {
                self.eventLog.removeFirst(self.eventLog.count - self.maxLogSize)
            }
        }
        
        // Snapshot observers to avoid holding lock during callbacks
        var snapshot: [Observer] = []
        queue.sync {
            snapshot = self.observers
        }
        
        for observer in snapshot {
            if let filter = observer.eventNameFilter {
                guard filter == event.name else { continue }
            }
            // Dispatch handler async to avoid blocking publisher
            DispatchQueue.global(qos: .userInitiated).async {
                observer.handler(event)
            }
        }
    }
    
    // MARK: Debug
    
    /// For testing: get recent events
    public func recentEvents() -> [QeloryxEvent] {
        var log: [QeloryxEvent] = []
        queue.sync {
            log = self.eventLog
        }
        return log
    }
    
    /// For testing: clear all observers
    public func removeAllObservers() {
        queue.async(flags: .barrier) {
            self.observers.removeAll()
            self.eventLog.removeAll()
        }
    }
}

// MARK: - Convenience Global

/// Global shortcut for publishing (optional)
public func publishEvent(_ event: QeloryxEvent) {
    AstryxEventBus.shared.publish(event)
}
