// QELORYX — ViewModels
// AudioLabViewModel.swift
// Extracted from the view file (Qeloryx/Views) — view models live here per the
// redesigned architecture.

import Foundation
import Combine

#if canImport(SwiftUI)
import SwiftUI
#endif

public final class AudioLabViewModel: ObservableObject {
    
    @Published public var isDSPEnabled: Bool = true
    @Published public var isEQEnabled: Bool = false
    @Published public var bands: [EQBand] = EQPreset.flat.bands
    @Published public var currentPreset: EQPreset? = .flat
    @Published public var presets: [EQPreset] = [.flat, .bassBoost, .vocalBoost]
    @Published public var currentFormat: String = "FLAC 44.1kHz"
    @Published public var storageInfo: String = "12.4 GB free"
    @Published public var signalPath: [SignalNode] = []
    
    // MARK: Playback settings (OSS benchmark: gapless/crossfade, ReplayGain, bit-perfect)
    @Published public var gaplessEnabled: Bool = true
    @Published public var crossfadeDuration: TimeInterval = 0
    @Published public var replayGainMode: ReplayGainMode = .off
    @Published public var outputMode: AstryxOutputMode = .standard
    
    public var playbackSettings: AstryxPlaybackSettings {
        AstryxPlaybackSettings(gaplessEnabled: gaplessEnabled, crossfadeDuration: crossfadeDuration)
    }
    public var outputSettings: AstryxAudioOutputSettings {
        outputMode == .bitPerfectDAC
            ? AstryxAudioOutputSettings(bitPerfectEnabled: true, preferredSampleRate: 0, exclusiveMode: true)
            : .default
    }
    
    private let dspEngine: any DSPEngineProtocol
    
    /// The DSP engine is injected from the composition root. It used to default
    /// to a brand-new `AstryxDSPEngine()`, so the Audio Lab edited a second,
    /// disconnected instance and its sliders changed nothing (BUG-07).
    public init(dspEngine: any DSPEngineProtocol) {
        self.dspEngine = dspEngine
        self.bands = dspEngine.equalizer.bands()
        self.isDSPEnabled = dspEngine.isEnabled()
        self.isEQEnabled = dspEngine.equalizer.isEnabled()
        // An illustrative signal path, not a measurement. Renamed from
        // `mockSignalPath` so nobody reads it as live diagnostics (BUG-17).
        self.signalPath = Self.illustrativeSignalPath
        self.presets = [EQPreset.flat, EQPreset.bassBoost, EQPreset.vocalBoost, EQPreset(name: "Treble Boost", bands: [
            EQBand(frequency: 32, gain: 0), EQBand(frequency: 64, gain: 0), EQBand(frequency: 125, gain: 0),
            EQBand(frequency: 250, gain: 0), EQBand(frequency: 500, gain: 0), EQBand(frequency: 1000, gain: 1),
            EQBand(frequency: 2000, gain: 2), EQBand(frequency: 4000, gain: 4), EQBand(frequency: 8000, gain: 5), EQBand(frequency: 16000, gain: 6)
        ])]
    }
    
    public func toggleDSP() {
        if isDSPEnabled {
            dspEngine.disable()
        } else {
            dspEngine.enable()
        }
        isDSPEnabled = dspEngine.isEnabled()
    }
    
    public func setGain(_ gain: Double, forBandID id: String) {
        dspEngine.equalizer.setGain(gain, forBandID: id)
        bands = dspEngine.equalizer.bands()
        currentPreset = nil
    }
    
    public func selectPreset(_ preset: EQPreset) {
        dspEngine.equalizer.setPreset(preset)
        bands = preset.bands
        currentPreset = preset
    }
    
    public func resetEQ() {
        dspEngine.equalizer.reset()
        bands = dspEngine.equalizer.bands()
        currentPreset = .flat
    }
    
    public func setEQEnabled(_ enabled: Bool) {
        dspEngine.equalizer.setEnabled(enabled)
        isEQEnabled = enabled
    }
    
    private static var illustrativeSignalPath: [SignalNode] {
        [
            SignalNode(name: "Source", detail: "FLAC 44.1kHz 16-bit", icon: "doc.fill", isActive: true),
            SignalNode(name: "Decoder", detail: "Lossless → PCM", icon: "cpu", isActive: true),
            SignalNode(name: "DSP", detail: "EQ + Spectrum", icon: "waveform.path.ecg", isActive: true),
            SignalNode(name: "Mixer", detail: "Volume + Crossfade", icon: "slider.horizontal.3", isActive: true),
            SignalNode(name: "Output", detail: "AVAudioEngine → Speaker", icon: "speaker.wave.3.fill", isActive: true)
        ]
    }
}
