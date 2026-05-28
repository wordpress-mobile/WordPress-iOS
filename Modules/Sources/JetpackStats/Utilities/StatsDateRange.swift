import Foundation

struct StatsDateRange: Equatable, Sendable {
    /// The primary date range for statistics.
    var dateInterval: DateInterval

    /// The navigation component (.day, .month, .year). If it's provided, it means
    /// the date interval was created with a preset to represet the respective
    /// date period. If nil, uses duration-based navigation.
    var component: Calendar.Component

    /// The comparison period type.
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
        effectiveComparisonInterval = calendar.comparisonRange(
            for: dateInterval,
            period: comparison == .off ? .precedingPeriod : comparison,
            component: component
        )
    }

    // MARK: - Navigation

    /// Navigates to the specified direction (previous or next period).
    func navigate(_ direction: NavigationDirection) -> StatsDateRange {
        // Use the component if available, otherwise determine it from the interval
        let newInterval = calendar.navigate(dateInterval, direction: direction, component: component)
        // When navigating, we lose the preset since it's no longer a standard preset
        return StatsDateRange(interval: newInterval, component: component, comparison: comparison, calendar: calendar, preset: nil)
    }

    /// Returns true if can navigate in the specified direction.
    func canNavigate(in direction: NavigationDirection, now: Date = .now) -> Bool {
        calendar.canNavigate(dateInterval, direction: direction, now: now)
    }

    /// Generates a list of available adjacent periods in the specified direction.
    /// - Parameters:
    ///   - direction: The navigation direction (previous or next)
    ///   - maxCount: Maximum number of periods to generate (default: 10)
    ///   - now: The reference date for determining navigation bounds (default: .now)
    /// - Returns: Array of AdjacentPeriod structs
    func availableAdjacentPeriods(in direction: NavigationDirection, maxCount: Int = 10, now: Date = .now) -> [AdjacentPeriod] {
        var periods: [AdjacentPeriod] = []
        var currentRange = self
        let formatter = StatsDateRangeFormatter(timeZone: calendar.timeZone, now: { now })
        for _ in 0..<maxCount {
            if currentRange.canNavigate(in: direction, now: now) {
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

struct StatsDateRangeSelection: Equatable {
    var range: StatsDateRange
    var subrange: StatsDateRange?

    var effectiveDateRange: StatsDateRange {
        subrange ?? range
    }

    mutating func navigate(_ direction: NavigationDirection) {
        if let currentSubrange = subrange {
            let newSubrange = currentSubrange.navigate(direction)
            if isWithinRange(newSubrange) {
                self.subrange = newSubrange
            } else {
                range = range.navigate(direction)
                subrange = makeEdgeSubrange(matching: currentSubrange, in: direction)
            }
        } else {
            range = range.navigate(direction)
        }
    }

    /// Returns the first or last period in the (already-navigated) `range` that matches
    /// the component of `reference`, so subrange navigation across range boundaries feels seamless.
    /// Returns nil if the resulting period doesn't align cleanly within the new range (e.g. a
    /// calendar week that straddles the range boundary).
    private func makeEdgeSubrange(matching reference: StatsDateRange, in direction: NavigationDirection) -> StatsDateRange? {
        let calendar = range.calendar
        let anchorDate: Date = switch direction {
        case .forward: range.dateInterval.start
        case .backward: Date(timeInterval: -1, since: range.dateInterval.end)
        }
        guard let interval = calendar.dateInterval(of: reference.component, for: anchorDate) else { return nil }
        let subrange = StatsDateRange(
            interval: interval,
            component: reference.component,
            comparison: range.comparison,
            calendar: calendar
        )
        return isWithinRange(subrange) ? subrange : nil
    }

    func canNavigate(in direction: NavigationDirection) -> Bool {
        if let subrange, isWithinRange(subrange.navigate(direction)) {
            return true
        }
        return range.canNavigate(in: direction)
    }

    private func isWithinRange(_ subrange: StatsDateRange) -> Bool {
        subrange.dateInterval.start >= range.dateInterval.start &&
        subrange.dateInterval.start < range.dateInterval.end
    }
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
