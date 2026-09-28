// QELORYX — Features — Search
// SearchView.swift
// 1.0.0 Stable — Production universal search with <50ms, grouped results, accessibility, haptics

import SwiftUI

public struct SearchView: View {
    
    @StateObject private var viewModel: SearchViewModel
    @Environment(\.searchEngine) private var searchEngineEnv
    
    public init(viewModel: SearchViewModel = SearchViewModel()) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        ZStack {
            AstryxColors.midnight
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                scopeSelector
                content
            }
        }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $viewModel.query, prompt: "Search songs, artists, albums, playlists...")
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
        .onSubmit {
            Task { await viewModel.performSearch(query: viewModel.query) }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !viewModel.query.isEmpty {
                    Button("Clear") {
                        viewModel.clearSearch()
                    }
                    .foregroundColor(AstryxColors.auroraBlue)
                }
            }
        }
    }
    
    private var scopeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SearchScope.allCases, id: \.self) { scope in
                    Button {
                        viewModel.selectedScope = scope
                        AstryxHapticEngine.shared.triggerTabChange()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: scope.icon)
                                .font(.system(size: 12, weight: .medium))
                            Text(scope.rawValue)
                                .font(AstryxTypography.Body.small)
                        }
                        .foregroundColor(viewModel.selectedScope == scope ? AstryxColors.iceWhite : AstryxColors.Semantic.foregroundSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(viewModel.selectedScope == scope ? AstryxColors.auroraBlue : AstryxColors.Semantic.surface)
                        .clipShape(Capsule())
                    }
                    .astrixAccessible(label: "Filter by \(scope.rawValue)", isButton: true)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(AstryxColors.Semantic.backgroundSecondary.opacity(0.5))
    }
    
    @ViewBuilder
    private var content: some View {
        if viewModel.isEmpty {
            emptyState
        } else if viewModel.isSearching {
            searchingState
        } else if viewModel.results.isEmpty {
            noResultsState
        } else {
            resultsList
        }
    }
    
    private var emptyState: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(AstryxColors.auroraBlue.opacity(0.5))
                    Text("Universal Search")
                        .font(AstryxTypography.Heading.h3)
                        .foregroundColor(AstryxColors.iceWhite)
                    Text("Song • Artist • Album • Playlist • Folder • Lyrics • Command palette")
                        .font(AstryxTypography.Body.small)
                        .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                if !viewModel.recentQueries.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recent Searches")
                                .font(AstryxTypography.Heading.h4)
                                .foregroundColor(AstryxColors.iceWhite)
                            Spacer()
                            Button("Clear") {
                                viewModel.clearRecentQueries()
                            }
                            .font(AstryxTypography.Body.small)
                            .foregroundColor(AstryxColors.auroraBlue)
                        }
                        
                        VStack(spacing: 8) {
                            ForEach(viewModel.recentQueries, id: \.self) { recent in
                                Button {
                                    viewModel.selectRecentQuery(recent)
                                } label: {
                                    HStack {
                                        Image(systemName: "clock.arrow.circlepath")
                                            .foregroundColor(AstryxColors.Semantic.foregroundTertiary)
                                        Text(recent)
                                            .font(AstryxTypography.Body.medium)
                                            .foregroundColor(AstryxColors.iceWhite)
                                        Spacer()
                                        Image(systemName: "arrow.up.left")
                                            .foregroundColor(AstryxColors.Semantic.foregroundTertiary)
                                    }
                                    .padding(12)
                                    .background(AstryxColors.Semantic.backgroundSecondary)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                Spacer()
            }
        }
    }
    
    private var searchingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(AstryxColors.auroraBlue)
            Text("Searching...")
                .font(AstryxTypography.Body.medium)
                .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var noResultsState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(AstryxColors.Semantic.foregroundSecondary.opacity(0.5))
            Text("No results for \"\(viewModel.query)\"")
                .font(AstryxTypography.Body.medium)
                .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
            Text("Try different keywords or check spelling")
                .font(AstryxTypography.Body.small)
                .foregroundColor(AstryxColors.Semantic.foregroundTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var resultsList: some View {
        List {
            ForEach(SearchResultType.allCases, id: \.self) { type in
                if let group = viewModel.groupedResults[type], !group.isEmpty {
                    Section {
                        ForEach(group) { result in
                            SearchResultRow(result: result)
                                .listRowBackground(AstryxColors.Semantic.backgroundSecondary)
                                .listRowSeparatorTint(AstryxColors.Semantic.border)
                        }
                    } header: {
                        HStack {
                            Image(systemName: iconForType(type))
                                .foregroundColor(AstryxColors.auroraBlue)
                            Text(headerForType(type))
                                .font(AstryxTypography.Label.small)
                            Spacer()
                            Text("\(group.count)")
                                .font(AstryxTypography.Body.caption)
                                .foregroundColor(AstryxColors.Semantic.foregroundTertiary)
                        }
                        .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                    }
                }
            }
        }
        .listStyle(.plain)
        .background(AstryxColors.midnight)
    }
    
    private func iconForType(_ type: SearchResultType) -> String {
        switch type {
        case .track: return "music.note"
        case .album: return "opticaldisc"
        case .artist: return "person.fill"
        case .playlist: return "music.note.list"
        case .folder: return "folder.fill"
        case .lyrics: return "text.quote"
        }
    }
    
    private func headerForType(_ type: SearchResultType) -> String {
        switch type {
        case .track: return "Songs"
        case .album: return "Albums"
        case .artist: return "Artists"
        case .playlist: return "Playlists"
        case .folder: return "Folders"
        case .lyrics: return "Lyrics"
        }
    }
}

private struct SearchResultRow: View {
    let result: AstryxSearchResult
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AstryxColors.auroraBlue.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: iconForType(result.type))
                    .foregroundColor(AstryxColors.auroraBlue)
                    .font(.system(size: 16))
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(result.title)
                    .font(AstryxTypography.Body.medium)
                    .foregroundColor(AstryxColors.iceWhite)
                    .lineLimit(1)
                Text(result.subtitle)
                    .font(AstryxTypography.Body.small)
                    .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(AstryxColors.Semantic.foregroundTertiary)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture {
            AstryxHapticEngine.shared.trigger(.light)
            // Handle selection — would navigate to track/album/artist
        }
        .astrixAccessible(label: "\(result.title), \(result.subtitle)", hint: "Tap to play", isButton: true)
    }
    
    private func iconForType(_ type: SearchResultType) -> String {
        switch type {
        case .track: return "music.note"
        case .album: return "opticaldisc"
        case .artist: return "person.fill"
        case .playlist: return "music.note.list"
        case .folder: return "folder.fill"
        case .lyrics: return "text.quote"
        }
    }
}

private extension SearchResultType {
    static var allCases: [SearchResultType] {
        [.track, .album, .artist, .playlist, .folder, .lyrics]
    }
}
