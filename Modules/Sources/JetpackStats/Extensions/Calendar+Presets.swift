import Foundation

/// Represents predefined date range options for stats filtering.
/// Each preset defines a specific time period relative to the current date.
enum DateIntervalPreset: String, CaseIterable, Identifiable {
    /// The current calendar day
    case today
    /// The current calendar week
    case thisWeek
    /// The current calendar month
    case thisMonth
    /// The current calendar quarter
    case thisQuarter
    /// The current calendar year
    case thisYear
    /// The previous 7 days, not including today
    case last7Days
    /// The previous 28 days, not including today
    case last28Days
    /// The previous 30 days, not including today
    case last30Days
    /// The previous 90 days, not including today
    case last90Days
    /// The last 6 months, including the current month
    case last6Months
    /// The last 12 months, including the current month
    case last12Months
    /// The last 3 complete years, including the current year
    case last3Years
    /// The last 10 complete years, including the current year
    case last10Years

    var id: DateIntervalPreset { self }

    var localizedString: String {
        switch self {
        case .today: Strings.Calendar.today
        case .thisWeek: Strings.Calendar.thisWeek
        case .thisMonth: Strings.Calendar.thisMonth
        case .thisQuarter: Strings.Calendar.thisQuarter
        case .thisYear: Strings.Calendar.thisYear
        case .last7Days: Strings.Calendar.last7Days
        case .last28Days: Strings.Calendar.last28Days
        case .last30Days: Strings.Calendar.last30Days
        case .last90Days: Strings.Calendar.last90Days
        case .last6Months: Strings.Calendar.last6Months
        case .last12Months: Strings.Calendar.last12Months
        case .last3Years: Strings.Calendar.last3Years
        case .last10Years: Strings.Calendar.last10Years
        }
    }

    var prefersDateIntervalFormatting: Bool {
        switch self {
        case .today, .last7Days, .last28Days, .last30Days, .last90Days, .last6Months, .last12Months, .thisWeek:
            return false
        case .thisMonth, .thisYear, .thisQuarter, .last3Years, .last10Years:
            return true
        }
    }

    /// Returns a calendar component for navigation behavior
    var component: Calendar.Component {
        switch self {
        case .today:
            return .day
        case .thisWeek:
            return .weekOfYear
        case .thisMonth, .last6Months, .last12Months:
            return .month
        case .thisQuarter:
            return .quarter
        case .thisYear, .last3Years, .last10Years:
            return .year
        case .last7Days, .last28Days, .last30Days, .last90Days:
            return .day
        }
    }
}

extension Calendar {
    /// Creates a DateInterval for the given preset relative to the specified date.
    /// - Parameters:
    ///   - preset: The date range preset to convert to a DateInterval
    ///   - now: The reference date for relative calculations (defaults to current date)
    /// - Returns: A DateInterval representing the date range
    ///
    /// ## Examples
    /// ```swift
    /// let calendar = Calendar.current
    /// let now = Date("2025-01-15T14:30:00Z")
    ///
    /// // Today: Returns interval for January 15
    /// let today = calendar.makeDateInterval(for: .today, now: now)
    /// // Start: 2025-01-15 00:00:00
    /// // End: 2025-01-16 00:00:00
    ///
    /// // Last 7 days: Returns previous 7 complete days, not including today
    /// let last7 = calendar.makeDateInterval(for: .last7Days, now: now)
    /// // Start: 2025-01-08 00:00:00
    /// // End: 2025-01-15 00:00:00
    /// ```
    func makeDateInterval(for preset: DateIntervalPreset, now: Date = .now) -> DateInterval {
        switch preset {
        case .today: makeDateInterval(of: .day, for: now)
        case .thisWeek: makeDateInterval(of: .weekOfYear, for: now)
        case .thisMonth: makeDateInterval(of: .month, for: now)
        case .thisQuarter: makeDateInterval(of: .quarter, for: now)
        case .thisYear: makeDateInterval(of: .year, for: now)
        case .last7Days: makeDateInterval(offset: -7, component: .day, for: now)
        case .last28Days: makeDateInterval(offset: -28, component: .day, for: now)
        case .last30Days: makeDateInterval(offset: -30, component: .day, for: now)
        case .last90Days: makeDateInterval(offset: -90, component: .day, for: now)
        case .last6Months: makeDateInterval(offset: -6, component: .month, for: now)
        case .last12Months: makeDateInterval(offset: -12, component: .month, for: now)
        case .last3Years: makeDateInterval(offset: -3, component: .year, for: now)
        case .last10Years: makeDateInterval(offset: -10, component: .year, for: now)
        }
    }

    private func makeDateInterval(of component: Component, for date: Date) -> DateInterval {
        guard let interval = self.dateInterval(of: component, for: date) else {
            assertionFailure("Failed to get \(component) interval for \(date)")
            return DateInterval(start: date, duration: 0)
        }
        return interval
    }

    private func makeDateInterval(offset: Int, component: Component, for date: Date) -> DateInterval {
        var endDate = makeDateInterval(of: component, for: date).end
        if component == .day {
            endDate = self.date(byAdding: .day, value: -1, to: endDate) ?? endDate
        }
        guard let startDate = self.date(byAdding: component, value: offset, to: endDate), endDate >= startDate else {
            assertionFailure("Failed to calculate start date for \(offset) \(component) from \(endDate)")
            return DateInterval(start: date, end: date)
        }
        return DateInterval(start: startDate, end: endDate)
    }
}
