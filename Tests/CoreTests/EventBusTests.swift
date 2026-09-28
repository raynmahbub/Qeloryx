// QELORYX — Tests
// EventBusTests.swift

import XCTest
@testable import QeloryxCore

final class EventBusTests: XCTestCase {
    
    var eventBus: AstryxEventBus!
    
    override func setUp() {
        super.setUp()
        eventBus = AstryxEventBus()
    }
    
    override func tearDown() {
        eventBus.removeAllObservers()
        super.tearDown()
    }
    
    func testPublishAndSubscribe() {
        let expectation = self.expectation(description: "Event received")
        var receivedEvent: QeloryxEvent?
        
        let _ = eventBus.subscribe { event in
            receivedEvent = event
            expectation.fulfill()
        }
        
        eventBus.publish(.trackStarted(trackID: "123", queueID: "queue-1"))
        
        waitForExpectations(timeout: 1.0)
        
        XCTAssertNotNil(receivedEvent)
        if case .trackStarted(let trackID, let queueID) = receivedEvent {
            XCTAssertEqual(trackID, "123")
            XCTAssertEqual(queueID, "queue-1")
        } else {
            XCTFail("Wrong event type")
        }
    }
    
    func testFilteredSubscription() {
        let expectation = self.expectation(description: "Filtered event")
        expectation.expectedFulfillmentCount = 1
        
        let _ = eventBus.subscribe(to: QeloryxEvent.trackStarted(trackID: "", queueID: "").name) { event in
            expectation.fulfill()
        }
        
        eventBus.publish(.trackStarted(trackID: "1", queueID: "q1"))
        eventBus.publish(.trackPaused(trackID: "1", position: 0)) // Should not trigger
        
        waitForExpectations(timeout: 1.0)
    }
    
    func testUnsubscribe() {
        var count = 0
        
        let subscription = eventBus.subscribe { _ in
            count += 1
        }
        
        eventBus.publish(.libraryDidChange(changeType: .incremental))
        
        // Wait a bit
        let exp1 = expectation(description: "first")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            exp1.fulfill()
        }
        waitForExpectations(timeout: 0.5)
        
        XCTAssertEqual(count, 1)
        
        subscription.cancel()
        
        eventBus.publish(.libraryDidChange(changeType: .incremental))
        
        let exp2 = expectation(description: "second")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            exp2.fulfill()
        }
        waitForExpectations(timeout: 0.5)
        
        XCTAssertEqual(count, 1, "Should not receive after cancel")
    }
    
    func testMultipleSubscribers() {
        let exp = expectation(description: "multiple")
        exp.expectedFulfillmentCount = 3
        
        for _ in 0..<3 {
            let _ = eventBus.subscribe { _ in
                exp.fulfill()
            }
        }
        
        eventBus.publish(.appDidEnterBackground)
        
        waitForExpectations(timeout: 1.0)
    }
}
