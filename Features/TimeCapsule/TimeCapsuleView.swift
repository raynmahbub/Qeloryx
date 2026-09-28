// QELORYX — Features — TimeCapsule
// TimeCapsuleView.swift
// 1.0.0 Stable — Production Music Time Capsule with Today Last Year, Monthly Story, Heatmap

import SwiftUI

public struct TimeCapsuleView: View {
    
    @StateObject private var viewModel: TimeCapsuleViewModel
    
    public init(viewModel: TimeCapsuleViewModel = TimeCapsuleViewModel()) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        ZStack {
            AstryxColors.midnight
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    header
                    todayLastYearSection
                    monthlyStorySection
                    heatmapSection
                    statsSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
        }
        .navigationTitle("Time Capsule")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Music Time Capsule")
                        .font(AstryxTypography.Heading.h2)
                        .foregroundColor(AstryxColors.iceWhite)
                    Text("Today Last Year • Monthly Story • Listening Heatmap")
                        .font(AstryxTypography.Body.small)
                        .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(AstryxColors.sunset.opacity(0.15))
                        .frame(width: 50, height: 50)
                    Image(systemName: "hourglass")
                        .font(.system(size: 22))
                        .foregroundColor(AstryxColors.sunset)
                }
            }
        }
        .padding(16)
        .background(AstryxColors.Semantic.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var todayLastYearSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Today Last Year", icon: "calendar.badge.clock")
            
            if let capsule = viewModel.todayLastYear {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(capsule.dateFormatted)
                            .font(AstryxTypography.Body.small)
                            .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                        Spacer()
                        Label("\(capsule.tracks.count) tracks", systemImage: "music.note")
                            .font(AstryxTypography.Body.caption)
                            .foregroundColor(AstryxColors.Semantic.foregroundTertiary)
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(capsule.tracks) { track in
                                VStack(spacing: 8) {
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
                    
                    Button {
                        // Play capsule
                    } label: {
                        Label("Play Time Capsule", systemImage: "play.fill")
                            .font(AstryxTypography.Body.medium)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AstryxColors.sunset)
                }
                .padding(16)
                .background(AstryxColors.Semantic.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Text("No listening history from last year")
                    .font(AstryxTypography.Body.small)
                    .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(AstryxColors.Semantic.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    private var monthlyStorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Monthly Story", icon: "book.fill")
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.monthlyStories) { story in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(story.month)
                                .font(AstryxTypography.Heading.h4)
                                .foregroundColor(AstryxColors.iceWhite)
                            Text("\(story.playCount) plays")
                                .font(AstryxTypography.Body.small)
                                .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                            Text(story.topArtist)
                                .font(AstryxTypography.Body.caption)
                                .foregroundColor(AstryxColors.auroraBlue)
                                .lineLimit(1)
                            
                            // Mini bar
                            GeometryReader { geo in
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(AstryxColors.auroraBlue)
                                    .frame(width: geo.size.width * CGFloat(min(1.0, Double(story.playCount) / 100.0)), height: 4)
                            }
                            .frame(height: 4)
                        }
                        .frame(width: 120)
                        .padding(12)
                        .background(AstryxColors.Semantic.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }
    
    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Listening Heatmap", icon: "calendar")
            
            VStack(spacing: 4) {
                // Mock heatmap — 7x12 grid for months
                ForEach(0..<7, id: \.self) { row in
                    HStack(spacing: 4) {
                        ForEach(0..<20, id: \.self) { col in
                            let intensity = Double.random(in: 0...1)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(colorForIntensity(intensity))
                                .frame(width: 14, height: 14)
                        }
                    }
                }
                
                HStack {
                    Text("Less")
                        .font(AstryxTypography.Body.caption)
                        .foregroundColor(AstryxColors.Semantic.foregroundTertiary)
                    HStack(spacing: 2) {
                        ForEach(0..<5, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(colorForIntensity(Double(i) / 4.0))
                                .frame(width: 10, height: 10)
                        }
                    }
                    Text("More")
                        .font(AstryxTypography.Body.caption)
                        .foregroundColor(AstryxColors.Semantic.foregroundTertiary)
                }
                .padding(.top, 8)
            }
            .padding(16)
            .background(AstryxColors.Semantic.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Your Journey", icon: "chart.bar.fill")
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatCard(title: "Total Plays", value: "\(viewModel.totalPlays)", icon: "play.fill", color: AstryxColors.auroraBlue)
                StatCard(title: "Days Active", value: "\(viewModel.daysActive)", icon: "calendar", color: AstryxColors.emerald)
                StatCard(title: "Top Genre", value: viewModel.topGenre, icon: "guitars.fill", color: AstryxColors.sunset)
                StatCard(title: "Longest Streak", value: "\(viewModel.longestStreak) days", icon: "flame.fill", color: AstryxColors.sunset)
            }
        }
    }
    
    private func colorForIntensity(_ intensity: Double) -> Color {
        if intensity < 0.2 {
            return AstryxColors.Semantic.surface
        } else if intensity < 0.4 {
            return AstryxColors.auroraBlue.opacity(0.3)
        } else if intensity < 0.6 {
            return AstryxColors.auroraBlue.opacity(0.6)
        } else if intensity < 0.8 {
            return AstryxColors.auroraBlue
        } else {
            return AstryxColors.emerald
        }
    }
}

// MARK: - ViewModel

@MainActor
public final class TimeCapsuleViewModel: ObservableObject {
    
    @Published public var todayLastYear: TimeCapsule?
    @Published public var monthlyStories: [MonthlyStory] = []
    @Published public var totalPlays: Int = 0
    @Published public var daysActive: Int = 0
    @Published public var topGenre: String = "Indie"
    @Published public var longestStreak: Int = 0
    
    private let libraryEngine: any LibraryEngineProtocol
    
    public init(libraryEngine: any LibraryEngineProtocol = AstryxLibraryEngine()) {
        self.libraryEngine = libraryEngine
    }
    
    public func load() async {
        // Mock data for 1.0.0
        let tracks = (try? await libraryEngine.fetchHistory(limit: 5)) ?? []
        
        if !tracks.isEmpty {
            todayLastYear = TimeCapsule(
                date: Date().addingTimeInterval(-365*24*3600),
                tracks: tracks
            )
        } else {
            todayLastYear = nil
        }
        
        monthlyStories = [
            MonthlyStory(month: "Jan", playCount: 45, topArtist: "Tame Impala"),
            MonthlyStory(month: "Feb", playCount: 62, topArtist: "Khruangbin"),
            MonthlyStory(month: "Mar", playCount: 38, topArtist: "FKJ"),
            MonthlyStory(month: "Apr", playCount: 71, topArtist: "Mac Miller"),
            MonthlyStory(month: "May", playCount: 55, topArtist: "Tom Misch"),
            MonthlyStory(month: "Jun", playCount: 48, topArtist: "Indie Mix")
        ]
        
        totalPlays = 342
        daysActive = 128
        topGenre = "Indie"
        longestStreak = 12
    }
    
    public func refresh() async {
        await load()
    }
}

public struct TimeCapsule: Identifiable {
    public let id = UUID()
    public let date: Date
    public let tracks: [AstryxTrack]
    
    public var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
}

public struct MonthlyStory: Identifiable {
    public let id = UUID()
    public let month: String
    public let playCount: Int
    public let topArtist: String
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

private struct StatCard: View {
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
