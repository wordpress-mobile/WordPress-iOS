import Foundation

enum NavigationDirection {
    case backward
    case forward

    var systemImage: String {
        switch self {
        case .backward: "chevron.backward"
        case .forward: "chevron.forward"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .forward: Strings.Accessibility.nextPeriod
        case .backward: Strings.Accessibility.previousPeriod
        }
    }
}

extension Calendar {
    /// Navigates to the next or previous period from the given date interval.
    ///
    /// This method navigates by the length of the period for the given component.
    /// For example, if the interval represents 6 months and the component is `.month`,
    /// it will navigate forward or backward by 6 months.
    ///
    /// - Parameters:
    ///   - interval: The date interval to navigate from
    ///   - direction: Whether to navigate forward (.forward) or backward (.backward)
    ///   - component: The calendar component to use for navigation
    /// - Returns: A new date interval representing the navigated period
    func navigate(_ interval: DateInterval, direction: NavigationDirection, component: Calendar.Component) -> DateInterval {
        let multiplier = direction == .forward ? 1 : -1

        // Calculate the offset based on the interval length and component
        let offset = calculateOffset(for: interval, component: component)

        // Navigate by the calculated offset
        guard let newStart = date(byAdding: component, value: offset * multiplier, to: interval.start),
              let newEnd = date(byAdding: component, value: offset * multiplier, to: interval.end) else {
            assertionFailure("Failed to navigate \(component) interval by \(offset)")
            return interval
        }

        return DateInterval(start: newStart, end: newEnd)
    }

    /// Calculates the number of units of the given component in the interval
    private func calculateOffset(for interval: DateInterval, component: Calendar.Component) -> Int {
        let components = dateComponents([component], from: interval.start, to: interval.end)
        return components.value(for: component) ?? 1
    }

    /// Determines if navigation is allowed in the specified direction
    func canNavigate(_ interval: DateInterval, direction: NavigationDirection, minYear: Int = 2000, now: Date = .now) -> Bool {
        switch direction {
        case .backward:
            let components = dateComponents([.year], from: interval.start)
            return (components.year ?? 0) > minYear
        case .forward:
            let currentEndDate = startOfDay(for: interval.end)
            let today = startOfDay(for: now)
            return currentEndDate <= today
        }
    }

    /// Determines the appropriate navigation component for a given date interval.
    ///
    /// This method analyzes the interval to determine if it represents a standard calendar period
    /// (day, week, month, quarter, or year) and returns the corresponding component for navigation.
    ///
    /// - Parameter interval: The date interval to analyze
    /// - Returns: The calendar component that best represents the interval, or nil if it's a custom period
    func determineNavigationComponent(for interval: DateInterval) -> Calendar.Component? {
        let start = interval.start
        let end = interval.end.addingTimeInterval(-1)

        // Check if it's a single day
        if isDate(start, equalTo: end, toGranularity: .day) {
            return .day
        }

        // Check if it's a complete month
        let startOfMonth = dateInterval(of: .month, for: start)
        if let monthInterval = startOfMonth,
           abs(monthInterval.start.timeIntervalSince(start)) < 1,
           abs(monthInterval.end.timeIntervalSince(interval.end)) < 1 {
            return .month
        }

        // Check if it's a complete quarter
        let startOfQuarter = dateInterval(of: .quarter, for: start)
        if let quarterInterval = startOfQuarter,
           abs(quarterInterval.start.timeIntervalSince(start)) < 1,
           abs(quarterInterval.end.timeIntervalSince(interval.end)) < 1 {
            return .quarter
        }

        // Check if it's a complete year
        let startOfYear = dateInterval(of: .year, for: start)
        if let yearInterval = startOfYear,
           abs(yearInterval.start.timeIntervalSince(start)) < 1,
           abs(yearInterval.end.timeIntervalSince(interval.end)) < 1 {
            return .year
        }

        // Check if it's a complete week
        let startOfWeek = dateInterval(of: .weekOfYear, for: start)
        if let weekInterval = startOfWeek,
           abs(weekInterval.start.timeIntervalSince(start)) < 1,
           abs(weekInterval.end.timeIntervalSince(interval.end)) < 1 {
            return .weekOfYear
        }

        return nil
    }
}
