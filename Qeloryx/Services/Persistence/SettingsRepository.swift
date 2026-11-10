// QELORYX — Services/Persistence
// SettingsRepository.swift
//
// Central settings store. Previously every screen owned its own `@Published`
// knobs (AudioLab's crossfade slider, SearchViewModel's history comment,
// DownloadSessionManager's hard-coded cellular flag), so a "setting" changed
// nothing outside the view that showed it.
//
// Design:
//   • One repository, injected everywhere.
//   • Every key has a documented default and is validated on write.
//   • `apply(to:)` pushes audio-related values into the engine, which is the
//     only way a preference can affect playback.
//   • Backed by `UserDefaults` (testable through the `SettingsStoring` seam).

import Foundation

// MARK: - Value types

public enum AppearanceMode: String, Sendable, CaseIterable {
    case system
    case light
    case dark
}

public struct AppearancePreferences: Sendable, Equatable {
    public var mode: AppearanceMode = .system
    public var accentHex: String = "#4C8DFF"
    public var reduceMotionOverride: Bool = false

    public init() {}
}

public struct AudioPreferences: Sendable, Equatable {
    /// 0…12 s. `0` disables crossfading.
    public var crossfadeSeconds: Double = 0
    public var crossfadeCurve: CrossfadeCurve = .equalPower
    public var gaplessEnabled: Bool = true
    public var replayGainEnabled: Bool = false

    public init() {}
}

public struct PlaybackPreferences: Sendable, Equatable {
    /// Restore the last queue (paused) when the app launches.
    public var restoreQueueOnLaunch: Bool = true
}

public struct DownloadPreferences: Sendable, Equatable {
    public var maxConcurrent: Int = 3
    public var allowsCellular: Bool = true
    public var wifiOnly: Bool { !allowsCellular }

    public init() {}
}

public struct PrivacyPreferences: Sendable, Equatable {
    /// Remote analytics is opt-in and off by default.
    public var analyticsEnabled: Bool = false
    /// Listening history never leaves the device unless this is on.
    public var syncHistoryEnabled: Bool = false

    public init() {}
}

// MARK: - Storage seam

public protocol SettingsStoring: Sendable {
    func double(forKey key: String) -> Double?
    func bool(forKey key: String) -> Bool?
    func int(forKey key: String) -> Int?
    func string(forKey key: String) -> String?
    func set(_ value: Any?, forKey key: String)
}

public final class UserDefaultsSettingsStore: SettingsStoring, @unchecked Sendable {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func double(forKey key: String) -> Double? {
        defaults.object(forKey: key) == nil ? nil : defaults.double(forKey: key)
    }

    public func bool(forKey key: String) -> Bool? {
        defaults.object(forKey: key) == nil ? nil : defaults.bool(forKey: key)
    }

    public func int(forKey key: String) -> Int? {
        defaults.object(forKey: key) == nil ? nil : defaults.integer(forKey: key)
    }

    public func string(forKey key: String) -> String? {
        defaults.string(forKey: key)
    }

    public func set(_ value: Any?, forKey key: String) {
        defaults.set(value, forKey: key)
    }
}

public final class InMemorySettingsStore: SettingsStoring, @unchecked Sendable {
    private var values: [String: Any] = [:]
    private let lock = NSLock()

    public init() {}

    public func double(forKey key: String) -> Double? {
        lock.lock(); defer { lock.unlock() }
        return values[key] as? Double
    }

    public func bool(forKey key: String) -> Bool? {
        lock.lock(); defer { lock.unlock() }
        return values[key] as? Bool
    }

    public func int(forKey key: String) -> Int? {
        lock.lock(); defer { lock.unlock() }
        return values[key] as? Int
    }

    public func string(forKey key: String) -> String? {
        lock.lock(); defer { lock.unlock() }
        return values[key] as? String
    }

    public func set(_ value: Any?, forKey key: String) {
        lock.lock()
        values[key] = value
        lock.unlock()
    }
}

// MARK: - Repository

public final class SettingsRepository: @unchecked Sendable {

    public enum Key {
        public static let appearanceMode = "qeloryx.appearance.mode"
        public static let accentHex = "qeloryx.appearance.accent"
        public static let reduceMotionOverride = "qeloryx.appearance.reduceMotionOverride"
        public static let crossfadeSeconds = "qeloryx.audio.crossfadeSeconds"
        public static let crossfadeCurve = "qeloryx.audio.crossfadeCurve"
        public static let gapless = "qeloryx.audio.gapless"
        public static let replayGain = "qeloryx.audio.replayGain"
        public static let restoreQueue = "qeloryx.playback.restoreQueue"
        public static let maxConcurrentDownloads = "qeloryx.downloads.maxConcurrent"
        public static let allowsCellular = "qeloryx.downloads.allowsCellular"
        public static let analytics = "qeloryx.privacy.analytics"
        public static let syncHistory = "qeloryx.privacy.syncHistory"
    }

    /// Must match `CrossfadeConfiguration.maxDuration` semantics (0…12 s).
    public static let maximumCrossfadeSeconds: Double = 12
    public static let maximumConcurrentDownloads: Int = 6

    private let store: any SettingsStoring
    private let lock = NSLock()
    private var _appearance = AppearancePreferences()
    private var _audio = AudioPreferences()
    private var _playback = PlaybackPreferences()
    private var _downloads = DownloadPreferences()
    private var _privacy = PrivacyPreferences()

    public init(store: any SettingsStoring = UserDefaultsSettingsStore()) {
        self.store = store
        reload()
    }

    // MARK: Reads

    public var appearance: AppearancePreferences {
        lock.lock(); defer { lock.unlock() }
        return _appearance
    }

    public var audio: AudioPreferences {
        lock.lock(); defer { lock.unlock() }
        return _audio
    }

    public var playback: PlaybackPreferences {
        lock.lock(); defer { lock.unlock() }
        return _playback
    }

    public var downloads: DownloadPreferences {
        lock.lock(); defer { lock.unlock() }
        return _downloads
    }

    public var privacy: PrivacyPreferences {
        lock.lock(); defer { lock.unlock() }
        return _privacy
    }

    // MARK: Writes (validated)

    public func setAppearanceMode(_ mode: AppearanceMode) {
        store.set(mode.rawValue, forKey: Key.appearanceMode)
        lock.lock(); _appearance.mode = mode; lock.unlock()
    }

    public func setAccentHex(_ hex: String) {
        guard Self.isValidHex(hex) else { return }
        store.set(hex, forKey: Key.accentHex)
        lock.lock(); _appearance.accentHex = hex; lock.unlock()
    }

    /// Clamped to 0…12 s; values outside the range would produce a fade longer
    /// than the transition controller allows.
    public func setCrossfadeSeconds(_ seconds: Double) {
        let clamped = min(max(seconds, 0), Self.maximumCrossfadeSeconds)
        store.set(clamped, forKey: Key.crossfadeSeconds)
        lock.lock(); _audio.crossfadeSeconds = clamped; lock.unlock()
    }

    public func setCrossfadeCurve(_ curve: CrossfadeCurve) {
        store.set(curve.rawValue, forKey: Key.crossfadeCurve)
        lock.lock(); _audio.crossfadeCurve = curve; lock.unlock()
    }

    public func setGaplessEnabled(_ enabled: Bool) {
        store.set(enabled, forKey: Key.gapless)
        lock.lock(); _audio.gaplessEnabled = enabled; lock.unlock()
    }

    public func setReplayGainEnabled(_ enabled: Bool) {
        store.set(enabled, forKey: Key.replayGain)
        lock.lock(); _audio.replayGainEnabled = enabled; lock.unlock()
    }

    public func setRestoreQueueOnLaunch(_ enabled: Bool) {
        store.set(enabled, forKey: Key.restoreQueue)
        lock.lock(); _playback.restoreQueueOnLaunch = enabled; lock.unlock()
    }

    public func setMaxConcurrentDownloads(_ count: Int) {
        let clamped = min(max(count, 1), Self.maximumConcurrentDownloads)
        store.set(clamped, forKey: Key.maxConcurrentDownloads)
        lock.lock(); _downloads.maxConcurrent = clamped; lock.unlock()
    }

    public func setAllowsCellular(_ allowed: Bool) {
        store.set(allowed, forKey: Key.allowsCellular)
        lock.lock(); _downloads.allowsCellular = allowed; lock.unlock()
    }

    public func setAnalyticsEnabled(_ enabled: Bool) {
        store.set(enabled, forKey: Key.analytics)
        lock.lock(); _privacy.analyticsEnabled = enabled; lock.unlock()
    }

    public func setSyncHistoryEnabled(_ enabled: Bool) {
        store.set(enabled, forKey: Key.syncHistory)
        lock.lock(); _privacy.syncHistoryEnabled = enabled; lock.unlock()
    }

    // MARK: Audio application

    /// The one place a preference becomes engine behaviour. Without this the
    /// dual-deck crossfade adapter never received a configuration and always
    /// ran disabled (BUG-06).
    public func crossfadeConfiguration() -> CrossfadeConfiguration {
        let audio = self.audio
        guard audio.crossfadeSeconds > 0 else { return .disabled }
        return CrossfadeConfiguration(duration: audio.crossfadeSeconds, curve: audio.crossfadeCurve)
    }

    public func applyAudioSettings(to engine: any AstryxAudioEngineProtocol) async {
        try? await engine.handle(command: .setCrossfade(crossfadeConfiguration()))
    }

    // MARK: Private

    private func reload() {
        lock.lock()
        defer { lock.unlock() }

        if let raw = store.string(forKey: Key.appearanceMode),
           let mode = AppearanceMode(rawValue: raw) {
            _appearance.mode = mode
        }
        if let hex = store.string(forKey: Key.accentHex), Self.isValidHex(hex) {
            _appearance.accentHex = hex
        }
        _appearance.reduceMotionOverride = store.bool(forKey: Key.reduceMotionOverride) ?? false

        _audio.crossfadeSeconds = min(
            max(store.double(forKey: Key.crossfadeSeconds) ?? 0, 0),
            Self.maximumCrossfadeSeconds
        )
        if let raw = store.string(forKey: Key.crossfadeCurve),
           let curve = CrossfadeCurve(rawValue: raw) {
            _audio.crossfadeCurve = curve
        }
        _audio.gaplessEnabled = store.bool(forKey: Key.gapless) ?? true
        _audio.replayGainEnabled = store.bool(forKey: Key.replayGain) ?? false

        _playback.restoreQueueOnLaunch = store.bool(forKey: Key.restoreQueue) ?? true

        _downloads.maxConcurrent = min(
            max(store.int(forKey: Key.maxConcurrentDownloads) ?? 3, 1),
            Self.maximumConcurrentDownloads
        )
        _downloads.allowsCellular = store.bool(forKey: Key.allowsCellular) ?? true

        _privacy.analyticsEnabled = store.bool(forKey: Key.analytics) ?? false
        _privacy.syncHistoryEnabled = store.bool(forKey: Key.syncHistory) ?? false
    }

    static func isValidHex(_ hex: String) -> Bool {
        guard hex.hasPrefix("#"), hex.count == 7 else { return false }
        return hex.dropFirst().allSatisfy { $0.isHexDigit }
    }
}
