import Foundation
@testable import JetpackStats

extension TimeZone {
    /// For simplicity, returns a timezone with a -3 hours offset from GMT.
    static let eastern = TimeZone(secondsFromGMT: -10_800)!
}

extension Calendar {
    /// Returns a mock Calendar with the given time zone. By default, uses
    /// ``TimeZone/est``.
    static func mock(timeZone: TimeZone = .eastern) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        calendar.locale = Locale(identifier: "en_US")
        return calendar
    }
}

extension Date {
    /// Creates a Date from an ISO 8601 string.
    /// Supports formats like "2025-01-15T14:30:00Z" or "2025-01-15T14:30:00-03:00"
    init(_ isoString: String) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        guard let date = formatter.date(from: isoString) else {
            fatalError("Invalid date string: \(isoString)")
        }
        self = date
    }
}
