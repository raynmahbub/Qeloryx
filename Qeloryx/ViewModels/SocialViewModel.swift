// QELORYX — ViewModels
// SocialViewModel.swift
// Extracted from the view file (Qeloryx/Views) — view models live here per the
// redesigned architecture.

import Foundation
import Combine

#if canImport(SwiftUI)
import SwiftUI
#endif

public final class SocialViewModel: ObservableObject {
    
    @Published public var activeSpaces: [AstryxSpace] = []
    @Published public var sharedQueue: [AstryxTrack] = []
    @Published public var recentReactions: [String] = []
    @Published public var totalListeners: Int = 0
    
    /// Spaces is not implemented. It starts empty and says so, instead of
    /// seeding two fake rooms, five fake listeners and three fake reactions
    /// from invented people (BUG-17). `isFeatureAvailable` lets the UI show a
    /// "not available yet" state rather than an empty room list.
    public static let isFeatureAvailable = false

    public init() {
        activeSpaces = []
        totalListeners = 0
        sharedQueue = []
        recentReactions = []
    }
    
    public func createSpace() {
        let newSpace = AstryxSpace(name: "My Space \(activeSpaces.count + 1)", host: "You", listeners: 1, isActive: true)
        activeSpaces.append(newSpace)
        totalListeners = activeSpaces.reduce(0) { $0 + $1.listeners }
    }
    
    public func joinSpace(_ space: AstryxSpace) {
        // Join logic
    }
    
    public func sendReaction(_ emoji: String) {
        recentReactions.insert("\(emoji) from You", at: 0)
        if recentReactions.count > 10 {
            recentReactions.removeLast()
        }
    }
}
