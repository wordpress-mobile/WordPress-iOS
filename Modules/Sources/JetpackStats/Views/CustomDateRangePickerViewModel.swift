import Foundation

@MainActor
final class CustomDateRangePickerViewModel: ObservableObject {
    @Published var startDate: Date {
        didSet {
            // If start date is after end date, adjust end date to be one day after start
            if startDate > endDate {
                endDate = calendar.date(byAdding: .day, value: 1, to: startDate) ?? startDate
            }
        }
    }

    @Published var endDate: Date {
        didSet {
            // If end date is before start date, adjust start date to be one day before end
            if endDate < startDate {
                startDate = calendar.date(byAdding: .day, value: -1, to: endDate) ?? endDate
            }
        }
    }

    private let calendar: Calendar
    private let comparison: DateRangeComparisonPeriod

    init(dateRange: StatsDateRange, calendar: Calendar) {
        let interval = dateRange.dateInterval
        self.calendar = calendar
        self.comparison = dateRange.comparison

        self.startDate = interval.start

        // The app uses inclusive date periods (e.g., Jan 1 00:00 to Jan 2 00:00 represents all of Jan 1).
        // For DatePicker, we subtract 1 second to ensure the end date shows as the last day of the range
        // (e.g., Jan 1 instead of Jan 2). The time component is irrelevant since we only pick dates.
        self.endDate = interval.end.addingTimeInterval(-1)
    }

    // MARK: - Date Calculations

    /// Creates the final DateInterval for the selected date range.
    /// The end date is adjusted by adding a full day to make the period inclusive.
    func createDateInterval() -> DateInterval {
        let adjustedEnd = {
            let date = calendar.startOfDay(for: endDate)
            return calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }()
        return DateInterval(start: startDate, end: adjustedEnd)
    }

    /// Returns a formatted string showing the number of days in the selected range.
    var formattedDateCount: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day]
        formatter.unitsStyle = .full
        formatter.calendar = calendar
        formatter.maximumUnitCount = 1

        // Match the interval calculation logic from createDateInterval()
        let adjustedEndDate = {
            let date = calendar.startOfDay(for: endDate)
            return calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }()

        return formatter.string(from: startDate, to: adjustedEndDate) ?? ""
    }

    // MARK: - Quick Period Selection

    /// Selects a quick period (week, month, quarter, year) based on the current start date.
    func selectQuickPeriod(_ component: Calendar.Component) {
        guard let interval = calendar.dateInterval(of: component, for: startDate) else {
            return
        }
        startDate = interval.start
        // Same adjustment as in init: subtract 1 second for DatePicker display
        endDate = interval.end.addingTimeInterval(-1)
    }

    /// Creates the final StatsDateRange with the selected dates.
    func createStatsDateRange() -> StatsDateRange {
        let interval = createDateInterval()
        let component = calendar.determineNavigationComponent(for: interval) ?? .day
        return StatsDateRange(
            interval: interval,
            component: component,
            comparison: comparison,
            calendar: calendar
        )
    }
}
