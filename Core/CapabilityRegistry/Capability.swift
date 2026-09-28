// QELORYX — CapabilityRegistry
// Capability.swift
// Greenfield — Qeloryx Labs

import Foundation

// MARK: - Capability Protocol

/// Every optional feature in QELORYX registers itself as a Capability.
/// This enables modular feature flags, dynamic UI, and clean dependency management.
public protocol AstryxCapability: Sendable {
    var id: String { get }
    var name: String { get }
    var version: String { get }
    var isEnabled: Bool { get }
    var dependencies: [String] { get } // Other capability IDs this depends on
    var description: String { get }
    
    func enable() async throws
    func disable() async throws
}

// MARK: - Capability Types

public enum CapabilityID {
    public static let lyrics = "com.qeloryx.capability.lyrics"
    public static let eq = "com.qeloryx.capability.eq"
    public static let visualizer = "com.qeloryx.capability.visualizer"
    public static let airPlay = "com.qeloryx.capability.airplay"
    public static let cloud = "com.qeloryx.capability.cloud"
    public static let nas = "com.qeloryx.capability.nas"
    public static let webDAV = "com.qeloryx.capability.webdav"
    public static let replayGain = "com.qeloryx.capability.replaygain"
    public static let crossfade = "com.qeloryx.capability.crossfade"
    public static let tasteDNA = "com.qeloryx.capability.tastedna"
    public static let spaces = "com.qeloryx.capability.spaces"
    public static let timeCapsule = "com.qeloryx.capability.timecapsule"
    public static let audioLab = "com.qeloryx.capability.audiolab"
}

// MARK: - Base Capability

open class BaseCapability: AstryxCapability {
    public let id: String
    public let name: String
    public let version: String
    public let dependencies: [String]
    public let description: String
    public private(set) var isEnabled: Bool
    
    public init(id: String, name: String, version: String = "1.0.0", dependencies: [String] = [], description: String, isEnabled: Bool = true) {
        self.id = id
        self.name = name
        self.version = version
        self.dependencies = dependencies
        self.description = description
        self.isEnabled = isEnabled
    }
    
    open func enable() async throws {
        isEnabled = true
    }
    
    open func disable() async throws {
        isEnabled = false
    }
}

// MARK: - Concrete Capabilities (Foundation)

public final class LyricsCapability: BaseCapability {
    public init() {
        super.init(id: CapabilityID.lyrics, name: "Lyrics++", description: "Synced lyrics, LRC, Karaoke, translation-ready")
    }
}

public final class EQCapability: BaseCapability {
    public init() {
        super.init(id: CapabilityID.eq, name: "Equalizer", description: "10-band EQ with presets")
    }
}

public final class VisualizerCapability: BaseCapability {
    public init() {
        super.init(id: CapabilityID.visualizer, name: "Visualizer", description: "Live spectrum, waveform")
    }
}

public final class AirPlayCapability: BaseCapability {
    public init() {
        super.init(id: CapabilityID.airPlay, name: "AirPlay", description: "AirPlay 2 streaming")
    }
}

public final class CloudCapability: BaseCapability {
    public init() {
        super.init(id: CapabilityID.cloud, name: "Cloud", description: "Cloud provider integration", isEnabled: false)
    }
}

public final class TasteDNACapability: BaseCapability {
    public init() {
        super.init(id: CapabilityID.tasteDNA, name: "Taste DNA", description: "Live evolving listening profile")
    }
}

public final class SpacesCapability: BaseCapability {
    public init() {
        super.init(id: CapabilityID.spaces, name: "Astryx Spaces", description: "Shared queue, DJ handoff, live reactions")
    }
}
