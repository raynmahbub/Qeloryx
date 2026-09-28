// QELORYX — DSP
// Equalizer.swift

import Foundation

public struct EQBand: Sendable, Equatable, Identifiable {
    public let id: String
    public var frequency: Double // Hz
    public var gain: Double // dB, -12 to +12
    public var q: Double // Quality factor
    public var type: EQBandType
    
    public init(id: String = UUID().uuidString, frequency: Double, gain: Double = 0, q: Double = 1.0, type: EQBandType = .peaking) {
        self.id = id
        self.frequency = frequency
        self.gain = gain
        self.q = q
        self.type = type
    }
}

public enum EQBandType: String, Sendable, CaseIterable {
    case lowShelf
    case highShelf
    case peaking
    case lowPass
    case highPass
}

public struct EQPreset: Sendable, Equatable, Identifiable {
    public let id: String
    public let name: String
    public let bands: [EQBand]
    
    public init(id: String = UUID().uuidString, name: String, bands: [EQBand]) {
        self.id = id
        self.name = name
        self.bands = bands
    }
    
    // Predefined presets
    public static let flat = EQPreset(name: "Flat", bands: [
        EQBand(frequency: 32, gain: 0),
        EQBand(frequency: 64, gain: 0),
        EQBand(frequency: 125, gain: 0),
        EQBand(frequency: 250, gain: 0),
        EQBand(frequency: 500, gain: 0),
        EQBand(frequency: 1000, gain: 0),
        EQBand(frequency: 2000, gain: 0),
        EQBand(frequency: 4000, gain: 0),
        EQBand(frequency: 8000, gain: 0),
        EQBand(frequency: 16000, gain: 0)
    ])
    
    public static let bassBoost = EQPreset(name: "Bass Boost", bands: [
        EQBand(frequency: 32, gain: 6),
        EQBand(frequency: 64, gain: 5),
        EQBand(frequency: 125, gain: 3),
        EQBand(frequency: 250, gain: 1),
        EQBand(frequency: 500, gain: 0),
        EQBand(frequency: 1000, gain: 0),
        EQBand(frequency: 2000, gain: 0),
        EQBand(frequency: 4000, gain: 0),
        EQBand(frequency: 8000, gain: 0),
        EQBand(frequency: 16000, gain: 0)
    ])
    
    public static let vocalBoost = EQPreset(name: "Vocal Boost", bands: [
        EQBand(frequency: 32, gain: 0),
        EQBand(frequency: 64, gain: 0),
        EQBand(frequency: 125, gain: 0),
        EQBand(frequency: 250, gain: 1),
        EQBand(frequency: 500, gain: 2),
        EQBand(frequency: 1000, gain: 3),
        EQBand(frequency: 2000, gain: 3),
        EQBand(frequency: 4000, gain: 2),
        EQBand(frequency: 8000, gain: 1),
        EQBand(frequency: 16000, gain: 0)
    ])
}

public protocol EqualizerProtocol: Sendable {
    func bands() -> [EQBand]
    func setGain(_ gain: Double, forBandID id: String)
    func setPreset(_ preset: EQPreset)
    func currentPreset() -> EQPreset?
    func reset()
    func isEnabled() -> Bool
    func setEnabled(_ enabled: Bool)
}

public final class AstryxEqualizer: EqualizerProtocol, @unchecked Sendable {
    
    private var _bands: [EQBand]
    private var _preset: EQPreset?
    private var _enabled: Bool = false
    private let lock = NSLock()
    
    public init(initialBands: [EQBand] = EQPreset.flat.bands) {
        self._bands = initialBands
        self._preset = .flat
    }
    
    public func bands() -> [EQBand] {
        lock.lock()
        defer { lock.unlock() }
        return _bands
    }
    
    public func setGain(_ gain: Double, forBandID id: String) {
        lock.lock()
        if let index = _bands.firstIndex(where: { $0.id == id }) {
            _bands[index].gain = max(-12, min(12, gain))
            _preset = nil // Custom
        }
        lock.unlock()
    }
    
    public func setPreset(_ preset: EQPreset) {
        lock.lock()
        _bands = preset.bands
        _preset = preset
        lock.unlock()
    }
    
    public func currentPreset() -> EQPreset? {
        lock.lock()
        defer { lock.unlock() }
        return _preset
    }
    
    public func reset() {
        setPreset(.flat)
    }
    
    public func isEnabled() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return _enabled
    }
    
    public func setEnabled(_ enabled: Bool) {
        lock.lock()
        _enabled = enabled
        lock.unlock()
    }
}
