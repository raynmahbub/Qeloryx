// QELORYX — Features/Library
// LibraryView.swift
// QEL-024 Library DNA — Production UI with multi-library, grouping, folder view

import SwiftUI

public struct LibraryView: View {
    
    @StateObject private var viewModel: LibraryViewModel
    @State private var showAddLibrary = false
    @State private var showDuplicates = false
    @State private var duplicateGroups: [[AstryxTrack]] = []
    
    public init(viewModel: LibraryViewModel = LibraryViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Stats header
                if let stats = viewModel.stats {
                    statsHeader(stats: stats)
                }
                
                // Tab selector — Midnight Aurora
                tabSelector
                
                // Content based on selected tab
                contentView
            }
            .background(AstryxColors.Semantic.background.ignoresSafeArea())
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $viewModel.searchText, prompt: "Search \(viewModel.selectedTab.rawValue)")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { Task { await viewModel.startIndexing() } }) {
                            Label("Rescan Libraries", systemImage: "arrow.triangle.2.circlepath")
                        }
                        Button(action: { showAddLibrary = true }) {
                            Label("Add Library", systemImage: "plus")
                        }
                        Button(action: {
                            Task {
                                duplicateGroups = await viewModel.scanForDuplicates()
                                showDuplicates = true
                            }
                        }) {
                            Label("Find Duplicates", systemImage: "doc.on.doc")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(AstryxColors.auroraBlue)
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if viewModel.isIndexing {
                        HStack(spacing: 8) {
                            ProgressView().tint(AstryxColors.auroraBlue)
                            Text("\(viewModel.indexingProgress.completed)/\(viewModel.indexingProgress.total)")
                                .font(AstryxTypography.Body.caption)
                        }
                    }
                }
            }
            .task {
                await viewModel.loadAll()
            }
            .refreshable {
                await viewModel.loadAll()
            }
            .sheet(isPresented: $showAddLibrary) {
                AddLibraryView { name, url, type in
                    Task { await viewModel.addLibrary(name: name, url: url, type: type) }
                }
            }
            .sheet(isPresented: $showDuplicates) {
                DuplicatesView(groups: duplicateGroups)
            }
            .overlay {
                if viewModel.isLoading && viewModel.tracks.isEmpty {
                    ProgressView("Loading Library...")
                        .tint(AstryxColors.auroraBlue)
                }
            }
        }
    }
    
    // MARK: - Stats Header
    
    private func statsHeader(stats: LibraryStats) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AstryxSpacing.md) {
                StatCard(title: "\(stats.trackCount)", subtitle: "Songs", icon: "music.note")
                StatCard(title: "\(stats.albumCount)", subtitle: "Albums", icon: "rectangle.stack")
                StatCard(title: "\(stats.artistCount)", subtitle: "Artists", icon: "person.2")
                StatCard(title: stats.totalDuration.formattedDuration, subtitle: "Duration", icon: "clock")
                StatCard(title: ByteCountFormatter.string(fromByteCount: stats.totalSize, countStyle: .file), subtitle: "Size", icon: "internaldrive")
                StatCard(title: "\(stats.favoriteCount)", subtitle: "Favorites", icon: "heart.fill")
            }
            .padding(.horizontal, AstryxSpacing.screenPadding)
            .padding(.vertical, AstryxSpacing.sm)
        }
        .background(AstryxColors.Semantic.backgroundSecondary)
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AstryxSpacing.sm) {
                ForEach(LibraryTab.allCases) { tab in
                    Button {
                        viewModel.selectedTab = tab
                        Task { await viewModel.loadForCurrentTab() }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon).font(.system(size: 14))
                            Text(tab.rawValue).font(AstryxTypography.Label.small)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(viewModel.selectedTab == tab ? AstryxColors.auroraBlue : AstryxColors.Semantic.surface)
                        .foregroundColor(viewModel.selectedTab == tab ? AstryxColors.iceWhite : AstryxColors.Semantic.foregroundSecondary)
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, AstryxSpacing.screenPadding)
            .padding(.vertical, AstryxSpacing.sm)
        }
    }
    
    // MARK: - Content
    
    @ViewBuilder
    private var contentView: some View {
        switch viewModel.selectedTab {
        case .songs:
            SongsListView(tracks: viewModel.tracks, viewModel: viewModel)
        case .albums:
            AlbumsGridView(albums: viewModel.albums, viewModel: viewModel)
        case .artists:
            ArtistsListView(artists: viewModel.artists, viewModel: viewModel)
        case .genres:
            GenresListView(genres: viewModel.genres, viewModel: viewModel)
        case .folders:
            FoldersListView(folders: viewModel.folders, viewModel: viewModel)
        case .favorites:
            SongsListView(tracks: viewModel.favorites, viewModel: viewModel)
        case .recent:
            SongsListView(tracks: viewModel.recentlyAdded, viewModel: viewModel)
        case .history:
            SongsListView(tracks: viewModel.history, viewModel: viewModel)
        }
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let title: String
    let subtitle: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 16)).foregroundColor(AstryxColors.auroraBlue)
            Text(title).font(AstryxTypography.Label.small).foregroundColor(AstryxColors.Semantic.foreground).lineLimit(1)
            Text(subtitle).font(AstryxTypography.Body.caption2).foregroundColor(AstryxColors.Semantic.foregroundTertiary)
        }
        .frame(width: 80, height: 60)
        .background(AstryxColors.Semantic.surface)
        .clipShape(RoundedRectangle(cornerRadius: AstryxCornerRadius.sm))
    }
}

// MARK: - Songs List

private struct SongsListView: View {
    let tracks: [AstryxTrack]
    @ObservedObject var viewModel: LibraryViewModel
    
    var body: some View {
        List(tracks, id: \.id) { track in
            SongRow(track: track, viewModel: viewModel)
                .listRowBackground(AstryxColors.Semantic.background)
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {} label: { Label("Delete", systemImage: "trash") }
                    Button { Task { await viewModel.toggleFavorite(track) } } label: { Label(track.isFavorite ? "Unfavorite" : "Favorite", systemImage: track.isFavorite ? "heart.slash" : "heart") }.tint(AstryxColors.sunset)
                }
                .swipeActions(edge: .leading) {
                    Button { Task { await viewModel.playTrack(track) } } label: { Label("Play", systemImage: "play.fill") }.tint(AstryxColors.auroraBlue)
                }
        }
        .listStyle(.plain)
        .background(AstryxColors.Semantic.background)
    }
}

private struct SongRow: View {
    let track: AstryxTrack
    @ObservedObject var viewModel: LibraryViewModel
    
    var body: some View {
        HStack(spacing: AstryxSpacing.sm) {
            AstryxArtwork(data: track.artworkData, size: 48)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(track.title).font(AstryxTypography.Label.medium).foregroundColor(AstryxColors.Semantic.foreground).lineLimit(1)
                HStack(spacing: 4) {
                    Text(track.artist).font(AstryxTypography.Body.small).foregroundColor(AstryxColors.Semantic.foregroundSecondary).lineLimit(1)
                    if track.isLossless {
                        Image(systemName: "waveform").font(.system(size: 8)).foregroundColor(AstryxColors.emerald)
                    }
                    if track.isFavorite {
                        Image(systemName: "heart.fill").font(.system(size: 8)).foregroundColor(AstryxColors.sunset)
                    }
                }
                Text(track.album).font(AstryxTypography.Body.caption).foregroundColor(AstryxColors.Semantic.foregroundTertiary).lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(track.formattedDuration).font(AstryxTypography.Body.caption).foregroundColor(AstryxColors.Semantic.foregroundTertiary)
                if track.playCount > 0 {
                    Text("\(track.playCount) plays").font(AstryxTypography.Body.caption2).foregroundColor(AstryxColors.Semantic.foregroundTertiary)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { Task { await viewModel.playTrack(track) } }
    }
}

// MARK: - Albums Grid

private struct AlbumsGridView: View {
    let albums: [AstryxAlbum]
    @ObservedObject var viewModel: LibraryViewModel
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: AstryxSpacing.md) {
                ForEach(albums, id: \.id) { album in
                    AlbumCard(album: album, viewModel: viewModel)
                }
            }
            .padding(AstryxSpacing.screenPadding)
        }
        .background(AstryxColors.Semantic.background)
    }
}

private struct AlbumCard: View {
    let album: AstryxAlbum
    @ObservedObject var viewModel: LibraryViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: AstryxSpacing.sm) {
            AstryxArtwork(data: album.tracks.first?.artworkData, size: 160)
                .frame(maxWidth: .infinity)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(album.title).font(AstryxTypography.Label.medium).foregroundColor(AstryxColors.Semantic.foreground).lineLimit(1)
                Text(album.artist).font(AstryxTypography.Body.small).foregroundColor(AstryxColors.Semantic.foregroundSecondary).lineLimit(1)
                Text("\(album.trackCount) tracks • \(album.duration.formattedDuration)").font(AstryxTypography.Body.caption).foregroundColor(AstryxColors.Semantic.foregroundTertiary).lineLimit(1)
            }
            .padding(.horizontal, AstryxSpacing.sm)
            .padding(.bottom, AstryxSpacing.sm)
        }
        .background(AstryxColors.Semantic.surface)
        .clipShape(RoundedRectangle(cornerRadius: AstryxCornerRadius.card))
        .onTapGesture { Task { await viewModel.playAlbum(album) } }
    }
}

// MARK: - Artists List

private struct ArtistsListView: View {
    let artists: [AstryxArtist]
    @ObservedObject var viewModel: LibraryViewModel
    
    var body: some View {
        List(artists, id: \.id) { artist in
            HStack {
                AstryxArtwork(data: nil, size: 48)
                VStack(alignment: .leading) {
                    Text(artist.name).font(AstryxTypography.Label.medium)
                    Text("\(artist.albumCount) albums • \(artist.trackCount) tracks").font(AstryxTypography.Body.small).foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(AstryxColors.Semantic.foregroundTertiary)
            }
            .contentShape(Rectangle())
            .onTapGesture { Task { await viewModel.playArtist(artist.name) } }
            .listRowBackground(AstryxColors.Semantic.background)
        }
        .listStyle(.plain)
        .background(AstryxColors.Semantic.background)
    }
}

// MARK: - Genres List

private struct GenresListView: View {
    let genres: [AstryxGenre]
    @ObservedObject var viewModel: LibraryViewModel
    
    var body: some View {
        List(genres, id: \.id) { genre in
            HStack {
                VStack(alignment: .leading) {
                    Text(genre.name).font(AstryxTypography.Label.medium)
                    Text("\(genre.trackCount) tracks • \(genre.albumCount) albums").font(AstryxTypography.Body.small).foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                }
                Spacer()
                Text("\(genre.trackCount)").font(AstryxTypography.Body.caption).foregroundColor(AstryxColors.Semantic.foregroundTertiary)
            }
            .listRowBackground(AstryxColors.Semantic.background)
        }
        .listStyle(.plain)
        .background(AstryxColors.Semantic.background)
    }
}

// MARK: - Folders List

private struct FoldersListView: View {
    let folders: [AstryxFolder]
    @ObservedObject var viewModel: LibraryViewModel
    
    var body: some View {
        List(folders, id: \.id) { folder in
            HStack {
                Image(systemName: "folder.fill").foregroundColor(AstryxColors.auroraBlue)
                VStack(alignment: .leading) {
                    Text(folder.name).font(AstryxTypography.Label.medium)
                    Text(folder.path).font(AstryxTypography.Body.caption).foregroundColor(AstryxColors.Semantic.foregroundTertiary).lineLimit(1)
                }
                Spacer()
                Text("\(folder.trackCount)").font(AstryxTypography.Body.caption)
            }
            .listRowBackground(AstryxColors.Semantic.background)
        }
        .listStyle(.plain)
        .background(AstryxColors.Semantic.background)
    }
}

// MARK: - Add Library View

private struct AddLibraryView: View {
    @State private var name = ""
    @State private var path = ""
    @State private var type: LibraryType = .local
    @Environment(\.dismiss) private var dismiss
    var onAdd: (String, URL, LibraryType) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Library Info") {
                    TextField("Name", text: $name)
                    TextField("Path (e.g. /Music)", text: $path)
                    Picker("Type", selection: $type) {
                        ForEach(LibraryType.allCases, id: \.self) { t in Text(t.rawValue).tag(t) }
                    }
                }
                Section("Supported Formats") {
                    Text("MP3, AAC, M4A, ALAC, FLAC, WAV, AIFF, OGG, OPUS").font(AstryxTypography.Body.small).foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                }
            }
            .navigationTitle("Add Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let url = URL(fileURLWithPath: path)
                        onAdd(name, url, type)
                        dismiss()
                    }
                    .disabled(name.isEmpty || path.isEmpty)
                }
            }
        }
    }
}

// MARK: - Duplicates View

private struct DuplicatesView: View {
    let groups: [[AstryxTrack]]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(groups.enumerated()), id: \.offset) { index, group in
                    Section("Duplicate Group \(index + 1) — \(group.count) tracks") {
                        ForEach(group, id: \.id) { track in
                            VStack(alignment: .leading) {
                                Text(track.title).font(AstryxTypography.Label.small)
                                Text(track.fileURL.path).font(AstryxTypography.Body.caption2).foregroundColor(AstryxColors.Semantic.foregroundTertiary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Duplicates (\(groups.count) groups)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}

// MARK: - Duration Formatting Extension

private extension TimeInterval {
    var formattedDuration: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        else { return "\(minutes)m"
        }
    }
}
