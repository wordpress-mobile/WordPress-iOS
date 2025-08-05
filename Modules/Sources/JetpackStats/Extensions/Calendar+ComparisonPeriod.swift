import Foundation

enum DateRangeComparisonPeriod: Equatable, Sendable, CaseIterable, Identifiable {
    case precedingPeriod
    case samePeriodLastYear

    var id: DateRangeComparisonPeriod { self }

    var localizedTitle: String {
        switch self {
        case .precedingPeriod: Strings.DatePicker.precedingPeriod
        case .samePeriodLastYear: Strings.DatePicker.samePeriodLastYear
        }
    }
}

extension Calendar {
    func comparisonRange(for dateInterval: DateInterval, period: DateRangeComparisonPeriod, component: Calendar.Component) -> DateInterval {
        switch period {
        case .precedingPeriod:
            return navigate(dateInterval, direction: .backward, component: component)
        case .samePeriodLastYear:
            guard let newStart = date(byAdding: .year, value: -1, to: dateInterval.start),
                  let newEnd = date(byAdding: .year, value: -1, to: dateInterval.end) else {
                assertionFailure("something went wrong: invalid range for: \(dateInterval)")
                return dateInterval
            }
            return DateInterval(start: newStart, end: newEnd)
        }
    }

    /// Determines if a date represents a period that might have incomplete data.
    ///
    /// - Returns: True if the date's period might have incomplete data
    func isIncompleteDataPeriod(for date: Date, granularity: DateRangeGranularity, now: Date = .now) -> Bool {
        isDate(date, equalTo: now, toGranularity: granularity.component)
    }
}
