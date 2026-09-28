// QELORYX — Tests
// Polish_Tests.swift
// 0.9.0-beta Polish — Performance monitor, launch tracking, budgets, haptics, animations

import XCTest
@testable import QeloryxCore

final class PolishTests: XCTestCase {
    
    var monitor: AstryxPerformanceMonitor!
    
    override func setUp() {
        super.setUp()
        monitor = AstryxPerformanceMonitor.shared
        monitor.clear()
    }
    
    func testPerformanceMonitorRecording() {
        let metric = PerformanceMetric(name: "Test", duration: 40, target: 50)
        monitor.record(metric)
        
        let all = monitor.allMetrics()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.name, "Test")
        XCTAssertTrue(all.first?.passed == true)
        
        let failing = PerformanceMetric(name: "Failing", duration: 100, target: 50)
        monitor.record(failing)
        
        XCTAssertEqual(monitor.allMetrics().count, 2)
        XCTAssertFalse(monitor.allMetrics().last?.passed == true)
    }
    
    func testMeasure() {
        let result = monitor.measure(name: "Search", target: PerformanceBudget.search) {
            // Simulate search
            var sum = 0
            for i in 0..<1000 {
                sum += i
            }
            return sum
        }
        
        XCTAssertEqual(result, 499500)
        
        let metrics = monitor.metrics(for: "Search")
        XCTAssertEqual(metrics.count, 1)
        XCTAssertLessThan(metrics.first?.duration ?? 1000, 50) // Should be <50ms
    }
    
    func testLaunchTracking() {
        monitor.startLaunchTracking(isCold: true)
        // Simulate some work
        Thread.sleep(forTimeInterval: 0.05) // 50ms
        let metric = monitor.endLaunchTracking()
        
        XCTAssertNotNil(metric)
        XCTAssertEqual(metric?.name, "Cold Launch")
        XCTAssertLessThan(metric?.duration ?? 2000, PerformanceBudget.coldLaunch)
        
        // Next should be warm
        monitor.startLaunchTracking(isCold: false)
        Thread.sleep(forTimeInterval: 0.02) // 20ms
        let warmMetric = monitor.endLaunchTracking()
        
        XCTAssertNotNil(warmMetric)
        XCTAssertEqual(warmMetric?.name, "Warm Launch")
        XCTAssertLessThan(warmMetric?.duration ?? 1000, PerformanceBudget.warmLaunch)
    }
    
    func testBudgets() {
        // Record some metrics
        monitor.record(PerformanceMetric(name: "Cold Launch", duration: 1200, target: PerformanceBudget.coldLaunch))
        monitor.record(PerformanceMetric(name: "Search", duration: 30, target: PerformanceBudget.search))
        monitor.record(PerformanceMetric(name: "Library Open", duration: 150, target: PerformanceBudget.libraryOpen))
        
        let budgets = monitor.checkBudgets()
        
        XCTAssertFalse(budgets.isEmpty)
        
        let coldLaunch = budgets.first { $0.name == "Cold Launch" }
        XCTAssertNotNil(coldLaunch)
        XCTAssertTrue(coldLaunch?.passed == true)
        XCTAssertEqual(coldLaunch?.target, PerformanceBudget.coldLaunch)
        
        let search = budgets.first { $0.name == "Search" }
        XCTAssertTrue(search?.passed == true)
    }
    
    func testPassRate() {
        monitor.record(PerformanceMetric(name: "Test1", duration: 40, target: 50)) // pass
        monitor.record(PerformanceMetric(name: "Test2", duration: 60, target: 50)) // fail
        monitor.record(PerformanceMetric(name: "Test3", duration: 30, target: 50)) // pass
        
        let rate = monitor.passRate()
        XCTAssertEqual(rate, 2.0/3.0, accuracy: 0.01)
    }
    
    func testHaptics() {
        // Core haptics fallback should not crash, even without Platform/UIKit
        let engine = FallbackHapticEngine()
        engine.trigger(.light)
        engine.trigger(.medium)
        engine.trigger(.heavy)
        engine.trigger(.selection)
        engine.trigger(.success)
        engine.trigger(.warning)
        engine.trigger(.error)
        engine.triggerPlay()
        engine.triggerPause()
        engine.triggerFavorite()
        
        // If we reach here without crash, test passes
        XCTAssertTrue(true)
    }
    
    func testPerformanceMetricFormatting() {
        let msMetric = PerformanceMetric(name: "Search", duration: 45, target: 50)
        XCTAssertTrue(msMetric.formattedDuration.contains("ms"))
        
        let sMetric = PerformanceMetric(name: "Cold Launch", duration: 1200, target: 1500)
        XCTAssertTrue(sMetric.formattedDuration.contains("s") || sMetric.formattedDuration.contains("ms"))
        
        XCTAssertTrue(msMetric.passed)
        
        let failing = PerformanceMetric(name: "Slow", duration: 100, target: 50)
        XCTAssertFalse(failing.passed)
    }
}
