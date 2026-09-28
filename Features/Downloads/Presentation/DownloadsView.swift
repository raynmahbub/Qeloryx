// QELORYX — Features — Downloads
// DownloadsView.swift
// QEL-041 Downloads — Production with state machine UI, progress, resume/retry

import SwiftUI

public struct DownloadsView: View {
    
    @StateObject private var viewModel: DownloadsViewModel
    
    public init(viewModel: DownloadsViewModel = DownloadsViewModel()) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        ZStack {
            AstryxColors.midnight
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                statsHeader
                filterSelector
                content
            }
        }
        .navigationTitle("Downloads")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                menuButton
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search downloads")
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            await viewModel.loadTasks()
        }
    }
    
    // MARK: - Stats Header
    
    private var statsHeader: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                StatCard(title: "Total", value: "\(viewModel.stats.total)", icon: "arrow.down.circle")
                StatCard(title: "Downloading", value: "\(viewModel.stats.downloading)", icon: "arrow.down.circle.fill", color: AstryxColors.auroraBlue)
                StatCard(title: "Queued", value: "\(viewModel.stats.queued)", icon: "clock", color: AstryxColors.Semantic.foregroundSecondary)
                StatCard(title: "Completed", value: "\(viewModel.stats.completed)", icon: "checkmark.circle.fill", color: AstryxColors.emerald)
                StatCard(title: "Failed", value: "\(viewModel.stats.failed)", icon: "exclamationmark.circle", color: AstryxColors.sunset)
                StatCard(title: "Size", value: viewModel.stats.formattedDownloadedSize, icon: "internaldrive", color: AstryxColors.Semantic.foregroundTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(AstryxColors.Semantic.backgroundSecondary.opacity(0.5))
    }
    
    // MARK: - Filter Selector
    
    private var filterSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DownloadsFilter.allCases, id: \.self) { filter in
                    Button {
                        viewModel.selectedFilter = filter
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: filter.icon)
                                .font(.system(size: 12, weight: .medium))
                            Text(filter.rawValue)
                                .font(AstryxTypography.Body.small)
                        }
                        .foregroundColor(viewModel.selectedFilter == filter ? AstryxColors.iceWhite : AstryxColors.Semantic.foregroundSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            viewModel.selectedFilter == filter ? AstryxColors.auroraBlue : AstryxColors.Semantic.surface
                        )
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }
    
    // MARK: - Content
    
    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.filteredTasks.isEmpty {
            loadingView
        } else if viewModel.filteredTasks.isEmpty {
            emptyView
        } else {
            listView
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView().tint(AstryxColors.auroraBlue)
            Text("Loading downloads...")
                .font(AstryxTypography.Body.medium)
                .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 48))
                .foregroundColor(AstryxColors.Semantic.foregroundSecondary.opacity(0.5))
            Text(viewModel.searchText.isEmpty ? "No downloads" : "No matching downloads")
                .font(AstryxTypography.Body.medium)
                .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
            if viewModel.selectedFilter != .all {
                Button("Show All") {
                    viewModel.selectedFilter = .all
                }
                .font(AstryxTypography.Body.small)
                .foregroundColor(AstryxColors.auroraBlue)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var listView: some View {
        List {
            ForEach(viewModel.filteredTasks) { task in
                DownloadRow(task: task, viewModel: viewModel)
                    .listRowBackground(AstryxColors.Semantic.backgroundSecondary)
                    .listRowSeparatorTint(AstryxColors.Semantic.border)
            }
        }
        .listStyle(.plain)
        .background(AstryxColors.midnight)
    }
    
    private var menuButton: some View {
        Menu {
            Button { viewModel.resumeAll() } label: { Label("Resume All", systemImage: "play.fill") }
            Button { viewModel.pauseAll() } label: { Label("Pause All", systemImage: "pause.fill") }
            Divider()
            Button(role: .destructive) { viewModel.cancelAll() } label: { Label("Cancel All", systemImage: "xmark.circle") }
            Button { viewModel.clearCompleted() } label: { Label("Clear Completed", systemImage: "trash") }
        } label: {
            Image(systemName: "ellipsis.circle")
                .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
        }
    }
}

// MARK: - Download Row

private struct DownloadRow: View {
    let task: AstryxDownloadTask
    @ObservedObject var viewModel: DownloadsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                // Icon based on state
                ZStack {
                    Circle()
                        .fill(stateColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: task.state.icon)
                        .foregroundColor(stateColor)
                        .font(.system(size: 18, weight: .medium))
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(task.title ?? task.sourceURL.lastPathComponent)
                        .font(AstryxTypography.Body.medium)
                        .foregroundColor(AstryxColors.iceWhite)
                        .lineLimit(1)
                    
                    if let artist = task.artist {
                        Text(artist)
                            .font(AstryxTypography.Body.small)
                            .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                            .lineLimit(1)
                    } else {
                        Text(task.sourceURL.host ?? task.sourceURL.absoluteString)
                            .font(AstryxTypography.Body.small)
                            .foregroundColor(AstryxColors.Semantic.foregroundTertiary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(task.state.displayName)
                        .font(AstryxTypography.Body.caption)
                        .foregroundColor(stateColor)
                    Text(task.formattedProgress)
                        .font(AstryxTypography.Mono.small)
                        .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
                }
            }
            
            // Progress bar
            if task.state.isActive || task.state == .queued || task.state == .paused {
                VStack(alignment: .leading, spacing: 4) {
                    ProgressView(value: task.progress)
                        .tint(stateColor)
                    
                    HStack {
                        Text(task.formattedBytes)
                            .font(AstryxTypography.Body.caption)
                            .foregroundColor(AstryxColors.Semantic.foregroundTertiary)
                        Spacer()
                        if task.retryCount > 0 {
                            Text("Retry \(task.retryCount)/\(task.maxRetries)")
                                .font(AstryxTypography.Body.caption)
                                .foregroundColor(AstryxColors.sunset)
                        }
                        if let error = task.error {
                            Text(error.localizedDescription)
                                .font(AstryxTypography.Body.caption)
                                .foregroundColor(AstryxColors.Semantic.error)
                                .lineLimit(1)
                        }
                    }
                }
            }
            
            // Actions
            HStack(spacing: 12) {
                if task.state.canPause {
                    Button { viewModel.pause(taskID: task.id) } label: {
                        Label("Pause", systemImage: "pause.fill")
                            .font(AstryxTypography.Body.small)
                    }
                    .buttonStyle(.bordered)
                    .tint(AstryxColors.Semantic.foregroundSecondary)
                }
                
                if task.state.canResume {
                    Button { viewModel.resume(taskID: task.id) } label: {
                        Label("Resume", systemImage: "play.fill")
                            .font(AstryxTypography.Body.small)
                    }
                    .buttonStyle(.bordered)
                    .tint(AstryxColors.auroraBlue)
                }
                
                if task.state.canRetry {
                    Button { viewModel.retry(taskID: task.id) } label: {
                        Label("Retry", systemImage: "arrow.clockwise")
                            .font(AstryxTypography.Body.small)
                    }
                    .buttonStyle(.bordered)
                    .tint(AstryxColors.sunset)
                }
                
                if task.state.canCancel {
                    Button(role: .destructive) { viewModel.cancel(taskID: task.id) } label: {
                        Label("Cancel", systemImage: "xmark")
                            .font(AstryxTypography.Body.small)
                    }
                    .buttonStyle(.bordered)
                    .tint(AstryxColors.Semantic.error)
                }
                
                if task.state.isTerminal {
                    Button(role: .destructive) { viewModel.remove(taskID: task.id) } label: {
                        Label("Remove", systemImage: "trash")
                            .font(AstryxTypography.Body.small)
                    }
                    .buttonStyle(.bordered)
                    .tint(AstryxColors.Semantic.foregroundTertiary)
                }
                
                Spacer()
                
                // Priority indicator
                if task.priority != .normal {
                    Text(task.priority.displayName)
                        .font(AstryxTypography.Body.caption)
                        .foregroundColor(AstryxColors.Semantic.foregroundTertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AstryxColors.Semantic.surface)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private var stateColor: Color {
        switch task.state {
        case .queued: return AstryxColors.Semantic.foregroundSecondary
        case .downloading: return AstryxColors.auroraBlue
        case .paused: return AstryxColors.Semantic.foregroundTertiary
        case .retry: return AstryxColors.sunset
        case .completed: return AstryxColors.emerald
        case .failed: return AstryxColors.Semantic.error
        case .cancelled: return AstryxColors.Semantic.foregroundTertiary
        }
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    var color: Color = AstryxColors.auroraBlue
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(color)
                Text(title)
                    .font(AstryxTypography.Body.caption)
                    .foregroundColor(AstryxColors.Semantic.foregroundSecondary)
            }
            Text(value)
                .font(AstryxTypography.Heading.h4)
                .foregroundColor(AstryxColors.iceWhite)
                .lineLimit(1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(AstryxColors.Semantic.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
