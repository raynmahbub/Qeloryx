import Foundation

public struct Duration: Sendable, Equatable, Comparable {
    public let seconds: TimeInterval
    public init(seconds: TimeInterval) { self.seconds = seconds }
    public static func < (lhs: Duration, rhs: Duration) -> Bool { lhs.seconds < rhs.seconds }
    public var formatted: String {
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%d:%02d", m, s)
    }
}

public struct PlayCount: Sendable, Equatable {
    public let count: Int
    public init(count: Int) { self.count = count }
}
