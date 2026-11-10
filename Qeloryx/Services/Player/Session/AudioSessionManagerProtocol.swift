// QELORYX — Services/Player
// AudioSessionManager.swift
// Protocol only — implementation in Platform layer per clean architecture

import Foundation

public enum AudioSessionCategory: String, Sendable {
    case playback
    case ambient
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
        eventBus.publish(.audioSessionInterrupted(interruption: interruption))
    }
}
