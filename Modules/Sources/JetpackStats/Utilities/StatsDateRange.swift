import Foundation

struct StatsDateRange: Equatable, Sendable {
    /// The primary date range for statistics.
    var dateInterval: DateInterval

    /// The navigation component (.day, .month, .year). If it's provided, it means
    /// the date interval was created with a preset to represet the respective
    /// date period. If nil, uses duration-based navigation.
    var component: Calendar.Component

    /// The comparison period type. Defaults to `.precedingPeriod` if nil.
    var comparison: DateRangeComparisonPeriod

    /// The calculated comparison date range.
    var effectiveComparisonInterval: DateInterval

    /// The calendar used for date calculations.
    let calendar: Calendar

    /// The preset that was used to create this date range, if any.
    var preset: DateIntervalPreset?

    init(
        interval: DateInterval,
        component: Calendar.Component,
        comparison: DateRangeComparisonPeriod = .precedingPeriod,
        calendar: Calendar,
        preset: DateIntervalPreset? = nil
    ) {
        self.dateInterval = interval
        self.comparison = comparison
        self.component = component
        self.calendar = calendar
        self.preset = preset
        self.effectiveComparisonInterval = interval
        self.refreshEffectiveComparisonPeriodInterval()
    }

    mutating func update(preset: DateIntervalPreset) {
        dateInterval = calendar.makeDateInterval(for: preset)
        component = preset.component
        self.preset = preset
        refreshEffectiveComparisonPeriodInterval()
    }

    func updating(preset: DateIntervalPreset) -> StatsDateRange {
        var copy = self
        copy.update(preset: preset)
        return copy
    }

    mutating func update(comparisonPeriod: DateRangeComparisonPeriod) {
        self.comparison = comparisonPeriod
        refreshEffectiveComparisonPeriodInterval()
    }

    private mutating func refreshEffectiveComparisonPeriodInterval() {
        effectiveComparisonInterval = calendar.comparisonRange(for: dateInterval, period: comparison, component: component)
    }

    // MARK: - Navigation

    /// Navigates to the specified direction (previous or next period).
    func navigate(_ direction: Calendar.NavigationDirection) -> StatsDateRange {
        // Use the component if available, otherwise determine it from the interval
        let newInterval = calendar.navigate(dateInterval, direction: direction, component: component)
        // When navigating, we lose the preset since it's no longer a standard preset
        return StatsDateRange(interval: newInterval, component: component, comparison: comparison, calendar: calendar, preset: nil)
    }

    /// Returns true if can navigate in the specified direction.
    func canNavigate(in direction: Calendar.NavigationDirection) -> Bool {
        calendar.canNavigate(dateInterval, direction: direction)
    }

    /// Generates a list of available adjacent periods in the specified direction.
    /// - Parameters:
    ///   - direction: The navigation direction (previous or next)
    ///   - maxCount: Maximum number of periods to generate (default: 10)
    /// - Returns: Array of AdjacentPeriod structs
    func availableAdjacentPeriods(in direction: Calendar.NavigationDirection, maxCount: Int = 10) -> [AdjacentPeriod] {
        var periods: [AdjacentPeriod] = []
        var currentRange = self
        let formatter = StatsDateRangeFormatter(timeZone: calendar.timeZone)
        for _ in 0..<maxCount {
            if currentRange.canNavigate(in: direction) {
                currentRange = currentRange.navigate(direction)
                let displayText = formatter.string(from: currentRange.dateInterval)
                periods.append(AdjacentPeriod(range: currentRange, displayText: displayText))
            } else {
                break
            }
        }
        return periods
    }

    func isAdjacent(to dateRange: StatsDateRange) -> Bool {
        dateInterval == dateRange.navigate(.backward).dateInterval ||
        dateInterval == dateRange.navigate(.forward).dateInterval
    }
}

/// Represents an adjacent period for navigation
struct AdjacentPeriod: Identifiable {
    let id = UUID()
    let range: StatsDateRange
    let displayText: String
}

extension Calendar {
    func makeDateRange(
        for preset: DateIntervalPreset,
        comparison: DateRangeComparisonPeriod = .precedingPeriod
    ) -> StatsDateRange {
        StatsDateRange(
            interval: makeDateInterval(for: preset),
            component: preset.component,
            comparison: comparison,
            calendar: self,
            preset: preset
        )
    }
}
