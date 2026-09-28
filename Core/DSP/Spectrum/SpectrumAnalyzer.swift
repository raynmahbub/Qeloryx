// QELORYX — DSP
// SpectrumAnalyzer.swift
// Live Spectrum per Audio Lab spec

import Foundation

public struct SpectrumData: Sendable, Equatable {
    public let frequencies: [Double] // Hz
    public let magnitudes: [Double] // dB
    public let timestamp: Date
    
    public init(frequencies: [Double], magnitudes: [Double], timestamp: Date = Date()) {
        self.frequencies = frequencies
        self.magnitudes = magnitudes
        self.timestamp = timestamp
    }
}

public protocol SpectrumAnalyzerProtocol: Sendable {
    func startAnalyzing()
    func stopAnalyzing()
    func isAnalyzing() -> Bool
    func latestSpectrum() -> SpectrumData?
    func subscribe(_ handler: @escaping @Sendable (SpectrumData) -> Void) -> EventSubscription
}

public final class AstryxSpectrumAnalyzer: SpectrumAnalyzerProtocol, @unchecked Sendable {
    
    private var analyzing = false
    private var latest: SpectrumData?
    private var observers: [(UUID, @Sendable (SpectrumData) -> Void)] = []
    private let lock = NSLock()
    private var timer: Timer?
    
    public init() {}
    
    public func startAnalyzing() {
        lock.lock()
        guard !analyzing else {
            lock.unlock()
            return
        }
        analyzing = true
        lock.unlock()
        
        // Foundation placeholder: generate fake spectrum data
        // Real implementation uses Accelerate FFT on audio buffer
        #if DEBUG
        debugPrint("[SpectrumAnalyzer] Started")
        #endif
    }
    
    public func stopAnalyzing() {
        lock.lock()
        analyzing = false
        latest = nil
        lock.unlock()
        
        #if DEBUG
        debugPrint("[SpectrumAnalyzer] Stopped")
        #endif
    }
    
    public func isAnalyzing() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return analyzing
    }
    
    public func latestSpectrum() -> SpectrumData? {
        lock.lock()
        defer { lock.unlock() }
        return latest
    }
    
    public func subscribe(_ handler: @escaping @Sendable (SpectrumData) -> Void) -> EventSubscription {
        let id = UUID()
        lock.lock()
        observers.append((id, handler))
        lock.unlock()
        
        return EventSubscription(id: id) { [weak self] id in
            self?.lock.lock()
            self?.observers.removeAll { $0.0 == id }
            self?.lock.unlock()
        }
    }
    
    // For testing / simulation
    public func simulateSpectrumData() {
        let frequencies = [32, 64, 125, 250, 500, 1000, 2000, 4000, 8000, 16000].map { Double($0) }
        let magnitudes = frequencies.map { _ in Double.random(in: -60...0) }
        let data = SpectrumData(frequencies: frequencies, magnitudes: magnitudes)
        
        lock.lock()
        latest = data
        let obs = observers
        lock.unlock()
        
        for (_, handler) in obs {
            handler(data)
        }
    }
}
