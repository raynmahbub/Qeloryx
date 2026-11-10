// QELORYX — Platform
// HapticEngine.swift
// QEL-051 Polish — Production haptics with Astryx feedback, QEL-012 + QEL-051 enhanced

#if canImport(QeloryxCore)
import QeloryxCore
#endif

import Foundation
#if canImport(UIKit)
import UIKit

public final class AstryxHapticEngine: HapticEngineProtocol, @unchecked Sendable {
    
    public static let shared = AstryxHapticEngine()
    
    private var lightGenerator: UIImpactFeedbackGenerator?
    private var mediumGenerator: UIImpactFeedbackGenerator?
    private var heavyGenerator: UIImpactFeedbackGenerator?
    private var selectionGenerator: UISelectionFeedbackGenerator?
    private var notificationGenerator: UINotificationFeedbackGenerator?
    
    public init() {
        // Pre-warm generators for <50ms response (performance budget)
        lightGenerator = UIImpactFeedbackGenerator(style: .light)
        mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
        heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
        selectionGenerator = UISelectionFeedbackGenerator()
        notificationGenerator = UINotificationFeedbackGenerator()
        
        lightGenerator?.prepare()
        mediumGenerator?.prepare()
        heavyGenerator?.prepare()
        selectionGenerator?.prepare()
        notificationGenerator?.prepare()
    }
    
    public func trigger(_ type: HapticType) {
        // Performance: haptics must be <10ms per budget (instant feedback)
        switch type {
        case .light:
            lightGenerator?.impactOccurred()
            lightGenerator?.prepare()
        case .medium:
            mediumGenerator?.impactOccurred()
            mediumGenerator?.prepare()
        case .heavy:
            heavyGenerator?.impactOccurred()
            heavyGenerator?.prepare()
        case .selection:
            selectionGenerator?.selectionChanged()
            selectionGenerator?.prepare()
        case .success:
            notificationGenerator?.notificationOccurred(.success)
            notificationGenerator?.prepare()
        case .warning:
            notificationGenerator?.notificationOccurred(.warning)
            notificationGenerator?.prepare()
        case .error:
            notificationGenerator?.notificationOccurred(.error)
            notificationGenerator?.prepare()
        }
    }
    
    // MARK: - Semantic Haptics — QEL-051 Polish
    
    public func triggerPlay() {
        // Medium impact for play — feels substantial
        trigger(.medium)
    }
    
    public func triggerPause() {
        // Light impact for pause — subtle
        trigger(.light)
    }
    
    public func triggerFavorite() {
        // Success notification for favorite — rewarding
        trigger(.success)
    }
    
    public func triggerSeek() {
        // Selection for seek — precise
        trigger(.selection)
    }
    
    public func triggerQueueAdd() {
        // Light for queue add — subtle confirmation
        trigger(.light)
    }
    
    public func triggerDownloadStart() {
        // Medium for download start
        trigger(.medium)
    }
    
    public func triggerDownloadComplete() {
        // Success for download complete — rewarding
        trigger(.success)
    }
    
    public func triggerError() {
        trigger(.error)
    }
    
    public func triggerTabChange() {
        trigger(.selection)
    }
    
    public func triggerLyricTap() {
        trigger(.light)
    }
}

#else

public final class AstryxHapticEngine: HapticEngineProtocol, @unchecked Sendable {
    public static let shared = AstryxHapticEngine()
    public init() {}
    public func trigger(_ type: HapticType) {}
    public func triggerPlay() {}
    public func triggerPause() {}
    public func triggerFavorite() {}
    public func triggerSeek() {}
    public func triggerQueueAdd() {}
    public func triggerDownloadStart() {}
    public func triggerDownloadComplete() {}
    public func triggerError() {}
    public func triggerTabChange() {}
    public func triggerLyricTap() {}
}

#endif

// MARK: - Enhanced Haptic Protocol — QEL-051

public extension HapticEngineProtocol {
    func triggerSeek() {
        trigger(.selection)
    }
    func triggerQueueAdd() {
        trigger(.light)
    }
    func triggerDownloadStart() {
        trigger(.medium)
    }
    func triggerDownloadComplete() {
        trigger(.success)
    }
    func triggerError() {
        trigger(.error)
    }
    func triggerTabChange() {
        trigger(.selection)
    }
    func triggerLyricTap() {
        trigger(.light)
    }
}
