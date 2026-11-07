// QELORYX — App
// EnvironmentValues+Qeloryx.swift
//
// Environment injection for the composition root's engines.
//
// The defect here (BUG-19) was that `defaultValue` **constructed a fresh
// engine** on every read:
//
//     static let defaultValue: any LibraryEngineProtocol = AstryxLibraryEngine()
//
// A view rendered outside the injected tree therefore silently received a
// second library with its own empty in-memory store, and a second audio engine
// with its own queue and position timer. Two engines running at once is worse
// than one unconfigured engine, so the defaults are now **one shared, inert
// placeholder per key**: a missing injection is a single degraded object rather
// than a new one per view, and it logs loudly in debug.
//
// The production path always injects real instances from `AppDependencies`
// (`QeloryxApp`), so these placeholders only surface in previews and in
// misconfigured test hosts.

import SwiftUI

// MARK: - Unconfigured placeholders
//
// One instance per kind, created on first use and never duplicated.

private enum Unconfigured {

    // MARK: Why these are degenerate, not real engines
    //
    // These used to return freshly-built, fully-functional engines. That is the
    // opposite of what a missing injection should produce: a view that forgot to
    // receive its dependency would get a *working* engine with its own empty
    // store and silently show nothing, instead of failing visibly. Every
    // placeholder here therefore refuses or returns empty, and logs once.

    static var audioEngine: any AstryxAudioEngineProtocol {
        log("AstryxAudioEngineProtocol")
        return UnconfiguredAudioEngine()
    }

    static var libraryEngine: any LibraryEngineProtocol {
        log("LibraryEngineProtocol")
        return UnconfiguredLibraryEngine()
    }

    static var searchEngine: any SearchEngineProtocol {
        log("SearchEngineProtocol")
        return AstryxSearchEngine(libraryEngine: libraryEngine)
    }

    static var downloadEngine: any DownloadEngineProtocol {
        log("DownloadEngineProtocol")
        return AstryxDownloadEngine(
            downloadSession: UnconfiguredDownloadSession(),
            taskStore: InMemoryDownloadTaskStore()
        )
    }

    static var dspEngine: any DSPEngineProtocol {
        log("DSPEngineProtocol")
        return AstryxDSPEngine()
    }

    static var settings: SettingsRepository {
        log("SettingsRepository")
        return SettingsRepository(store: InMemorySettingsStore())
    }

    static var tasteEngine: any TasteDNAEngineProtocol {
        log("TasteDNAEngineProtocol")
        return AstryxTasteDNAEngine()
    }

    static var lyricsEngine: any LyricsEngineProtocol {
        log("LyricsEngineProtocol")
        return AstryxLyricsEngine(providers: [])
    }

    /// Logs once per type rather than on every `body` evaluation, so the console
    /// stays readable in previews that read several keys per frame.
    private static let logged = LoggedOnce()

    private static func log(_ name: String) {
        #if DEBUG
        logged.once(name) {
            debugPrint(
                "[Qeloryx] \(name) was read from the environment but was never "
                + "injected by AppDependencies. Using an inert placeholder."
            )
        }
        #endif
    }
}

/// Serialises the "have I warned about this key already" bookkeeping.
private final class LoggedOnce: @unchecked Sendable {
    private let lock = NSLock()
    private var seen: Set<String> = []

    func once(_ key: String, _ body: () -> Void) {
        lock.lock()
        let isNew = seen.insert(key).inserted
        lock.unlock()
        if isNew { body() }
    }
}

// MARK: - Environment Keys

private struct AudioEngineKey: EnvironmentKey {
    static var defaultValue: any AstryxAudioEngineProtocol { Unconfigured.audioEngine }
}

private struct LibraryEngineKey: EnvironmentKey {
    static var defaultValue: any LibraryEngineProtocol { Unconfigured.libraryEngine }
}

private struct SearchEngineKey: EnvironmentKey {
    static var defaultValue: any SearchEngineProtocol { Unconfigured.searchEngine }
}

/// The event bus is a true singleton by design, so this default is correct
/// rather than a placeholder.
private struct EventBusKey: EnvironmentKey {
    // Computed, not stored: `EnvironmentKey.defaultValue` is a get-only
    // requirement, and a stored static var is mutable global state — an error
    // under `SWIFT_STRICT_CONCURRENCY: complete`.
    static var defaultValue: any EventBusProtocol { AstryxEventBus.shared }
}

private struct DownloadEngineKey: EnvironmentKey {
    static var defaultValue: any DownloadEngineProtocol { Unconfigured.downloadEngine }
}

private struct DSPEngineKey: EnvironmentKey {
    static var defaultValue: any DSPEngineProtocol { Unconfigured.dspEngine }
}

private struct SettingsKey: EnvironmentKey {
    static var defaultValue: SettingsRepository { Unconfigured.settings }
}

private struct TasteEngineKey: EnvironmentKey {
    static var defaultValue: any TasteDNAEngineProtocol { Unconfigured.tasteEngine }
}

private struct LyricsEngineKey: EnvironmentKey {
    static var defaultValue: any LyricsEngineProtocol { Unconfigured.lyricsEngine }
}

// MARK: - Accessors

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

    var downloadEngine: any DownloadEngineProtocol {
        get { self[DownloadEngineKey.self] }
        set { self[DownloadEngineKey.self] = newValue }
    }

    var dspEngine: any DSPEngineProtocol {
        get { self[DSPEngineKey.self] }
        set { self[DSPEngineKey.self] = newValue }
    }

    var settings: SettingsRepository {
        get { self[SettingsKey.self] }
        set { self[SettingsKey.self] = newValue }
    }

    var tasteEngine: any TasteDNAEngineProtocol {
        get { self[TasteEngineKey.self] }
        set { self[TasteEngineKey.self] = newValue }
    }

    var lyricsEngine: any LyricsEngineProtocol {
        get { self[LyricsEngineKey.self] }
        set { self[LyricsEngineKey.self] = newValue }
    }
}
