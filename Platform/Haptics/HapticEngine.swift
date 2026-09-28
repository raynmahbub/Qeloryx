// QELORYX — Platform
// HapticEngine.swift
// Isolates CoreHaptics / UIFeedbackGenerator

import Foundation
#if canImport(UIKit)
import UIKit

public enum HapticType: Sendable {
    case light
    case medium
    case heavy
    case selection
    case success
    case warning
    case error
}

public final class AstryxHapticEngine: Sendable {
    
    public static let shared = AstryxHapticEngine()
    
    public init() {}
    
    public func trigger(_ type: HapticType) {
        switch type {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .selection:
            UISelectionFeedbackGenerator().selectionChanged()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
    
    public func triggerPlay() {
        trigger(.medium)
    }
    
    public func triggerPause() {
        trigger(.light)
    }
    
    public func triggerFavorite() {
        trigger(.success)
    }
}

#else

public enum HapticType: Sendable {
    case light, medium, heavy, selection, success, warning, error
}

public final class AstryxHapticEngine: Sendable {
    public static let shared = AstryxHapticEngine()
    public init() {}
    public func trigger(_ type: HapticType) {}
    public func triggerPlay() {}
    public func triggerPause() {}
    public func triggerFavorite() {}
}

#endif
