// QELORYX — Models/Playback
// RepeatMode.swift
// Repeat and shuffle selection for the play queue.

import Foundation

public enum AstryxRepeatMode: String, Sendable, CaseIterable, Equatable {
    case off
    case all
    case one

    public var next: AstryxRepeatMode {
        switch self {
        case .off: return .all
        case .all: return .one
        case .one: return .off
        }
    }

    public var systemImage: String {
        switch self {
        case .off: return "repeat"
        case .all: return "repeat"
        case .one: return "repeat.1"
        }
    }
}

// MARK: - ShuffleMode

public enum AstryxShuffleMode: Sendable, Equatable {
    case off
    case on(seed: Int? = nil)

    public var isEnabled: Bool {
        if case .on = self { return true }
        return false
    }
}

// MARK: - Playback errors

/// Typed failures for the playback path. The engine never silently degrades
/// into "simulated playback"; it reports one of these instead.
