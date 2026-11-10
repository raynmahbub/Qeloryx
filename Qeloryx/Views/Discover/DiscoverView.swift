// QELORYX — Views/Discover
// DiscoverView.swift
// QEL-051 Discovery — Production with Taste DNA, Recommendations, Audio Lab, Spaces entry

import SwiftUI

public struct DiscoverView: View {
    
    @StateObject private var viewModel: DiscoverViewModel

    // The navigation links below hand these engines to child screens, so the
    // view needs its own references. Passing them only to the view model left
    // `body` unable to resolve them.
    private let tasteEngine: any TasteDNAEngineProtocol
    private let libraryEngine: any LibraryEngineProtocol
    private let dspEngine: any DSPEngineProtocol

    public init(
        tasteEngine: any TasteDNAEngineProtocol,
        libraryEngine: any LibraryEngineProtocol,
        dspEngine: any DSPEngineProtocol
    ) {
        self.tasteEngine = tasteEngine
        self.libraryEngine = libraryEngine
        self.dspEngine = dspEngine
        _viewModel = StateObject(
            wrappedValue: DiscoverViewModel(
                tasteEngine: tasteEngine,
                libraryEngine: libraryEngine,
                dspEngine: dspEngine
            )
        )
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
        .navigationTitle("Discover")
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
                NavigationLink(destination: TasteDNAView(tasteEngine: tasteEngine, libraryEngine: libraryEngine)) {
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
        NavigationLink(destination: AudioLabView(dspEngine: dspEngine)) {
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
        NavigationLink(destination: SocialView()) {
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
        NavigationLink(destination: StatisticsView(libraryEngine: libraryEngine)) {
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
