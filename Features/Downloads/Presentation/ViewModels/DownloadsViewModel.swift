// QELORYX — Features — Downloads
// DownloadsViewModel.swift
// QEL-041 Downloads — Production with state machine, resume, retry, priority

import Foundation
import Combine

#if canImport(SwiftUI)
import SwiftUI
#endif

public enum DownloadsFilter: String, CaseIterable, Sendable {
    case all = "All"
    case downloading = "Downloading"
    case queued = "Queued"
    case paused = "Paused"
    case completed = "Completed"
    case failed = "Failed"
    
    public var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .downloading: return "arrow.down.circle.fill"
        case .queued: return "clock"
        case .paused: return "pause.circle"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.circle"
        }
    }
    
    public func matches(_ state: AstryxDownloadState) -> Bool {
        switch self {
        case .all: return true
        case .downloading: return state == .downloading || state == .retry
        case .queued: return state == .queued
        case .paused: return state == .paused
        case .completed: return state == .completed
        case .failed: return state == .failed || state == .cancelled
        }
    }
}

@MainActor
public final class DownloadsViewModel: ObservableObject {
    
    // MARK: - Published
    
    @Published public var tasks: [AstryxDownloadTask] = []
    @Published public var filteredTasks: [AstryxDownloadTask] = []
    @Published public var stats: DownloadStats = DownloadStats()
    @Published public var selectedFilter: DownloadsFilter = .all
    @Published public var isLoading: Bool = false
    @Published public var searchText: String = ""
    @Published public var errorMessage: String?
    
    // MARK: - Dependencies
    
    private let downloadEngine: any DownloadEngineProtocol
    private let eventBus: any EventBusProtocol
    
    private var cancellables = Set<AnyCancellable>()
    private var eventSubscriptions: [Any] = []
    
    public init(
        downloadEngine: any DownloadEngineProtocol = AstryxDownloadEngine(),
        eventBus: any EventBusProtocol = AstryxEventBus.shared
    ) {
        self.downloadEngine = downloadEngine
        self.eventBus = eventBus
        
        observeEvents()
        observeSearch()
    }
    
    private func observeEvents() {
        let sub1 = eventBus.subscribe(to: QeloryxEvent.downloadStateChanged(taskID: "", state: DownloadStateSnapshot(state: "", progress: 0)).name) { [weak self] _ in
            Task { @MainActor in
                await self?.loadTasks()
            }
        }
        let sub2 = eventBus.subscribe(to: QeloryxEvent.downloadProgress(taskID: "", progress: 0).name) { [weak self] event in
            Task { @MainActor in
                if case .downloadProgress(let taskID, let progress) = event {
                    self?.updateProgress(taskID: taskID, progress: progress)
                }
            }
        }
        let sub3 = eventBus.subscribe(to: QeloryxEvent.downloadCompleted(taskID: "", trackID: "").name) { [weak self] _ in
            Task { @MainActor in
                await self?.loadTasks()
            }
        }
        
        // Store subscriptions to keep alive (EventBus returns cancellable)
        eventSubscriptions = [sub1, sub2, sub3]
    }
    
    private func observeSearch() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.applyFilter()
            }
            .store(in: &cancellables)
        
        $selectedFilter
            .sink { [weak self] _ in
                self?.applyFilter()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    
    public func loadTasks() async {
        isLoading = true
        let all = await downloadEngine.allTasks()
        tasks = all
        stats = await downloadEngine.stats()
        applyFilter()
        isLoading = false
    }
    
    public func refresh() async {
        await loadTasks()
    }
    
    private func applyFilter() {
        var result = tasks
        
        // Filter by state
        if selectedFilter != .all {
            result = result.filter { selectedFilter.matches($0.state) }
        }
        
        // Filter by search
        if !searchText.isEmpty {
            let search = searchText.lowercased()
            result = result.filter {
                ($0.title?.lowercased().contains(search) ?? false) ||
                ($0.artist?.lowercased().contains(search) ?? false) ||
                $0.sourceURL.absoluteString.lowercased().contains(search)
            }
        }
        
        // Sort: downloading first, then queued, paused, failed, completed last
        result.sort { lhs, rhs in
            let order: [AstryxDownloadState] = [.downloading, .retry, .queued, .paused, .failed, .cancelled, .completed]
            let lhsIdx = order.firstIndex(of: lhs.state) ?? 999
            let rhsIdx = order.firstIndex(of: rhs.state) ?? 999
            if lhsIdx != rhsIdx {
                return lhsIdx < rhsIdx
            }
            return lhs.createdAt > rhs.createdAt
        }
        
        filteredTasks = result
    }
    
    private func updateProgress(taskID: String, progress: Double) {
        if let idx = tasks.firstIndex(where: { $0.id == taskID }) {
            tasks[idx].progress = progress
        }
        if let idx = filteredTasks.firstIndex(where: { $0.id == taskID }) {
            filteredTasks[idx].progress = progress
        }
    }
    
    public func pause(taskID: String) {
        Task {
            await downloadEngine.pause(taskID: taskID)
            await loadTasks()
        }
    }
    
    public func resume(taskID: String) {
        Task {
            await downloadEngine.resume(taskID: taskID)
            await loadTasks()
        }
    }
    
    public func cancel(taskID: String) {
        Task {
            await downloadEngine.cancel(taskID: taskID)
            await loadTasks()
        }
    }
    
    public func retry(taskID: String) {
        Task {
            await downloadEngine.retry(taskID: taskID)
            await loadTasks()
        }
    }
    
    public func remove(taskID: String) {
        Task {
            await downloadEngine.remove(taskID: taskID)
            await loadTasks()
        }
    }
    
    public func pauseAll() {
        Task {
            await downloadEngine.pauseAll()
            await loadTasks()
        }
    }
    
    public func resumeAll() {
        Task {
            await downloadEngine.resumeAll()
            await loadTasks()
        }
    }
    
    public func cancelAll() {
        Task {
            await downloadEngine.cancelAll()
            await loadTasks()
        }
    }
    
    public func clearCompleted() {
        Task {
            await downloadEngine.clearCompleted()
            await loadTasks()
        }
    }
    
    public func downloadTrack(track: AstryxTrack, sourceURL: URL, priority: DownloadPriority = .normal) {
        Task {
            _ = await downloadEngine.enqueue(track: track, sourceURL: sourceURL, priority: priority)
            await loadTasks()
        }
    }
}
