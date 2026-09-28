// QELORYX — CapabilityRegistry
// CapabilityRegistry.swift
// Greenfield — Qeloryx Labs

import Foundation

// MARK: - AstryxCapabilityRegistry

/// Registry for all optional features. Every capability self-registers.
/// Enables feature flags, dynamic UI, and modular builds.
public final class AstryxCapabilityRegistry: @unchecked Sendable {
    
    public static let shared = AstryxCapabilityRegistry()
    
    private var capabilities: [String: any AstryxCapability] = [:]
    private let lock = NSLock()
    
    public init() {
        registerDefaults()
    }
    
    // MARK: Registration
    
    public func register(_ capability: any AstryxCapability) {
        lock.lock()
        defer { lock.unlock() }
        capabilities[capability.id] = capability
        
        #if DEBUG
        debugPrint("[CapabilityRegistry] Registered: \(capability.name) (\(capability.id))")
        #endif
    }
    
    public func unregister(id: String) {
        lock.lock()
        defer { lock.unlock() }
        capabilities.removeValue(forKey: id)
    }
    
    // MARK: Query
    
    public func capability(for id: String) -> (any AstryxCapability)? {
        lock.lock()
        defer { lock.unlock() }
        return capabilities[id]
    }
    
    public func allCapabilities() -> [any AstryxCapability] {
        lock.lock()
        defer { lock.unlock() }
        return Array(capabilities.values)
    }
    
    public func enabledCapabilities() -> [any AstryxCapability] {
        lock.lock()
        defer { lock.unlock() }
        return capabilities.values.filter { $0.isEnabled }
    }
    
    public func isEnabled(_ id: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return capabilities[id]?.isEnabled ?? false
    }
    
    // MARK: Lifecycle
    
    public func enable(id: String) async throws {
        guard let cap = capability(for: id) else {
            throw CapabilityError.notFound(id: id)
        }
        // Check dependencies
        for dep in cap.dependencies {
            guard isEnabled(dep) else {
                throw CapabilityError.dependencyNotEnabled(id: id, dependency: dep)
            }
        }
        try await cap.enable()
    }
    
    public func disable(id: String) async throws {
        guard let cap = capability(for: id) else {
            throw CapabilityError.notFound(id: id)
        }
        try await cap.disable()
    }
    
    // MARK: Defaults
    
    private func registerDefaults() {
        let defaults: [any AstryxCapability] = [
            LyricsCapability(),
            EQCapability(),
            VisualizerCapability(),
            AirPlayCapability(),
            CloudCapability(),
            TasteDNACapability(),
            SpacesCapability(),
            BaseCapability(id: CapabilityID.nas, name: "NAS", description: "NAS integration", isEnabled: false),
            BaseCapability(id: CapabilityID.webDAV, name: "WebDAV", description: "WebDAV integration", isEnabled: false),
            BaseCapability(id: CapabilityID.replayGain, name: "ReplayGain", description: "ReplayGain normalization"),
            BaseCapability(id: CapabilityID.crossfade, name: "Crossfade", description: "Crossfade playback"),
            BaseCapability(id: CapabilityID.timeCapsule, name: "Time Capsule", description: "Today Last Year, Monthly Story, Heatmap"),
            BaseCapability(id: CapabilityID.audioLab, name: "Audio Lab", description: "Signal Path, Diagnostics, Live Spectrum")
        ]
        
        for cap in defaults {
            capabilities[cap.id] = cap
        }
    }
    
    // MARK: Testing
    
    public func reset() {
        lock.lock()
        capabilities.removeAll()
        lock.unlock()
        registerDefaults()
    }
}

// MARK: - Errors

public enum CapabilityError: Error, LocalizedError {
    case notFound(id: String)
    case dependencyNotEnabled(id: String, dependency: String)
    
    public var errorDescription: String? {
        switch self {
        case .notFound(let id):
            return "Capability not found: \(id)"
        case .dependencyNotEnabled(let id, let dep):
            return "Cannot enable \(id): dependency \(dep) not enabled"
        }
    }
}
