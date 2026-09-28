// QELORYX — Features — Dashboard
// DashboardView.swift
// QEL-051 Discovery — Production Dashboard with widgets, Taste DNA entry, Audio Lab, Spaces

import SwiftUI

public struct DashboardView: View {
    
    @StateObject private var viewModel: DashboardViewModel
    
    public init(viewModel: DashboardViewModel = DashboardViewModel()) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        ZStack {
            AstryxColors.midnight
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    greetingHeader
                    tasteDNAWidget
                    statsGrid
                    quickActions
                    recentSection
                    discoverySection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
        }
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
    
    private var greetingHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.greeting)
                    .font(AstryxTypography.Heading.h2)
                    .foregroundColor(AstryxColors.iceWhite)
                Text(viewModel.subGreeting)
                    .font(AstryxTypography.Body.small)
                    .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
            }
            Spacer()
            ZStack {
                Circle()
                    .fill(AstryxColors.Gradients.aurora)
                    .frame(width: 50, height: 50)
                Text(String(viewModel.userInitial))
                    .font(AstryxTypography.Heading.h3)
                    .foregroundColor(AstryxColors.iceWhite)
            }
        }
    }
    
    private var tasteDNAWidget: some View {
        NavigationLink(destination: TasteDNAView()) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(AstryxColors.auroraBlue.opacity(0.15))
                        .frame(width: 60, height: 60)
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 28))
                        .foregroundColor(AstryxColors.auroraBlue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Taste DNA")
                        .font(AstryxTypography.Heading.h4)
                        .foregroundColor(AstryxColors.iceWhite)
                    Text(viewModel.tasteSummary)
                        .font(AstryxTypography.Body.small)
                        .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(AstryxColors.Semantic.foregroundTertiary)
            }
            .padding(16)
            .background(AstryxColors.Semantic.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AstryxColors.auroraBlue.opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            DashboardCard(title: "Favorites", value: "\(viewModel.favoriteCount)", icon: "heart.fill", color: AstryxColors.sunset, destination: AnyView(LibraryView()))
            DashboardCard(title: "Recent", value: "\(viewModel.recentCount)", icon: "clock.fill", color: AstryxColors.auroraBlue, destination: AnyView(LibraryView()))
            DashboardCard(title: "Downloads", value: "\(viewModel.downloadCount)", icon: "arrow.down.circle.fill", color: AstryxColors.emerald, destination: AnyView(DownloadsView()))
            DashboardCard(title: "Mood", value: viewModel.currentMood, icon: "face.smiling.fill", color: AstryxColors.auroraBlue, destination: AnyView(TasteDNAView()))
            DashboardCard(title: "Queue", value: "\(viewModel.queueCount)", icon: "music.note.list", color: AstryxColors.Semantic.foregroundSecondary, destination: AnyView(AstryxPlayerView()))
            DashboardCard(title: "Vinyl", value: "Collection", icon: "opticaldisc.fill", color: AstryxColors.Semantic.foregroundTertiary, destination: AnyView(LibraryView()))
        }
    }
    
    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Quick Actions", icon: "bolt.fill")
            
            HStack(spacing: 12) {
                QuickActionButton(title: "Audio Lab", icon: "waveform.path.ecg", color: AstryxColors.auroraBlue) {
                    // Navigate to Audio Lab
                }
                QuickActionButton(title: "Spaces", icon: "person.3.fill", color: AstryxColors.emerald) {
                    // Navigate to Spaces
                }
                QuickActionButton(title: "Shuffle", icon: "shuffle", color: AstryxColors.sunset) {
                    // Shuffle play
                }
                QuickActionButton(title: "Search", icon: "magnifyingglass", color: AstryxColors.Semantic.foregroundSecondary) {
                    // Search
                }
            }
        }
    }
    
    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Recently Played", icon: "clock.arrow.circlepath")
            
            if viewModel.recentTracks.isEmpty {
                Text("No recent tracks")
                    .font(AstryxTypography.Body.small)
                    .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(AstryxColors.Semantic.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.recentTracks) { track in
                            VStack(spacing: 8) {
                                AstryxArtwork(data: track.artworkData, size: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                Text(track.title)
                                    .font(AstryxTypography.Body.small)
                                    .foregroundColor(AstryxColors.iceWhite)
                                    .lineLimit(1)
                                    .frame(width: 100)
                                Text(track.artist)
                                    .font(AstryxTypography.Body.caption)
                                    .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                                    .lineLimit(1)
                                    .frame(width: 100)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var discoverySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Discovery", icon: "sparkles")
            
            VStack(spacing: 10) {
                DiscoveryRow(icon: "waveform.path.ecg", title: "Audio Lab", subtitle: "Signal Path • EQ • Spectrum", color: AstryxColors.auroraBlue)
                DiscoveryRow(icon: "person.3.fill", title: "Spaces", subtitle: "Shared Queue • Live Reactions", color: AstryxColors.emerald)
                DiscoveryRow(icon: "heart.circle.fill", title: "Taste DNA", subtitle: "Your evolving listening profile", color: AstryxColors.sunset)
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
public final class DashboardViewModel: ObservableObject {
    
    @Published public var favoriteCount: Int = 0
    @Published public var recentCount: Int = 0
    @Published public var downloadCount: Int = 0
    @Published public var queueCount: Int = 0
    @Published public var currentMood: String = "Chill"
    @Published public var tasteSummary: String = "Indie • Rock • Lo-Fi • Jazz"
    @Published public var recentTracks: [AstryxTrack] = []
    @Published public var greeting: String = "Good evening"
    @Published public var subGreeting: String = "Here's your music overview"
    @Published public var userInitial: String = "Q"
    
    private let libraryEngine: any LibraryEngineProtocol
    private let downloadEngine: any DownloadEngineProtocol
    private let tasteEngine: any TasteDNAEngineProtocol
    
    public init(
        libraryEngine: any LibraryEngineProtocol = AstryxLibraryEngine(),
        downloadEngine: any DownloadEngineProtocol = AstryxDownloadEngine(useRealSession: false),
        tasteEngine: any TasteDNAEngineProtocol = AstryxTasteDNAEngine()
    ) {
        self.libraryEngine = libraryEngine
        self.downloadEngine = downloadEngine
        self.tasteEngine = tasteEngine
        
        // Greeting based on time
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: greeting = "Good morning"
        case 12..<17: greeting = "Good afternoon"
        case 17..<22: greeting = "Good evening"
        default: greeting = "Good night"
        }
    }
    
    public func load() async {
        // Load stats
        let favorites = (try? await libraryEngine.fetchFavorites()) ?? []
        let history = (try? await libraryEngine.fetchHistory(limit: 10)) ?? []
        let downloads = await downloadEngine.allTasks()
        let profile = await tasteEngine.currentProfile()
        
        favoriteCount = favorites.count
        recentCount = history.count
        downloadCount = downloads.filter { $0.state == .completed }.count
        queueCount = 0 // Would come from queue engine
        
        if let profile = profile {
            currentMood = profile.mood.primary
            tasteSummary = profile.summary
        }
        
        recentTracks = history
        
        // Mock data if empty
        if favorites.isEmpty && history.isEmpty {
            favoriteCount = 42
            recentCount = 12
            downloadCount = 8
            queueCount = 5
            recentTracks = [] // Keep empty for now
        }
    }
    
    public func refresh() async {
        await load()
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

private struct DashboardCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let destination: AnyView
    
    var body: some View {
        NavigationLink(destination: destination) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(color)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(AstryxColors.Semantic.foregroundTertiary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .font(AstryxTypography.Heading.h3)
                        .foregroundColor(AstryxColors.iceWhite)
                        .lineLimit(1)
                    Text(title)
                        .font(AstryxTypography.Body.small)
                        .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                }
            }
            .padding(14)
            .background(AstryxColors.Semantic.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

private struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.15))
                    .clipShape(Circle())
                Text(title)
                    .font(AstryxTypography.Body.caption)
                    .foregroundColor(AstryxColors.iceWhite)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(AstryxColors.Semantic.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

private struct DiscoveryRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AstryxTypography.Body.medium)
                    .foregroundColor(AstryxColors.iceWhite)
                Text(subtitle)
                    .font(AstryxTypography.Body.caption)
                    .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(AstryxColors.Semantic.foregroundTertiary)
        }
        .padding(12)
        .background(AstryxColors.Semantic.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
