// QELORYX — AstryxAudioEngine
// AudioSessionManager.swift
// Protocol only — implementation in Platform layer per clean architecture

import Foundation

public enum AudioSessionCategory: String, Sendable {
    case playback
    case ambient
}

public enum AudioSessionInterruption: Sendable {
    case began
    case ended(shouldResume: Bool)
}

public protocol AudioSessionManagerProtocol: Sendable {
    func configure(category: AudioSessionCategory) throws
    func activate() throws
    func deactivate() throws
    func handleInterruption(_ interruption: AudioSessionInterruption)
}

// MARK: - Fallback for Core-only builds

public final class FallbackAudioSessionManager: AudioSessionManagerProtocol, @unchecked Sendable {
    private let eventBus: any EventBusProtocol
    
    public init(eventBus: any EventBusProtocol = AstryxEventBus.shared) {
        self.eventBus = eventBus
    }
    
    public func configure(category: AudioSessionCategory) throws {}
    public func activate() throws {}
    public func deactivate() throws {}
    public func handleInterruption(_ interruption: AudioSessionInterruption) {
        switch interruption {
        case .began:
            eventBus.publish(.audioSessionInterrupted(reason: "began"))
        case .ended(let shouldResume):
            eventBus.publish(.audioSessionInterrupted(reason: "ended_shouldResume_\(shouldResume)"))
        }
    }
}
