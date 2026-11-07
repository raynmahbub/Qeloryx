// QELORYX — CoreTests
// DownloadTaskStoreTests.swift
//
// BUG-07/BUG-09. The download table lived only in memory, so a relaunch lost
// every queued and in-flight transfer. These tests pin the durability and
// corruption contracts of both stores.

import XCTest
#if canImport(QeloryxCore)
@testable import QeloryxCore
#else
// The XcodeGen app target is a single module named `Qeloryx` (App + Core +
// Features + Platform + DesignSystem compiled together), so `QeloryxCore` does
// not exist there. `swift test` uses the multi-module SPM targets above.
@testable import Qeloryx
#endif

final class DownloadTaskStoreTests: XCTestCase {

    private var directory: URL!

    override func setUp() {
        super.setUp()
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("QeloryxTests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: directory)
        super.tearDown()
    }

    private func task(
        id: String = "task-1",
        state: AstryxDownloadState = .queued
    ) -> AstryxDownloadTask {
        AstryxDownloadTask(
            id: id,
            trackID: "track-\\(id)",
            sourceURL: URL(string: "https://example.com/\\(id).m4a")!,
            destinationURL: directory.appendingPathComponent("\\(id).m4a"),
            state: state,
            progress: 0.5,
            bytesDownloaded: 1_024,
            totalBytes: 2_048,
            priority: .high,
            retryCount: 1,
            error: .networkError("timeout"),
            resumeData: Data([0x01, 0x02]),
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            startedAt: Date(timeIntervalSince1970: 1_700_000_010),
            title: "Song",
            artist: "Artist"
        )
    }

    // MARK: - In-memory store

    func testInMemoryStoreRoundTrips() {
        let store = InMemoryDownloadTaskStore()
        XCTAssertTrue(store.load().isEmpty)

        let tasks = [task(id: "a"), task(id: "b")]
        store.save(tasks)

        XCTAssertEqual(store.load().map(\.id), ["a", "b"])
    }

    func testInMemoryStoreReplacesRatherThanAppends() {
        let store = InMemoryDownloadTaskStore()
        store.save([task(id: "a"), task(id: "b")])
        store.save([task(id: "c")])
        XCTAssertEqual(store.load().map(\.id), ["c"])
    }

    func testInMemoryStoreIsSafeUnderConcurrentAccess() {
        let store = InMemoryDownloadTaskStore()
        let group = DispatchGroup()
        for index in 0..<50 {
            DispatchQueue.global().async(group: group) {
                store.save([self.task(id: "t\(index)")])
            }
        }
        XCTAssertEqual(group.wait(timeout: .now() + 5), .success)
        XCTAssertEqual(store.load().count, 1, "concurrent saves must not corrupt the table")
    }

    // MARK: - File store

    func testFileStorePersistsAcrossInstances() throws {
        let url = directory.appendingPathComponent("downloads.json")
        let first = FileDownloadTaskStore(fileURL: url)
        first.save([task(id: "a", state: .downloading), task(id: "b", state: .completed)])

        // A fresh instance models the next launch.
        let second = FileDownloadTaskStore(fileURL: url)
        let restored = second.load()

        XCTAssertEqual(restored.map(\.id), ["a", "b"])
        XCTAssertEqual(restored.first?.state, .downloading)
        XCTAssertEqual(restored.first?.trackID, "track-a")
        XCTAssertEqual(restored.first?.resumeData, Data([0x01, 0x02]))
        XCTAssertEqual(restored.first?.error, .networkError("timeout"))
    }

    func testFileStoreCreatesMissingDirectories() {
        let nested = directory
            .appendingPathComponent("deep", isDirectory: true)
            .appendingPathComponent("downloads.json")
        let store = FileDownloadTaskStore(fileURL: nested)
        store.save([task()])
        XCTAssertTrue(FileManager.default.fileExists(atPath: nested.path))
        XCTAssertEqual(store.load().count, 1)
    }

    func testFileStoreReturnsEmptyWhenFileIsMissing() {
        let store = FileDownloadTaskStore(fileURL: directory.appendingPathComponent("nope.json"))
        XCTAssertTrue(store.load().isEmpty, "a first run must not throw or crash")
    }

    func testFileStoreReturnsEmptyOnCorruptJSON() throws {
        let url = directory.appendingPathComponent("downloads.json")
        try Data("{ this is not json".utf8).write(to: url)

        let store = FileDownloadTaskStore(fileURL: url)
        XCTAssertTrue(store.load().isEmpty, "corrupt state must degrade to an empty table")
    }

    func testFileStoreSaveIsAtomic() throws {
        let url = directory.appendingPathComponent("downloads.json")
        let store = FileDownloadTaskStore(fileURL: url)
        store.save([task(id: "a")])

        let original = try Data(contentsOf: url)
        store.save([task(id: "b")])

        // The file is always complete, decodable JSON — never a partial write.
        let decoded = try JSONDecoder.iso8601.decode([AstryxDownloadTask].self, from: Data(contentsOf: url))
        XCTAssertEqual(decoded.map(\.id), ["b"])
        XCTAssertNotEqual(original, Data(contentsOf: url))
    }
}

private extension JSONDecoder {
    static var iso8601: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
