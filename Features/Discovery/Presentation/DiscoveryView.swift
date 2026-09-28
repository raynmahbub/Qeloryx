// QELORYX — Features — Discovery
// DiscoveryView.swift
// QEL-051 Discovery — Production with Taste DNA, Recommendations, Audio Lab, Spaces entry

import SwiftUI

public struct DiscoveryView: View {
    
    @StateObject private var viewModel: DiscoveryViewModel
    
    public init(viewModel: DiscoveryViewModel = DiscoveryViewModel()) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        ZStack {
            AstryxColors.midnight
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    header
                    tasteDNASection
                    recommendationsSection
                    audioLabEntry
                    spacesEntry
                    timeCapsuleEntry
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
        }
        .navigationTitle("Discovery")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Discover")
                .font(AstryxTypography.Heading.h1)
                .foregroundColor(AstryxColors.iceWhite)
            Text("Taste DNA • Recommendations • Audio Lab • Spaces • Time Capsule")
                .font(AstryxTypography.Body.small)
                .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var tasteDNASection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "Your Taste DNA", icon: "waveform.path.ecg")
                Spacer()
                NavigationLink(destination: TasteDNAView()) {
                    Text("View All")
                        .font(AstryxTypography.Body.small)
                        .foregroundColor(AstryxColors.auroraBlue)
                }
            }
            
            if let profile = viewModel.profile {
                HStack(spacing: 12) {
                    ForEach(profile.topGenres.prefix(3)) { genre in
                        VStack(spacing: 6) {
                            Text(genre.name)
                                .font(AstryxTypography.Body.medium)
                                .foregroundColor(AstryxColors.iceWhite)
                            Text("\(Int(genre.percentage * 100))%")
                                .font(AstryxTypography.Body.small)
                                .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(AstryxColors.Semantic.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                
                HStack {
                    Label(profile.mood.primary, systemImage: "face.smiling")
                    Spacer()
                    Label(profile.formattedListeningTime, systemImage: "clock")
                    Spacer()
                    Label("\(Int(profile.diversityScore * 100))% diverse", systemImage: "shuffle")
                }
                .font(AstryxTypography.Body.small)
                .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                .padding(12)
                .background(AstryxColors.Semantic.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                Text("Analyzing your taste...")
                    .font(AstryxTypography.Body.small)
                    .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(AstryxColors.Semantic.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "For You", icon: "sparkles")
            
            if viewModel.recommendations.isEmpty {
                Text("No recommendations yet — play more music")
                    .font(AstryxTypography.Body.small)
                    .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(AstryxColors.Semantic.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                ForEach(viewModel.recommendations) { rec in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: rec.type.icon)
                                .foregroundColor(AstryxColors.auroraBlue)
                            Text(rec.title)
                                .font(AstryxTypography.Heading.h5)
                                .foregroundColor(AstryxColors.iceWhite)
                            Spacer()
                            Text("\(rec.tracks.count) tracks")
                                .font(AstryxTypography.Body.caption)
                                .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                        }
                        Text(rec.reason)
                            .font(AstryxTypography.Body.small)
                            .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(rec.tracks.prefix(5)) { track in
                                    VStack(spacing: 6) {
                                        AstryxArtwork(data: track.artworkData, size: 80)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                        Text(track.title)
                                            .font(AstryxTypography.Body.caption)
                                            .foregroundColor(AstryxColors.iceWhite)
                                            .lineLimit(1)
                                            .frame(width: 80)
                                    }
                                }
                            }
                        }
                    }
                    .padding(14)
                    .background(AstryxColors.Semantic.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
    
    private var audioLabEntry: some View {
        NavigationLink(destination: AudioLabView()) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(AstryxColors.auroraBlue.opacity(0.15))
                        .frame(width: 50, height: 50)
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 22))
                        .foregroundColor(AstryxColors.auroraBlue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Astryx Audio Lab")
                        .font(AstryxTypography.Heading.h4)
                        .foregroundColor(AstryxColors.iceWhite)
                    Text("Signal Path • EQ • Spectrum • Diagnostics")
                        .font(AstryxTypography.Body.small)
                        .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(AstryxColors.Semantic.foregroundTertiary)
            }
            .padding(16)
            .background(AstryxColors.Semantic.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private var spacesEntry: some View {
        NavigationLink(destination: SpacesView()) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(AstryxColors.emerald.opacity(0.15))
                        .frame(width: 50, height: 50)
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 22))
                        .foregroundColor(AstryxColors.emerald)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Astryx Spaces")
                        .font(AstryxTypography.Heading.h4)
                        .foregroundColor(AstryxColors.iceWhite)
                    Text("Shared Queue • DJ Handoff • Live Reactions")
                        .font(AstryxTypography.Body.small)
                        .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(AstryxColors.Semantic.foregroundTertiary)
            }
            .padding(16)
            .background(AstryxColors.Semantic.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private var timeCapsuleEntry: some View {
        NavigationLink(destination: TimeCapsuleView()) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(AstryxColors.sunset.opacity(0.15))
                        .frame(width: 50, height: 50)
                    Image(systemName: "hourglass")
                        .font(.system(size: 22))
                        .foregroundColor(AstryxColors.sunset)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Time Capsule")
                        .font(AstryxTypography.Heading.h4)
                        .foregroundColor(AstryxColors.iceWhite)
                    Text("Rediscover your past listening")
                        .font(AstryxTypography.Body.small)
                        .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(AstryxColors.Semantic.foregroundTertiary)
            }
            .padding(16)
            .background(AstryxColors.Semantic.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - ViewModel

@MainActor
public final class DiscoveryViewModel: ObservableObject {
    
    @Published public var profile: AstryxTasteProfile?
    @Published public var recommendations: [AstryxRecommendation] = []
    @Published public var isLoading: Bool = false
    
    private let tasteEngine: any TasteDNAEngineProtocol
    private let libraryEngine: any LibraryEngineProtocol
    
    public init(
        tasteEngine: any TasteDNAEngineProtocol = AstryxTasteDNAEngine(),
        libraryEngine: any LibraryEngineProtocol = AstryxLibraryEngine()
    ) {
        self.tasteEngine = tasteEngine
        self.libraryEngine = libraryEngine
    }
    
    public func load() async {
        isLoading = true
        
        let tracks = (try? await libraryEngine.fetchTracks(predicate: nil)) ?? []
        
        if tracks.isEmpty {
            // Mock for preview
            profile = mockProfile
            recommendations = []
            isLoading = false
            return
        }
        
        let generated = await tasteEngine.generateProfile(from: tracks)
        profile = generated
        
        let recs = await tasteEngine.recommendations(for: generated, from: tracks, limit: 5)
        recommendations = recs
        
        isLoading = false
    }
    
    public func refresh() async {
        await load()
    }
    
    private var mockProfile: AstryxTasteProfile {
        AstryxTasteProfile(
            topGenres: [
                TasteGenre(name: "Indie", playCount: 120, percentage: 0.35, color: "#10B981"),
                TasteGenre(name: "Rock", playCount: 80, percentage: 0.25, color: "#EF4444"),
                TasteGenre(name: "Lo-Fi", playCount: 60, percentage: 0.20, color: "#6B7280")
            ],
            topArtists: [
                TasteArtist(name: "Tame Impala", playCount: 45, trackCount: 12, percentage: 0.3),
                TasteArtist(name: "Khruangbin", playCount: 38, trackCount: 8, percentage: 0.25)
            ],
            mood: TasteMood(primary: "Chill", energy: 0.35, valence: 0.55),
            totalPlays: 342,
            totalTracks: 240,
            totalDuration: 86400,
            favoriteCount: 42,
            listeningTime: 123456,
            diversityScore: 0.72
        )
    }
}

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
