// QELORYX — Platform
// AudioSessionManager.swift
// QEL-012 Player — Real AVAudioSession handling

#if canImport(QeloryxCore)
import QeloryxCore
#endif

import Foundation

#if canImport(AVFoundation)
import AVFoundation

public final class AstryxAudioSessionManager: AudioSessionManagerProtocol, @unchecked Sendable {
    
    private let eventBus: any EventBusProtocol
    private var interruptionObserver: NSObjectProtocol?
    private var routeChangeObserver: NSObjectProtocol?
    
    public init(eventBus: any EventBusProtocol = AstryxEventBus.shared) {
        self.eventBus = eventBus
        observeInterruptions()
        observeRouteChanges()
    }
    
    public func configure(category: AudioSessionCategory) throws {
        let session = AVAudioSession.sharedInstance()
        do {
            switch category {
            case .playback:
                try session.setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetooth, .allowBluetoothA2DP])
            case .ambient:
                try session.setCategory(.ambient, mode: .default, options: [.allowAirPlay])
            }
            try session.setActive(true, options: [])
        } catch {
            throw AudioSessionError.configurationFailed(error.localizedDescription)
        }
    }
    
    public func activate() throws {
        do {
            try AVAudioSession.sharedInstance().setActive(true, options: [])
        } catch {
            throw AudioSessionError.activationFailed(error.localizedDescription)
        }
    }
    
    public func deactivate() throws {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        } catch {
            throw AudioSessionError.deactivationFailed(error.localizedDescription)
        }
    }
    
    public func handleInterruption(_ interruption: AudioSessionInterruption) {
        switch interruption {
        case .began:
            eventBus.publish(.audioSessionInterrupted(reason: "began"))
        case .ended(let shouldResume):
            eventBus.publish(.audioSessionInterrupted(reason: "ended_shouldResume_\(shouldResume)"))
        }
    }
    
    private func observeInterruptions() {
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let userInfo = notification.userInfo,
                  let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
            switch type {
            case .began:
                self?.handleInterruption(.began)
            case .ended:
                let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                let shouldResume = options.contains(.shouldResume)
                self?.handleInterruption(.ended(shouldResume: shouldResume))
            @unknown default:
                break
            }
        }
    }
    
    private func observeRouteChanges() {
        routeChangeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let userInfo = notification.userInfo,
                  let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
                  let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }
            switch reason {
            case .oldDeviceUnavailable:
                self?.eventBus.publish(.audioSessionInterrupted(reason: "route_oldDeviceUnavailable"))
            default:
                break
            }
        }
    }
    
    deinit {
        if let obs = interruptionObserver { NotificationCenter.default.removeObserver(obs) }
        if let obs = routeChangeObserver { NotificationCenter.default.removeObserver(obs) }
    }
}

public enum AudioSessionError: Error, LocalizedError {
    case configurationFailed(String)
    case activationFailed(String)
    case deactivationFailed(String)
    public var errorDescription: String? {
        switch self {
        case .configurationFailed(let msg): return "Audio session config failed: \(msg)"
        case .activationFailed(let msg): return "Audio session activation failed: \(msg)"
        case .deactivationFailed(let msg): return "Audio session deactivation failed: \(msg)"
        }
    }
}

#else

public final class AstryxAudioSessionManager: AudioSessionManagerProtocol, @unchecked Sendable {
    private let eventBus: any EventBusProtocol
    public init(eventBus: any EventBusProtocol = AstryxEventBus.shared) {
        self.eventBus = eventBus
    }
    public func configure(category: AudioSessionCategory) throws {}
    public func activate() throws {}
    public func deactivate() throws {}
    public func handleInterruption(_ interruption: AudioSessionInterruption) {}
}

#endif
