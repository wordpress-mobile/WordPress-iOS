import Foundation

enum DateRangeGranularity: Comparable, CaseIterable, Identifiable {
    case hour
    case day
    case week
    case month
    case year

    var id: Self { self }
}

extension DateInterval {
    /// Automatically determine the appropriate period for chart display based
    /// on date range. This aims to show between 7 and 30 data points for optimal
    /// visualization on both bar charts and line charts where you can use drag
    /// gesture to see information about individual periods.
    var preferredGranularity: DateRangeGranularity {
        // Calculate total days for more accurate granularity selection
        let totalDays = Int(ceil(duration / 86400)) // 86400 seconds in a day

        // For ranges <= 1 day: show hourly data (up to 24 points)
        if totalDays <= 1 {
            return .hour
        }
        // For ranges 2-31 days: show daily data (2-31 points)
        else if totalDays <= 31 {
            return .day
        }
        else if totalDays <= 90 {
            return .week
        }
        // For ranges under about 2 years, show months
        else if totalDays <= 365 * 2 {
            return .month
        }
        // For ranges > 2 years: show yearly data
        else {
            return .year
        }
    }
}

extension DateRangeGranularity {
    var localizedTitle: String {
        switch self {
        case .hour: Strings.Granularity.hour
        case .day: Strings.Granularity.day
        case .week: Strings.Granularity.week
        case .month: Strings.Granularity.month
        case .year: Strings.Granularity.year
        }
    }

    /// Components needed to aggregate data at this granularity
    var calendarComponents: Set<Calendar.Component> {
        switch self {
        case .hour: [.year, .month, .day, .hour]
        case .day: [.year, .month, .day]
        case .week: [.year, .month, .day]
        case .month: [.year, .month]
        case .year: [.year]
        }
    }

    /// Component to increment when generating date sequences
    var component: Calendar.Component {
        switch self {
        case .hour: .hour
        case .day: .day
        case .week: .weekOfYear
        case .month: .month
        case .year: .year
        }
    }

    /// Preferred quantity of data points to fetch for this granularity.
    /// Used by legacy APIs that accept a date and quantity instead of date periods.
    var preferredQuantity: Int {
        switch self {
        case .hour: 24
        case .day: 14
        case .week: 12
        case .month: 12
        case .year: 6
        }
    }
}
