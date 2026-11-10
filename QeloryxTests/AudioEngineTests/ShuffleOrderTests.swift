// QELORYX — CoreTests
// ShuffleOrderTests.swift
//
// BUG-04. Shuffle used to permute `items` once and then follow array order, so
// `next()` ignored shuffle entirely and `previous()` walked a stale ordering.
// The regression the register asked for: after N advances the visited set must
// equal the queue contents — no repeats, no omissions.

import XCTest
#if canImport(QeloryxCore)
@testable import QeloryxCore
#else
// The XcodeGen app target is a single module named `Qeloryx` (App + Core +
// Features + Platform + DesignSystem compiled together), so `QeloryxCore` does
// not exist there. `swift test` uses the multi-module SPM targets above.
@testable import Qeloryx
#endif

final class ShuffleOrderTests: XCTestCase {

    private func makeQueue(_ count: Int) async -> (AstryxQueueController, [String]) {
        let controller = AstryxQueueController(eventBus: AstryxEventBus())
        let ids = (0..<count).map { "t\($0)" }
        await controller.setQueue(trackIDs: ids, startIndex: 0, source: .manual)
        return (controller, ids)
    }

    func testShuffleVisitsEveryTrackExactlyOnce() async {
        let (controller, ids) = await makeQueue(12)
        await controller.setShuffle(true)

        var visited = Set<String>()
        if let first = controller.currentQueue().currentItem?.trackID {
            visited.insert(first)
        }

        for _ in 0..<(ids.count - 1) {
            guard let item = await controller.next() else { break }
            visited.insert(item.trackID)
        }

        XCTAssertEqual(visited, Set(ids),
                       "shuffle must reach every track before repeating")
    }

    func testShuffleDoesNotRepeatUntilTheBagIsExhausted() async {
        let (controller, _) = await makeQueue(8)
        await controller.setShuffle(true)

        var sequence: [String] = []
        if let first = controller.currentQueue().currentItem?.trackID {
            sequence.append(first)
        }
        for _ in 0..<7 {
            guard let item = await controller.next() else { break }
            sequence.append(item.trackID)
        }

        XCTAssertEqual(sequence.count, Set(sequence).count,
                       "no track may play twice while others are unheard")
    }

    func testShuffleKeepsTheCurrentTrackSelected() async {
        let (controller, _) = await makeQueue(6)
        await controller.setQueue(trackIDs: ["a", "b", "c", "d"], startIndex: 2, source: .manual)
        let before = controller.currentQueue().currentItem?.trackID

        await controller.setShuffle(true)

        XCTAssertEqual(controller.currentQueue().currentItem?.trackID, before,
                       "enabling shuffle must not change what is playing")
    }

    func testDisablingShuffleRestoresOriginalOrderAndSelection() async {
        let (controller, ids) = await makeQueue(10)
        await controller.setShuffle(true)
        _ = await controller.next()
        _ = await controller.next()
        let playing = controller.currentQueue().currentItem?.trackID

        await controller.setShuffle(false)
        let queue = controller.currentQueue()

        XCTAssertEqual(queue.items.map(\.trackID), ids, "original order is restored")
        XCTAssertEqual(queue.currentItem?.trackID, playing, "and the selection follows the track")
    }

    func testSingleTrackQueueUnderShuffleStopsWithoutRepeatAll() async {
        let controller = AstryxQueueController(eventBus: AstryxEventBus())
        await controller.setQueue(trackIDs: ["only"], startIndex: 0, source: .manual)
        await controller.setShuffle(true)

        let next = await controller.next()
        XCTAssertNil(next, "one track, no repeat ⇒ nothing to advance to")
    }

    func testRepeatAllRefillsTheBag() async {
        let (controller, ids) = await makeQueue(5)
        await controller.setShuffle(true)
        await controller.setRepeatMode(.all)

        var visited: [String] = []
        for _ in 0..<15 {
            guard let item = await controller.next() else { break }
            visited.append(item.trackID)
        }

        XCTAssertGreaterThanOrEqual(visited.count, 10,
                                    "repeat-all must keep the round going")
        XCTAssertTrue(Set(visited).isSubset(of: Set(ids)))
    }

    func testPreviousWalksShuffleHistory() async {
        let (controller, _) = await makeQueue(6)
        await controller.setShuffle(true)

        let start = controller.currentQueue().currentItem?.trackID
        let second = await controller.next()?.trackID
        XCTAssertNotEqual(start, second)

        let back = await controller.previous()?.trackID
        XCTAssertEqual(back, start, "previous() must undo the shuffle step")
    }
}
