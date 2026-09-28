// QELORYX — AstryxAudioEngine
// AudioSessionManager.swift

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

// MARK: - AstryxAudioSessionManager (Foundation - platform abstraction)

public final class AstryxAudioSessionManager: AudioSessionManagerProtocol {
    
    private let eventBus: any EventBusProtocol
    private var isActive = false
    
    public init(eventBus: any EventBusProtocol = AstryxEventBus.shared) {
        self.eventBus = eventBus
    }
    
    public func configure(category: AudioSessionCategory) throws {
        // Real implementation in Platform layer uses AVAudioSession
        // Foundation placeholder logs
        #if DEBUG
        debugPrint("[AudioSessionManager] Configure category: \(category.rawValue)")
        #endif
    }
    
    public func activate() throws {
        isActive = true
        #if DEBUG
        debugPrint("[AudioSessionManager] Activated")
        #endif
    }
    
    public func deactivate() throws {
        isActive = false
        #if DEBUG
        debugPrint("[AudioSessionManager] Deactivated")
        #endif
    }
    
    public func handleInterruption(_ interruption: AudioSessionInterruption) {
        switch interruption {
        case .began:
            eventBus.publish(.audioSessionInterrupted(reason: "began"))
        case .ended(let shouldResume):
            eventBus.publish(.audioSessionInterrupted(reason: "ended_shouldResume_\(shouldResume)"))
        }
    }
}
