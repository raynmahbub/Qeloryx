// QELORYX — DSP
// DSPEngine.swift

import Foundation

public protocol DSPEngineProtocol: Sendable {
    var equalizer: any EqualizerProtocol { get }
    var spectrumAnalyzer: any SpectrumAnalyzerProtocol { get }
    
    func enable()
    func disable()
    func isEnabled() -> Bool
}

public final class AstryxDSPEngine: DSPEngineProtocol, @unchecked Sendable {
    
    public let equalizer: any EqualizerProtocol
    public let spectrumAnalyzer: any SpectrumAnalyzerProtocol
    
    private var enabled = false
    private let lock = NSLock()
    
    public init(
        equalizer: any EqualizerProtocol = AstryxEqualizer(),
        spectrumAnalyzer: any SpectrumAnalyzerProtocol = AstryxSpectrumAnalyzer()
    ) {
        self.equalizer = equalizer
        self.spectrumAnalyzer = spectrumAnalyzer
    }
    
    public func enable() {
        lock.lock()
        enabled = true
        lock.unlock()
    }
    
    public func disable() {
        lock.lock()
        enabled = false
        lock.unlock()
    }
    
    public func isEnabled() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return enabled
    }
}
