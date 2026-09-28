// QELORYX — App
// EnvironmentValues+Qeloryx.swift

import SwiftUI

// MARK: - Environment Keys

private struct AudioEngineKey: EnvironmentKey {
    static let defaultValue: any AstryxAudioEngineProtocol = AstryxAudioEngine()
}

private struct LibraryEngineKey: EnvironmentKey {
    static let defaultValue: any LibraryEngineProtocol = AstryxLibraryEngine()
}

private struct SearchEngineKey: EnvironmentKey {
    static let defaultValue: any SearchEngineProtocol = AstryxSearchEngine()
}

private struct EventBusKey: EnvironmentKey {
    static let defaultValue: any EventBusProtocol = AstryxEventBus.shared
}

public extension EnvironmentValues {
    var audioEngine: any AstryxAudioEngineProtocol {
        get { self[AudioEngineKey.self] }
        set { self[AudioEngineKey.self] = newValue }
    }
    
    var libraryEngine: any LibraryEngineProtocol {
        get { self[LibraryEngineKey.self] }
        set { self[LibraryEngineKey.self] = newValue }
    }
    
    var searchEngine: any SearchEngineProtocol {
        get { self[SearchEngineKey.self] }
        set { self[SearchEngineKey.self] = newValue }
    }
    
    var eventBus: any EventBusProtocol {
        get { self[EventBusKey.self] }
        set { self[EventBusKey.self] = newValue }
    }
}
