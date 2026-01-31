import Foundation

/// Formats date intervals for display in stats UI, with smart year display.
///
/// Years are shown only when dates are not in the current year.
///
/// ## Examples
///
/// ```swift
/// // Current year: no year shown
/// "Mar 15"                           // Single day
/// "Jan 1 – 5"                        // Same month
/// "Jan 31 – Feb 2"                   // Cross month
///
/// // Previous year: year shown
/// "Mar 15, 2024"                     // Single day
/// "Jan 1 – 5, 2024"                  // Same month
/// "Jan 31 – Feb 2, 2024"             // Cross month
///
/// // Cross-year ranges: both years shown
/// "Dec 31, 2024 – Jan 2, 2025"
///
/// // Special cases
/// "Jan 2025"                         // Entire month
/// "Jan – May 2025"                   // Multiple full months
/// "2025"                             // Entire year
/// "2020 – 2023"                      // Multiple full years
/// ```
struct StatsDateRangeFormatter {
    private let locale: Locale
    private let timeZone: TimeZone
    private let dateFormatter = DateFormatter()
    private let dateIntervalFormatter = DateIntervalFormatter()
    private let now: @Sendable () -> Date

    init(
        locale: Locale = .current,
        timeZone: TimeZone = .current,
        now: @Sendable @escaping () -> Date = { Date() }
    ) {
        self.locale = locale
        self.timeZone = timeZone
        self.now = now

        dateFormatter.locale = locale
        dateFormatter.timeZone = timeZone

        dateIntervalFormatter.locale = locale
        dateIntervalFormatter.timeZone = timeZone
        dateIntervalFormatter.dateStyle = .medium
        dateIntervalFormatter.timeStyle = .none
    }

    /// Returns a preset name or a formatted date interval depending on what's
    /// optimial for presentation.
    func string(from dateRange: StatsDateRange) -> String {
        if let preset = dateRange.preset, !preset.prefersDateIntervalFormatting {
            return preset.localizedString
        }
        return string(from: dateRange.dateInterval)
    }

    func string(from interval: DateInterval, now: Date? = nil) -> String {
        var calendar = Calendar.current
        calendar.timeZone = timeZone

        let startDate = interval.start
        let endDate = interval.end
        let currentDate = now ?? self.now()
        let currentYear = calendar.component(.year, from: currentDate)

        // Check if it's an entire year
        if let yearInterval = calendar.dateInterval(of: .year, for: startDate),
           calendar.isDate(yearInterval.start, inSameDayAs: startDate) &&
            calendar.isDate(yearInterval.end, inSameDayAs: endDate) {
            dateFormatter.dateFormat = "yyyy"
            return dateFormatter.string(from: startDate)
        }

        // Check if it's an entire month
        if let monthInterval = calendar.dateInterval(of: .month, for: startDate),
           calendar.isDate(monthInterval.start, inSameDayAs: startDate) &&
            calendar.isDate(monthInterval.end, inSameDayAs: endDate) {
            dateFormatter.dateFormat = "MMM yyyy"
            return dateFormatter.string(from: startDate)
        }

        // Check if it's multiple full years
        if isMultipleFullYears(interval: interval, calendar: calendar) {
            let displayedEndDate = calendar.date(byAdding: .second, value: -1, to: endDate) ?? endDate
            dateFormatter.dateFormat = "yyyy"
            let startYear = dateFormatter.string(from: startDate)
            let endYear = dateFormatter.string(from: displayedEndDate)
            return "\(startYear) – \(endYear)"
        }

        // Check if it's multiple full months
        if isMultipleFullMonths(interval: interval, calendar: calendar) {
            let startYear = calendar.component(.year, from: startDate)
            let endYear = calendar.component(.year, from: endDate)
            let displayedEndDate = calendar.date(byAdding: .second, value: -1, to: endDate) ?? endDate

            if startYear == endYear {
                // Same year: "Jan – May 2025"
                dateFormatter.dateFormat = "MMM"
                let startMonth = dateFormatter.string(from: startDate)
                let endMonth = dateFormatter.string(from: displayedEndDate)
                dateFormatter.dateFormat = "yyyy"
                let year = dateFormatter.string(from: startDate)
                return "\(startMonth) – \(endMonth) \(year)"
            } else {
                // Different years: "Dec 2024 – Feb 2025"
                dateFormatter.dateFormat = "MMM yyyy"
                let start = dateFormatter.string(from: startDate)
                let end = dateFormatter.string(from: displayedEndDate)
                return "\(start) – \(end)"
            }
        }

        // Default formatting for other ranges
        let displayedEndDate = calendar.date(byAdding: .second, value: -1, to: endDate) ?? endDate

        if calendar.component(.year, from: startDate) == currentYear && calendar.component(.year, from: displayedEndDate) == currentYear {
            dateIntervalFormatter.dateTemplate = "MMM d"
        } else {
            dateIntervalFormatter.dateTemplate = nil
            dateIntervalFormatter.dateStyle = .medium
            dateIntervalFormatter.timeStyle = .none
        }

        return dateIntervalFormatter.string(from: startDate, to: displayedEndDate)
    }

    private func isMultipleFullYears(interval: DateInterval, calendar: Calendar) -> Bool {
        let startDate = interval.start
        let endDate = interval.end

        // Check if start date is January 1st
        guard calendar.component(.month, from: startDate) == 1 else { return false }
        guard calendar.component(.day, from: startDate) == 1 else { return false }

        // Check if end date is January 1st (open interval)
        guard calendar.component(.month, from: endDate) == 1 else { return false }
        guard calendar.component(.day, from: endDate) == 1 else { return false }

        // Check if it spans more than one year
        let startYear = calendar.component(.year, from: startDate)
        let endYear = calendar.component(.year, from: endDate)

        return endYear > startYear + 1
    }

    private func isMultipleFullMonths(interval: DateInterval, calendar: Calendar) -> Bool {
        let startDate = interval.start
        let endDate = interval.end

        // Check if start date is the first day of a month
        guard calendar.component(.day, from: startDate) == 1 else { return false }

        // Check if end date is the first day of a month (open interval)
        guard calendar.component(.day, from: endDate) == 1 else { return false }

        // Check if it spans more than one month
        let startMonth = calendar.component(.month, from: startDate)
        let startYear = calendar.component(.year, from: startDate)
        let endMonth = calendar.component(.month, from: endDate)
        let endYear = calendar.component(.year, from: endDate)

        if startYear == endYear {
            return endMonth > startMonth + 1
        } else {
            // Cross-year: always multiple months
            return true
        }
    }
}
