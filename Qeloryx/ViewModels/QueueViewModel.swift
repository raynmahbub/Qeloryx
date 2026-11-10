// QELORYX — ViewModels
// QueueViewModel.swift
// Backs `Views/Queue/QueueView`. Wraps the queue controller (the source of
// truth) and resolves track metadata for display; never owns playback state.

import Foundation
import Combine

@MainActor
public final class QueueViewModel: ObservableObject {

    @Published public private(set) var items: [AstryxQueueItem] = []
    @Published public private(set) var currentIndex: Int?
    @Published public private(set) var tracks: [String: AstryxTrack] = [:]
    @Published public private(set) var isLoading = false

    private let queueController: any QueueControllerProtocol
    private let libraryEngine: any LibraryEngineProtocol
    /// Cap on per-load metadata lookups; queues can hold thousands of items.
    private static let maxTitleLookups = 100

    public init(queueController: any QueueControllerProtocol, libraryEngine: any LibraryEngineProtocol) {
        self.queueController = queueController
        self.libraryEngine = libraryEngine
    }

    public var isEmpty: Bool { items.isEmpty }

    public func isCurrent(_ item: AstryxQueueItem) -> Bool {
        guard let currentIndex, currentIndex < items.count else { return false }
        return items[currentIndex].id == item.id
    }

    public func title(for item: AstryxQueueItem) -> String {
        tracks[item.trackID]?.title ?? "Track \(item.order + 1)"
    }

    public func artist(for item: AstryxQueueItem) -> String {
        tracks[item.trackID]?.artist ?? "Unknown Artist"
    }

    public func artworkData(for item: AstryxQueueItem) -> Data? {
        tracks[item.trackID]?.artworkData
    }

    public func load() async {
        isLoading = true
        defer { isLoading = false }

        let queue = queueController.currentQueue()
        items = queue.items
        currentIndex = queue.currentIndex

        var resolved: [String: AstryxTrack] = [:]
        for item in queue.items.prefix(Self.maxTitleLookups) {
            if let track = try? await libraryEngine.fetchTrack(id: item.trackID) {
                resolved[item.trackID] = track
            }
        }
        tracks = resolved
    }

    public func remove(at offsets: IndexSet) async {
        for index in offsets.sorted(by: >) where index < items.count {
            await queueController.removeFromQueue(itemID: items[index].id)
        }
        await load()
    }

    /// SwiftUI `.onMove` passes a single-source move. `destination` is the
    /// insertion index in the *post-removal* array.
    public func move(from source: IndexSet, to destination: Int) async {
        guard let from = source.first else { return }
        let to = destination > from ? destination - 1 : destination
        await queueController.moveItem(from: from, to: to)
        await load()
    }

    public func clear() async {
        await queueController.clear()
        await load()
    }

    public func jump(to item: AstryxQueueItem) async {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        await queueController.setCurrentIndex(index)
        await load()
    }
}
