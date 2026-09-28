// QELORYX — Features — AudioLab
// AudioLabView.swift
// QEL-051 Discovery — Production Astryx Audio Lab with DSP, EQ, Spectrum, Diagnostics

import SwiftUI

public struct AudioLabView: View {
    
    @StateObject private var viewModel: AudioLabViewModel
    
    public init(viewModel: AudioLabViewModel = AudioLabViewModel()) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        ZStack {
            AstryxColors.midnight
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    header
                    signalPathSection
                    eqSection
                    spectrumSection
                    diagnosticsSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
        }
        .navigationTitle("Audio Lab")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button { viewModel.resetEQ() } label: { Label("Reset EQ", systemImage: "arrow.counterclockwise") }
                    Button { viewModel.toggleDSP() } label: { Label(viewModel.isDSPEnabled ? "Disable DSP" : "Enable DSP", systemImage: "waveform.path") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                }
            }
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Astryx Audio Lab")
                        .font(AstryxTypography.Heading.h2)
                        .foregroundColor(AstryxColors.iceWhite)
                    Text("Signal Path • Playback Diagnostics • Battery • Storage • Live Spectrum")
                        .font(AstryxTypography.Body.small)
                        .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(viewModel.isDSPEnabled ? AstryxColors.emerald.opacity(0.15) : AstryxColors.Semantic.surface)
                        .frame(width: 50, height: 50)
                    Image(systemName: viewModel.isDSPEnabled ? "waveform.path.ecg" : "waveform.path")
                        .font(.system(size: 22))
                        .foregroundColor(viewModel.isDSPEnabled ? AstryxColors.emerald : AstryxColors.Semantic.foregroundSecondary)
                }
            }
            
            HStack(spacing: 12) {
                LabStat(title: "DSP", value: viewModel.isDSPEnabled ? "On" : "Off", color: viewModel.isDSPEnabled ? AstryxColors.emerald : AstryxColors.Semantic.foregroundSecondary)
                LabStat(title: "EQ", value: viewModel.currentPreset?.name ?? "Custom", color: AstryxColors.auroraBlue)
                LabStat(title: "Format", value: viewModel.currentFormat, color: AstryxColors.Semantic.foregroundSecondary)
            }
        }
        .padding(16)
        .background(AstryxColors.Semantic.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var signalPathSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Signal Path", icon: "point.3.connected.trianglepath.dotted")
            
            VStack(spacing: 0) {
                ForEach(Array(viewModel.signalPath.enumerated()), id: \.offset) { index, node in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(node.isActive ? AstryxColors.auroraBlue : AstryxColors.Semantic.surface)
                                .frame(width: 32, height: 32)
                            Image(systemName: node.icon)
                                .font(.system(size: 14))
                                .foregroundColor(node.isActive ? AstryxColors.iceWhite : AstryxColors.Semantic.foregroundSecondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(node.name)
                                .font(AstryxTypography.Body.medium)
                                .foregroundColor(AstryxColors.iceWhite)
                            Text(node.detail)
                                .font(AstryxTypography.Body.caption)
                                .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                        }
                        
                        Spacer()
                        
                        if node.isActive {
                            Circle()
                                .fill(AstryxColors.emerald)
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    
                    if index < viewModel.signalPath.count - 1 {
                        HStack {
                            Rectangle()
                                .fill(AstryxColors.Semantic.border)
                                .frame(width: 2, height: 16)
                                .padding(.leading, 31)
                            Spacer()
                        }
                    }
                }
            }
            .background(AstryxColors.Semantic.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var eqSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Equalizer", icon: "slider.horizontal.3")
            
            VStack(spacing: 16) {
                // Presets
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.presets, id: \.id) { preset in
                            Button {
                                viewModel.selectPreset(preset)
                            } label: {
                                Text(preset.name)
                                    .font(AstryxTypography.Body.small)
                                    .foregroundColor(viewModel.currentPreset?.id == preset.id ? AstryxColors.iceWhite : AstryxColors.Semantic.foregroundSecondary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(viewModel.currentPreset?.id == preset.id ? AstryxColors.auroraBlue : AstryxColors.Semantic.surface)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                
                // Bands
                VStack(spacing: 12) {
                    ForEach(viewModel.bands) { band in
                        HStack(spacing: 12) {
                            Text("\(Int(band.frequency))Hz")
                                .font(AstryxTypography.Mono.small)
                                .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                                .frame(width: 50, alignment: .leading)
                            
                            Slider(value: Binding(
                                get: { band.gain },
                                set: { viewModel.setGain($0, forBandID: band.id) }
                            ), in: -12...12, step: 0.5)
                            .tint(AstryxColors.auroraBlue)
                            
                            Text(String(format: "%+.1fdB", band.gain))
                                .font(AstryxTypography.Mono.small)
                                .foregroundColor(band.gain == 0 ? AstryxColors.Semantic.foregroundSecondary : AstryxColors.auroraBlue)
                                .frame(width: 50, alignment: .trailing)
                        }
                    }
                }
                
                HStack {
                    Button("Reset") { viewModel.resetEQ() }
                        .font(AstryxTypography.Body.small)
                        .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                    Spacer()
                    Toggle("Enable EQ", isOn: Binding(
                        get: { viewModel.isEQEnabled },
                        set: { viewModel.setEQEnabled($0) }
                    ))
                    .tint(AstryxColors.auroraBlue)
                    .font(AstryxTypography.Body.small)
                }
            }
            .padding(16)
            .background(AstryxColors.Semantic.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var spectrumSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Live Spectrum", icon: "waveform")
            
            VStack(spacing: 12) {
                // Mock spectrum visualization
                HStack(alignment: .bottom, spacing: 3) {
                    ForEach(0..<32, id: \.self) { i in
                        let height = CGFloat.random(in: 4...60)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [AstryxColors.auroraBlue, AstryxColors.emerald],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(height: height)
                    }
                }
                .frame(height: 80)
                .frame(maxWidth: .infinity)
                .background(AstryxColors.Semantic.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                HStack {
                    Label("44.1 kHz", systemImage: "waveform.path")
                    Spacer()
                    Label("16-bit", systemImage: "dial.medium")
                    Spacer()
                    Label("Stereo", systemImage: "speaker.wave.2")
                }
                .font(AstryxTypography.Body.caption)
                .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
            }
            .padding(16)
            .background(AstryxColors.Semantic.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var diagnosticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Diagnostics", icon: "stethoscope")
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                DiagCard(title: "Battery", value: "Optimized", icon: "battery.100", color: AstryxColors.emerald)
                DiagCard(title: "Storage", value: viewModel.storageInfo, icon: "internaldrive", color: AstryxColors.auroraBlue)
                DiagCard(title: "Latency", value: "< 50ms", icon: "timer", color: AstryxColors.emerald)
                DiagCard(title: "Buffer", value: "Healthy", icon: "waveform.path.badge.minus", color: AstryxColors.emerald)
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
public final class AudioLabViewModel: ObservableObject {
    
    @Published public var isDSPEnabled: Bool = true
    @Published public var isEQEnabled: Bool = false
    @Published public var bands: [EQBand] = EQPreset.flat.bands
    @Published public var currentPreset: EQPreset? = .flat
    @Published public var presets: [EQPreset] = [.flat, .bassBoost, .vocalBoost]
    @Published public var currentFormat: String = "FLAC 44.1kHz"
    @Published public var storageInfo: String = "12.4 GB free"
    @Published public var signalPath: [SignalNode] = []
    
    private let dspEngine: any DSPEngineProtocol
    
    public init(dspEngine: any DSPEngineProtocol = AstryxDSPEngine()) {
        self.dspEngine = dspEngine
        self.bands = dspEngine.equalizer.bands()
        self.isDSPEnabled = dspEngine.isEnabled()
        self.isEQEnabled = dspEngine.equalizer.isEnabled()
        self.signalPath = Self.mockSignalPath
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
    
    private static var mockSignalPath: [SignalNode] {
        [
            SignalNode(name: "Source", detail: "FLAC 44.1kHz 16-bit", icon: "doc.fill", isActive: true),
            SignalNode(name: "Decoder", detail: "Lossless → PCM", icon: "cpu", isActive: true),
            SignalNode(name: "DSP", detail: "EQ + Spectrum", icon: "waveform.path.ecg", isActive: true),
            SignalNode(name: "Mixer", detail: "Volume + Crossfade", icon: "slider.horizontal.3", isActive: true),
            SignalNode(name: "Output", detail: "AVAudioEngine → Speaker", icon: "speaker.wave.3.fill", isActive: true)
        ]
    }
}

public struct SignalNode: Identifiable {
    public let id = UUID()
    public let name: String
    public let detail: String
    public let icon: String
    public let isActive: Bool
}

// MARK: - Helpers

private struct SectionHeader: View {
    let title: String
    let icon: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AstryxColors.auroraBlue)
            Text(title)
                .font(AstryxTypography.Heading.h4)
                .foregroundColor(AstryxColors.iceWhite)
            Spacer()
        }
    }
}

private struct LabStat: View {
    let title: String
    let value: String
    let color: Color
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(AstryxTypography.Body.caption)
                .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
            Text(value)
                .font(AstryxTypography.Body.small)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(AstryxColors.Semantic.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct DiagCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.15))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AstryxTypography.Body.caption)
                    .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                Text(value)
                    .font(AstryxTypography.Body.small)
                    .foregroundColor(AstryxColors.iceWhite)
            }
            Spacer()
        }
        .padding(12)
        .background(AstryxColors.Semantic.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
