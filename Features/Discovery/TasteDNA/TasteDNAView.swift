// QELORYX — Features — Discovery — TasteDNA
// TasteDNAView.swift
// QEL-051 Discovery — Production with evolving listening profile visualization

import SwiftUI

public struct TasteDNAView: View {
    
    @StateObject private var viewModel: TasteDNAViewModel
    
    public init(viewModel: TasteDNAViewModel = TasteDNAViewModel()) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        ZStack {
            AstryxColors.midnight
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    if viewModel.isLoading {
                        loadingView
                    } else if let profile = viewModel.profile {
                        profileHeader(profile: profile)
                        genresSection(profile: profile)
                        artistsSection(profile: profile)
                        moodSection(profile: profile)
                        erasSection(profile: profile)
                        statsSection(profile: profile)
                        recommendationsSection
                    } else {
                        emptyView
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
        }
        .navigationTitle("Taste DNA")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await viewModel.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                }
            }
        }
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView().tint(AstryxColors.auroraBlue)
            Text("Analyzing your taste...")
                .font(AstryxTypography.Body.medium)
                .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 48))
                .foregroundColor(AstryxColors.Semantic.foregroundSecondary.opacity(0.5))
            Text("No listening data yet")
                .font(AstryxTypography.Body.medium)
                .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
            Text("Play some music to generate your Taste DNA")
                .font(AstryxTypography.Body.small)
                .foregroundColor(AstryxColors.Semantic.foregroundTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding()
    }
    
    private func profileHeader(profile: AstryxTasteProfile) -> some View {
        VStack(spacing: 16) {
            // Summary
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Taste")
                        .font(AstryxTypography.Body.small)
                        .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                    Text(profile.summary)
                        .font(AstryxTypography.Heading.h2)
                        .foregroundColor(AstryxColors.iceWhite)
                        .lineLimit(2)
                }
                Spacer()
                // Diversity score circle
                ZStack {
                    Circle()
                        .stroke(AstryxColors.Semantic.surface, lineWidth: 6)
                        .frame(width: 60, height: 60)
                    Circle()
                        .trim(from: 0, to: profile.diversityScore)
                        .stroke(AstryxColors.auroraBlue, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(profile.diversityScore * 100))%")
                        .font(AstryxTypography.Body.small)
                        .foregroundColor(AstryxColors.iceWhite)
                }
            }
            
            // Listening time + total plays
            HStack(spacing: 12) {
                StatBadge(title: "Listening", value: profile.formattedListeningTime, icon: "clock.fill")
                StatBadge(title: "Plays", value: "\(profile.totalPlays)", icon: "play.fill")
                StatBadge(title: "Tracks", value: "\(profile.totalTracks)", icon: "music.note")
                StatBadge(title: "Favorites", value: "\(profile.favoriteCount)", icon: "heart.fill")
            }
        }
        .padding(16)
        .background(AstryxColors.Semantic.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func genresSection(profile: AstryxTasteProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Top Genres", icon: "guitars.fill")
            
            VStack(spacing: 10) {
                ForEach(profile.topGenres) { genre in
                    HStack(spacing: 12) {
                        // Color indicator
                        Circle()
                            .fill(Color(hex: genre.color))
                            .frame(width: 12, height: 12)
                        
                        Text(genre.name)
                            .font(AstryxTypography.Body.medium)
                            .foregroundColor(AstryxColors.iceWhite)
                            .frame(width: 80, alignment: .leading)
                        
                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(AstryxColors.Semantic.surface)
                                    .frame(height: 8)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(hex: genre.color))
                                    .frame(width: geo.size.width * genre.percentage, height: 8)
                            }
                        }
                        .frame(height: 8)
                        
                        Text("\(Int(genre.percentage * 100))%")
                            .font(AstryxTypography.Body.caption)
                            .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }
            .padding(16)
            .background(AstryxColors.Semantic.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private func artistsSection(profile: AstryxTasteProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Top Artists", icon: "person.2.fill")
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(profile.topArtists) { artist in
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(AstryxColors.auroraBlue.opacity(0.2))
                                    .frame(width: 60, height: 60)
                                Text(String(artist.name.prefix(1)))
                                    .font(AstryxTypography.Heading.h3)
                                    .foregroundColor(AstryxColors.auroraBlue)
                            }
                            Text(artist.name)
                                .font(AstryxTypography.Body.small)
                                .foregroundColor(AstryxColors.iceWhite)
                                .lineLimit(1)
                                .frame(width: 70)
                            Text("\(artist.playCount) plays")
                                .font(AstryxTypography.Body.caption)
                                .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                        }
                        .frame(width: 80)
                    }
                }
                .padding(.horizontal, 4)
            }
            .padding(12)
            .background(AstryxColors.Semantic.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private func moodSection(profile: AstryxTasteProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Mood", icon: "face.smiling.fill")
            
            HStack(spacing: 16) {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(AstryxColors.auroraBlue.opacity(0.15))
                            .frame(width: 80, height: 80)
                        VStack(spacing: 2) {
                            Text(profile.mood.primary)
                                .font(AstryxTypography.Heading.h4)
                                .foregroundColor(AstryxColors.iceWhite)
                            if let secondary = profile.mood.secondary {
                                Text(secondary)
                                    .font(AstryxTypography.Body.caption)
                                    .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                            }
                        }
                    }
                    Text("Primary Mood")
                        .font(AstryxTypography.Body.caption)
                        .foregroundColor(AstryxColors.Semantic.foregroundTertiary)
                }
                
                VStack(spacing: 12) {
                    // Energy
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Energy")
                                .font(AstryxTypography.Body.small)
                                .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                            Spacer()
                            Text("\(Int(profile.mood.energy * 100))%")
                                .font(AstryxTypography.Body.caption)
                                .foregroundColor(AstryxColors.iceWhite)
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(AstryxColors.Semantic.surface)
                                    .frame(height: 6)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(AstryxColors.sunset)
                                    .frame(width: geo.size.width * profile.mood.energy, height: 6)
                            }
                        }
                        .frame(height: 6)
                    }
                    
                    // Valence
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Happiness")
                                .font(AstryxTypography.Body.small)
                                .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                            Spacer()
                            Text("\(Int(profile.mood.valence * 100))%")
                                .font(AstryxTypography.Body.caption)
                                .foregroundColor(AstryxColors.iceWhite)
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(AstryxColors.Semantic.surface)
                                    .frame(height: 6)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(AstryxColors.emerald)
                                    .frame(width: geo.size.width * profile.mood.valence, height: 6)
                            }
                        }
                        .frame(height: 6)
                    }
                }
            }
            .padding(16)
            .background(AstryxColors.Semantic.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private func erasSection(profile: AstryxTasteProfile) -> some View {
        guard !profile.topEras.isEmpty else { return AnyView(EmptyView()) }
        
        return AnyView(
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Eras", icon: "calendar")
                
                HStack(spacing: 12) {
                    ForEach(profile.topEras, id: \.decade) { era in
                        VStack(spacing: 6) {
                            Text(era.decade)
                                .font(AstryxTypography.Heading.h4)
                                .foregroundColor(AstryxColors.iceWhite)
                            Text("\(era.count) tracks")
                                .font(AstryxTypography.Body.caption)
                                .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                            Text("\(Int(era.percentage * 100))%")
                                .font(AstryxTypography.Body.small)
                                .foregroundColor(AstryxColors.auroraBlue)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(AstryxColors.Semantic.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(12)
                .background(AstryxColors.Semantic.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        )
    }
    
    private func statsSection(profile: AstryxTasteProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Stats", icon: "chart.bar.fill")
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatCard(title: "Total Duration", value: formatDuration(profile.totalDuration), icon: "clock")
                StatCard(title: "Avg Plays", value: profile.totalTracks > 0 ? "\(profile.totalPlays / profile.totalTracks)" : "0", icon: "repeat")
                StatCard(title: "Diversity", value: "\(Int(profile.diversityScore * 100))%", icon: "shuffle")
                StatCard(title: "Last Updated", value: RelativeDateTimeFormatter().localizedString(for: profile.lastUpdated, relativeTo: Date()), icon: "calendar.badge.clock")
            }
        }
    }
    
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Recommendations", icon: "sparkles")
            
            ForEach(viewModel.recommendations) { rec in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: rec.type.icon)
                            .foregroundColor(AstryxColors.auroraBlue)
                        Text(rec.title)
                            .font(AstryxTypography.Heading.h5)
                            .foregroundColor(AstryxColors.iceWhite)
                        Spacer()
                        Text(rec.type.rawValue)
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
                                    AstryxArtwork(data: track.artworkData, size: 60)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    Text(track.title)
                                        .font(AstryxTypography.Body.caption)
                                        .foregroundColor(AstryxColors.iceWhite)
                                        .lineLimit(1)
                                        .frame(width: 60)
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
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

// MARK: - ViewModel

@MainActor
public final class TasteDNAViewModel: ObservableObject {
    
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
        
        // Fetch tracks from library
        let tracks = (try? await libraryEngine.fetchTracks(predicate: nil)) ?? []
        
        if tracks.isEmpty {
            // Generate mock profile for preview if no tracks
            profile = mockProfile
            recommendations = mockRecommendations
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
                TasteGenre(name: "Lo-Fi", playCount: 60, percentage: 0.20, color: "#6B7280"),
                TasteGenre(name: "Jazz", playCount: 40, percentage: 0.12, color: "#8B5CF6"),
                TasteGenre(name: "Electronic", playCount: 30, percentage: 0.08, color: "#06B6D4")
            ],
            topArtists: [
                TasteArtist(name: "Tame Impala", playCount: 45, trackCount: 12, percentage: 0.3),
                TasteArtist(name: "Khruangbin", playCount: 38, trackCount: 8, percentage: 0.25),
                TasteArtist(name: "Mac Miller", playCount: 32, trackCount: 15, percentage: 0.2),
                TasteArtist(name: "FKJ", playCount: 28, trackCount: 6, percentage: 0.15),
                TasteArtist(name: "Tom Misch", playCount: 20, trackCount: 10, percentage: 0.1)
            ],
            mood: TasteMood(primary: "Chill", secondary: "Introspective", energy: 0.35, valence: 0.55),
            topEras: [
                TasteEra(decade: "2020s", count: 120, percentage: 0.5),
                TasteEra(decade: "2010s", count: 80, percentage: 0.3),
                TasteEra(decade: "2000s", count: 40, percentage: 0.2)
            ],
            totalPlays: 342,
            totalTracks: 240,
            totalDuration: 86400,
            favoriteCount: 42,
            listeningTime: 123456,
            diversityScore: 0.72
        )
    }
    
    private var mockRecommendations: [AstryxRecommendation] {
        [] // Empty for mock, real would be generated
    }
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

private struct StatBadge: View {
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
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(AstryxColors.Semantic.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AstryxColors.auroraBlue)
                .frame(width: 32, height: 32)
                .background(AstryxColors.auroraBlue.opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AstryxTypography.Body.caption)
                    .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                Text(value)
                    .font(AstryxTypography.Body.medium)
                    .foregroundColor(AstryxColors.iceWhite)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(12)
        .background(AstryxColors.Semantic.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
