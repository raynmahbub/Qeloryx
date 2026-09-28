// QELORYX — Core — Performance
// PerformanceMonitor.swift
// QEL-051 Polish — Production performance monitoring, cold/warm launch tracking, budgets

import Foundation

public struct PerformanceMetric: Sendable, Equatable, Identifiable {
    public let id: String
    public let name: String
    public let duration: TimeInterval // ms
    public let target: TimeInterval // ms
    public let timestamp: Date
    public let passed: Bool
    
    public init(id: String = UUID().uuidString, name: String, duration: TimeInterval, target: TimeInterval, timestamp: Date = Date()) {
        self.id = id
        self.name = name
        self.duration = duration
        self.target = target
        self.timestamp = timestamp
        self.passed = duration <= target
    }
    
    public var formattedDuration: String {
        if duration < 1 {
            return String(format: "%.0fms", duration * 1000)
        } else if duration < 1000 {
            return String(format: "%.0fms", duration)
        } else {
            return String(format: "%.2fs", duration / 1000)
        }
    }
    
    public var formattedTarget: String {
        if target < 1000 {
            return String(format: "%.0fms", target)
        } else {
            return String(format: "%.1fs", target / 1000)
        }
    }
}

public enum PerformanceBudget: Sendable {
    public static let coldLaunch: TimeInterval = 1500 // ms
    public static let warmLaunch: TimeInterval = 600
    public static let search: TimeInterval = 50
    public static let libraryOpen: TimeInterval = 200
    public static let queue: TimeInterval = 10 // Instant ~10ms
    public static let seek: TimeInterval = 50
    public static let playPause: TimeInterval = 10
    public static let lyricsSync: TimeInterval = 50
    public static let karaokeSync: TimeInterval = 100
    public static let downloadEnqueue: TimeInterval = 50
    public static let downloadProgress: TimeInterval = 100
    public static let tasteDNAGen: TimeInterval = 200
    public static let recommendations: TimeInterval = 100
}

public final class AstryxPerformanceMonitor: @unchecked Sendable {
    
    public static let shared = AstryxPerformanceMonitor()
    
    private var metrics: [PerformanceMetric] = []
    private var launchStartTime: Date?
    private var isColdLaunch: Bool = true
    private let lock = NSLock()
    
    private init() {}
    
    // MARK: - Launch Tracking
    
    public func startLaunchTracking(isCold: Bool = true) {
        lock.lock()
        launchStartTime = Date()
        isColdLaunch = isCold
        lock.unlock()
        
        #if DEBUG
        debugPrint("[Performance] Launch tracking started — cold=\(isCold)")
        #endif
    }
    
    public func endLaunchTracking() -> PerformanceMetric? {
        lock.lock()
        guard let start = launchStartTime else {
            lock.unlock()
            return nil
        }
        let duration = Date().timeIntervalSince(start) * 1000 // ms
        launchStartTime = nil
        let isCold = isColdLaunch
        lock.unlock()
        
        let target = isCold ? PerformanceBudget.coldLaunch : PerformanceBudget.warmLaunch
        let name = isCold ? "Cold Launch" : "Warm Launch"
        
        let metric = PerformanceMetric(name: name, duration: duration, target: target)
        record(metric)
        
        #if DEBUG
        debugPrint("[Performance] \(name): \(metric.formattedDuration) / \(metric.formattedTarget) — \(metric.passed ? "✅" : "❌")")
        #endif
        
        // Mark next launch as warm
        lock.lock()
        isColdLaunch = false
        lock.unlock()
        
        return metric
    }
    
    // MARK: - Generic Measurement
    
    public func measure<T>(name: String, target: TimeInterval, block: () throws -> T) rethrows -> T {
        let start = Date()
        let result = try block()
        let duration = Date().timeIntervalSince(start) * 1000
        
        let metric = PerformanceMetric(name: name, duration: duration, target: target)
        record(metric)
        
        #if DEBUG
        if !metric.passed {
            debugPrint("[Performance] ⚠️ \(name): \(metric.formattedDuration) exceeded \(metric.formattedTarget)")
        }
        #endif
        
        return result
    }
    
    public func measureAsync<T>(name: String, target: TimeInterval, block: () async throws -> T) async rethrows -> T {
        let start = Date()
        let result = try await block()
        let duration = Date().timeIntervalSince(start) * 1000
        
        let metric = PerformanceMetric(name: name, duration: duration, target: target)
        record(metric)
        
        #if DEBUG
        if !metric.passed {
            debugPrint("[Performance] ⚠️ \(name): \(metric.formattedDuration) exceeded \(metric.formattedTarget)")
        }
        #endif
        
        return result
    }
    
    // MARK: - Recording
    
    public func record(_ metric: PerformanceMetric) {
        lock.lock()
        metrics.append(metric)
        // Keep only last 100 metrics
        if metrics.count > 100 {
            metrics.removeFirst(metrics.count - 100)
        }
        lock.unlock()
    }
    
    public func allMetrics() -> [PerformanceMetric] {
        lock.lock()
        defer { lock.unlock() }
        return metrics
    }
    
    public func metrics(for name: String) -> [PerformanceMetric] {
        lock.lock()
        defer { lock.unlock() }
        return metrics.filter { $0.name == name }
    }
    
    public func averageDuration(for name: String) -> TimeInterval? {
        let filtered = metrics(for: name)
        guard !filtered.isEmpty else { return nil }
        return filtered.reduce(0) { $0 + $1.duration } / Double(filtered.count)
    }
    
    public func passRate() -> Double {
        lock.lock()
        defer { lock.unlock() }
        guard !metrics.isEmpty else { return 1.0 }
        let passed = metrics.filter { $0.passed }.count
        return Double(passed) / Double(metrics.count)
    }
    
    public func clear() {
        lock.lock()
        metrics.removeAll()
        lock.unlock()
    }
    
    // MARK: - Budget Check
    
    public func checkBudgets() -> [(name: String, passed: Bool, avgDuration: TimeInterval, target: TimeInterval)] {
        let budgets: [(String, TimeInterval)] = [
            ("Cold Launch", PerformanceBudget.coldLaunch),
            ("Warm Launch", PerformanceBudget.warmLaunch),
            ("Search", PerformanceBudget.search),
            ("Library Open", PerformanceBudget.libraryOpen),
            ("Queue", PerformanceBudget.queue),
            ("Seek", PerformanceBudget.seek),
            ("Play/Pause", PerformanceBudget.playPause),
            ("Lyrics Sync", PerformanceBudget.lyricsSync),
            ("Karaoke Sync", PerformanceBudget.karaokeSync),
            ("Download Enqueue", PerformanceBudget.downloadEnqueue),
            ("Taste DNA Gen", PerformanceBudget.tasteDNAGen),
            ("Recommendations", PerformanceBudget.recommendations)
        ]
        
        return budgets.map { (name, target) in
            let avg = averageDuration(for: name) ?? 0
            let passed = avg <= target || avg == 0 // 0 means no data yet, considered passing
            return (name, passed, avg, target)
        }
    }
}
