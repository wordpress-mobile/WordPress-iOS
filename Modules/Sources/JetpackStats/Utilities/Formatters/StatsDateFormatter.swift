import Foundation

struct StatsDateFormatter {
    var locale: Locale
    var timeZone: TimeZone

    init(locale: Locale = .current, timeZone: TimeZone = .current) {
        self.locale = locale
        self.timeZone = timeZone
    }

    func formatDate(_ date: Date, granularity: DateRangeGranularity) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone

        switch granularity {
        case .hour:
            formatter.dateFormat = "h a" // 3 AM
        case .day:
            formatter.dateFormat = "MMM d"
        case .month:
            formatter.dateFormat = "MMM"
        case .year:
            formatter.dateFormat = "yyyy"
        }
        return formatter.string(from: date)
    }

    var formattedTimeOffset: String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = "ZZZZ"  // "GMT-05:00"
        return formatter.string(from: Date())
    }
}
