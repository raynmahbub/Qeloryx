// QELORYX — Services/Downloads
// DownloadTaskStore.swift
//
// BUG-09. The download queue lived only in memory, so "paused" was lost on
// relaunch and nothing could be reconciled against the background session.
// Task state is now written through a small, testable store.
//
// The default implementation is a JSON file in Application Support. Tests (and
// Linux builds) use `InMemoryDownloadTaskStore`, so the persistence contract is
// exercised without touching the filesystem.

import Foundation

public protocol DownloadTaskStoring: Sendable {
    func load() -> [AstryxDownloadTask]
    func save(_ tasks: [AstryxDownloadTask])
}

// MARK: - In-memory

public final class InMemoryDownloadTaskStore: DownloadTaskStoring, @unchecked Sendable {
    private var tasks: [AstryxDownloadTask] = []
    private let lock = NSLock()

    public init(tasks: [AstryxDownloadTask] = []) {
        self.tasks = tasks
    }

    public func load() -> [AstryxDownloadTask] {
        lock.lock()
        defer { lock.unlock() }
        return tasks
    }

    public func save(_ tasks: [AstryxDownloadTask]) {
        lock.lock()
        self.tasks = tasks
        lock.unlock()
    }
}

// MARK: - JSON file

/// Writes the task table atomically to disk. Downloads can be interrupted by
/// process death at any point, so the write is a replace, never a truncate.
public final class FileDownloadTaskStore: DownloadTaskStoring, @unchecked Sendable {

    private let fileURL: URL
    private let lock = NSLock()
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(fileURL: URL? = nil) {
        let resolved: URL
        if let fileURL {
            resolved = fileURL
        } else {
            let base = FileManager.default
                .urls(for: .applicationSupportDirectory, in: .userDomainMask)
                .first ?? URL(fileURLWithPath: NSTemporaryDirectory())
            resolved = base
                .appendingPathComponent("Qeloryx", isDirectory: true)
                .appendingPathComponent("downloads.json")
        }
        self.fileURL = resolved
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    public func load() -> [AstryxDownloadTask] {
        lock.lock()
        defer { lock.unlock() }
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? decoder.decode([AstryxDownloadTask].self, from: data)) ?? []
    }

    public func save(_ tasks: [AstryxDownloadTask]) {
        lock.lock()
        defer { lock.unlock() }
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try encoder.encode(tasks)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            #if DEBUG
            debugPrint("[DownloadTaskStore] save failed: \(error)")
            #endif
        }
    }
}
