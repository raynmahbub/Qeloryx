// QELORYX — Features — Spaces
// SpacesView.swift
// QEL-051 Discovery — Production Astryx Spaces with Shared Queue, DJ Handoff, Live Reactions

import SwiftUI

public struct SpacesView: View {
    
    @StateObject private var viewModel: SpacesViewModel
    
    public init(viewModel: SpacesViewModel = SpacesViewModel()) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        ZStack {
            AstryxColors.midnight
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    header
                    activeSpacesSection
                    sharedQueueSection
                    reactionsSection
                    futureSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
        }
        .navigationTitle("Astryx Spaces")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.createSpace()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(AstryxColors.auroraBlue)
                }
            }
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Shared Listening")
                        .font(AstryxTypography.Heading.h2)
                        .foregroundColor(AstryxColors.iceWhite)
                    Text("Shared Queue • DJ Handoff • Live Reactions • Future Voice Rooms")
                        .font(AstryxTypography.Body.small)
                        .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(AstryxColors.auroraBlue.opacity(0.15))
                        .frame(width: 50, height: 50)
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 22))
                        .foregroundColor(AstryxColors.auroraBlue)
                }
            }
            
            HStack(spacing: 12) {
                SpaceStat(title: "Active", value: "\(viewModel.activeSpaces.count)", icon: "dot.radiowaves.leftAndRight")
                SpaceStat(title: "Listeners", value: "\(viewModel.totalListeners)", icon: "person.2.fill")
                SpaceStat(title: "Queue", value: "\(viewModel.sharedQueue.count)", icon: "music.note.list")
            }
        }
        .padding(16)
        .background(AstryxColors.Semantic.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var activeSpacesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Active Spaces", icon: "antenna.radiowaves.leftAndRight")
            
            if viewModel.activeSpaces.isEmpty {
                emptySpacesView
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.activeSpaces) { space in
                        SpaceCard(space: space, viewModel: viewModel)
                    }
                }
            }
        }
    }
    
    private var emptySpacesView: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.3")
                .font(.system(size: 32))
                .foregroundColor(AstryxColors.Semantic.foregroundSecondary.opacity(0.5))
            Text("No active spaces")
                .font(AstryxTypography.Body.medium)
                .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
            Text("Create a space to listen together")
                .font(AstryxTypography.Body.small)
                .foregroundColor(AstryxColors.Semantic.foregroundTertiary)
            Button {
                viewModel.createSpace()
            } label: {
                Label("Create Space", systemImage: "plus.circle.fill")
                    .font(AstryxTypography.Body.medium)
            }
            .buttonStyle(.borderedProminent)
            .tint(AstryxColors.auroraBlue)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(AstryxColors.Semantic.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var sharedQueueSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Shared Queue", icon: "music.note.list")
            
            if viewModel.sharedQueue.isEmpty {
                Text("Queue is empty — add tracks to share")
                    .font(AstryxTypography.Body.small)
                    .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(AstryxColors.Semantic.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(viewModel.sharedQueue.enumerated()), id: \.element.id) { index, track in
                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(AstryxTypography.Mono.small)
                                .foregroundColor(AstryxColors.Semantic.foregroundTertiary)
                                .frame(width: 20)
                            
                            AstryxArtwork(data: track.artworkData, size: 40)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(track.title)
                                    .font(AstryxTypography.Body.medium)
                                    .foregroundColor(AstryxColors.iceWhite)
                                    .lineLimit(1)
                                Text(track.artist)
                                    .font(AstryxTypography.Body.small)
                                    .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "person.fill")
                                .font(.system(size: 12))
                                .foregroundColor(AstryxColors.auroraBlue)
                        }
                        .padding(10)
                        .background(AstryxColors.Semantic.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
    }
    
    private var reactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Live Reactions", icon: "heart.circle.fill")
            
            HStack(spacing: 12) {
                ForEach(["❤️", "🔥", "😍", "🎧", "✨", "🙌"], id: \.self) { emoji in
                    Button {
                        viewModel.sendReaction(emoji)
                    } label: {
                        Text(emoji)
                            .font(.system(size: 24))
                            .frame(width: 48, height: 48)
                            .background(AstryxColors.Semantic.surface)
                            .clipShape(Circle())
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(AstryxColors.Semantic.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            if !viewModel.recentReactions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.recentReactions, id: \.self) { reaction in
                            Text(reaction)
                                .font(AstryxTypography.Body.small)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(AstryxColors.auroraBlue.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }
    
    private var futureSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Coming Soon", icon: "sparkles")
            
            VStack(spacing: 10) {
                FutureFeatureRow(icon: "mic.fill", title: "Voice Rooms", description: "Talk while listening together", isComingSoon: true)
                FutureFeatureRow(icon: "hand.raised.fill", title: "DJ Handoff", description: "Pass the DJ role to friends", isComingSoon: true)
                FutureFeatureRow(icon: "waveform.path.ecg", title: "Live Spectrum Share", description: "Share your audio lab live", isComingSoon: true)
            }
            .padding(16)
            .background(AstryxColors.Semantic.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - ViewModel

@MainActor
public final class SpacesViewModel: ObservableObject {
    
    @Published public var activeSpaces: [AstryxSpace] = []
    @Published public var sharedQueue: [AstryxTrack] = []
    @Published public var recentReactions: [String] = []
    @Published public var totalListeners: Int = 0
    
    public init() {
        // Mock data for QEL-051
        activeSpaces = [
            AstryxSpace(name: "Late Night Lo-Fi", host: "You", listeners: 3, isActive: true),
            AstryxSpace(name: "Indie Discovery", host: "Alex", listeners: 5, isActive: true)
        ]
        totalListeners = activeSpaces.reduce(0) { $0 + $1.listeners }
        sharedQueue = [] // Would be populated from queue engine
        recentReactions = ["❤️ from Alex", "🔥 from Sam", "🎧 from You"]
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

public struct AstryxSpace: Identifiable {
    public let id = UUID()
    public let name: String
    public let host: String
    public let listeners: Int
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

private struct SpaceStat: View {
    let title: String
    let value: String
    let icon: String
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(AstryxColors.auroraBlue)
                Text(title)
                    .font(AstryxTypography.Body.caption)
                    .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
            }
            Text(value)
                .font(AstryxTypography.Body.small)
                .foregroundColor(AstryxColors.iceWhite)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(AstryxColors.Semantic.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct SpaceCard: View {
    let space: AstryxSpace
    @ObservedObject var viewModel: SpacesViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AstryxColors.emerald.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: "antenna.radiowaves.leftAndRight")
                    .foregroundColor(AstryxColors.emerald)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(space.name)
                    .font(AstryxTypography.Body.medium)
                    .foregroundColor(AstryxColors.iceWhite)
                HStack(spacing: 8) {
                    Label(space.host, systemImage: "person.fill")
                    Label("\(space.listeners)", systemImage: "person.2.fill")
                }
                .font(AstryxTypography.Body.caption)
                .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
            }
            
            Spacer()
            
            Button("Join") {
                viewModel.joinSpace(space)
            }
            .font(AstryxTypography.Body.small)
            .buttonStyle(.borderedProminent)
            .tint(AstryxColors.auroraBlue)
        }
        .padding(14)
        .background(AstryxColors.Semantic.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct FutureFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let isComingSoon: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                .frame(width: 32, height: 32)
                .background(AstryxColors.Semantic.surface)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AstryxTypography.Body.medium)
                    .foregroundColor(AstryxColors.iceWhite)
                Text(description)
                    .font(AstryxTypography.Body.caption)
                    .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
            }
            
            Spacer()
            
            if isComingSoon {
                Text("Soon")
                    .font(AstryxTypography.Body.caption)
                    .foregroundColor(AstryxColors.auroraBlue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AstryxColors.auroraBlue.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
    }
}
