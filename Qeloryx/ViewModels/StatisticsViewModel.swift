// QELORYX — ViewModels
// StatisticsViewModel.swift
// Extracted from the view file (Qeloryx/Views) — view models live here per the
// redesigned architecture.

import Foundation
import Combine

#if canImport(SwiftUI)
import SwiftUI
#endif

public final class StatisticsViewModel: ObservableObject {
    
    @Published public var todayLastYear: TimeCapsule?
    @Published public var monthlyStories: [MonthlyStory] = []
    @Published public var totalPlays: Int = 0
    @Published public var daysActive: Int = 0
    @Published public var topGenre: String = "—"
    @Published public var longestStreak: Int = 0
    /// Normalized 0…1 play intensity, `[row][column]`. Empty until history loads.
    @Published public var heatmapIntensities: [[Double]] = []
    
    private let libraryEngine: any LibraryEngineProtocol
    
    public init(libraryEngine: any LibraryEngineProtocol) {
        self.libraryEngine = libraryEngine
    }
    
    /// Every figure here is derived from the play history.
    ///
    /// This screen used to hard-code "342 plays", "128 days active", six
    /// invented monthly stories and a `Double.random` heatmap, so a brand-new
    /// library reported a year of listening that never happened (BUG-17).
    /// With no history it now reports nothing.
    public func load() async {
        let recent = (try? await libraryEngine.fetchHistory(limit: 5)) ?? []
        let fullHistory = (try? await libraryEngine.fetchHistory(limit: 5_000)) ?? []

        if !recent.isEmpty {
            todayLastYear = TimeCapsule(
                date: Date().addingTimeInterval(-365 * 24 * 3600),
                tracks: recent
            )
        } else {
            todayLastYear = nil
        }

        monthlyStories = Self.monthlyStories(from: fullHistory)

        let played = fullHistory.filter { $0.lastPlayed != nil }
        totalPlays = played.reduce(0) { $0 + $1.playCount }
        daysActive = Set(
            played.compactMap { $0.lastPlayed }.map { Calendar.current.startOfDay(for: $0) }
        ).count
        topGenre = Self.mostCommon(fullHistory.compactMap(\.genre)) ?? "—"
        longestStreak = Self.longestStreak(in: played.compactMap(\.lastPlayed))
        heatmapIntensities = Self.heatmap(from: played.compactMap(\.lastPlayed), columns: 20, rows: 7)
    }

    // MARK: Statistics

    static func monthlyStories(from tracks: [AstryxTrack]) -> [MonthlyStory] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        var byMonth: [Int: [AstryxTrack]] = [:]
        for track in tracks {
            guard let played = track.lastPlayed else { continue }
            byMonth[calendar.component(.month, from: played), default: []].append(track)
        }

        return byMonth.keys.sorted().compactMap { month in
            guard let monthTracks = byMonth[month], !monthTracks.isEmpty else { return nil }
            let reference = monthTracks.compactMap(\.lastPlayed).first ?? Date()
            return MonthlyStory(
                month: formatter.string(from: reference),
                playCount: monthTracks.reduce(0) { $0 + $1.playCount },
                topArtist: mostCommon(monthTracks.map(\.artist)) ?? "—"
            )
        }
    }

    static func mostCommon(_ values: [String]) -> String? {
        var counts: [String: Int] = [:]
        for value in values where !value.isEmpty {
            counts[value, default: 0] += 1
        }
        return counts.max { $0.value < $1.value }?.key
    }

    static func longestStreak(in dates: [Date]) -> Int {
        let days = Set(dates.map { Calendar.current.startOfDay(for: $0) }).sorted()
        guard !days.isEmpty else { return 0 }
        var longest = 1
        var current = 1
        for index in 1..<days.count {
            let gap = Calendar.current.dateComponents([.day], from: days[index - 1], to: days[index]).day
            if gap == 1 {
                current += 1
                longest = max(longest, current)
            } else {
                current = 1
            }
        }
        return longest
    }

    /// Buckets play dates into a `rows × columns` grid ending today. Empty
    /// buckets are 0, not random noise.
    static func heatmap(from dates: [Date], columns: Int, rows: Int) -> [[Double]] {
        let cells = columns * rows
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var buckets = Array(repeating: 0, count: cells)

        for date in dates {
            let day = calendar.startOfDay(for: date)
            let offset = calendar.dateComponents([.day], from: day, to: today).day ?? 0
            guard offset >= 0, offset < cells else { continue }
            buckets[cells - 1 - offset] += 1
        }

        let maximum = max(buckets.max() ?? 0, 1)
        let rowMajor = buckets.map { Double($0) / Double(maximum) }
        return stride(from: 0, to: cells, by: columns).map {
            Array(rowMajor[$0..<min($0 + columns, cells)])
        }
    }
    
    public func refresh() async {
        await load()
    }
}
