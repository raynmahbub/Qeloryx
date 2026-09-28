// QELORYX — ProviderLayer
// ProviderRegistry.swift
// Replaceable services

import Foundation

public protocol Provider: Sendable {
    var id: String { get }
    var name: String { get }
}

public final class AstryxProviderRegistry: @unchecked Sendable {
    
    public static let shared = AstryxProviderRegistry()
    
    private var providers: [String: any Provider] = [:]
    private let lock = NSLock()
    
    public init() {}
    
    public func register(_ provider: any Provider) {
        lock.lock()
        providers[provider.id] = provider
        lock.unlock()
    }
    
    public func provider<T: Provider>(for id: String) -> T? {
        lock.lock()
        defer { lock.unlock() }
        return providers[id] as? T
    }
    
    public func allProviders() -> [any Provider] {
        lock.lock()
        defer { lock.unlock() }
        return Array(providers.values)
    }
    
    public func reset() {
        lock.lock()
        providers.removeAll()
        lock.unlock()
    }
}
