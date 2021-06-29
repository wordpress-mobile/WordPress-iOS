import Foundation


extension Calendar {
    public func daysElapsedSinceDate(_ date: Date) -> Int {
        let fromDate = date.normalizedDate()
        let toDate = Date().normalizedDate()

        let components = dateComponents([.day], from: fromDate, to: toDate)
        return components.day!
    }

    /// Converts a localized weekday index (where 0 can be either Sunday or Monday depending on the locale settings)
    /// into an unlocalized weekday index (where 0 is always Sunday).
    ///
    /// - Parameters:
    ///     - localizedWeekdayIndex: a localized weekday index representing the desired day of
    ///         the week.  0 could either be Sunday or Monday depending on the `Calendar`'s locale settings.
    ///
    /// - Returns: an index where 0 is always Sunday.  This index can be used with methods such as `Calendar.weekdaySymbol`
    ///     to obtain the name of the day.
    ///
    public func unlocalizedWeekdayIndex(localizedWeekdayIndex: Int) -> Int {
        return (localizedWeekdayIndex + firstWeekday - 1) % weekdaySymbols.count
    }

    /// Converts an unlocalized weekday index (where 0 is always Sunday)
    /// into a localized weekday index (where 0 can be either Sunday or Monday depending on the locale settings).
    ///
    /// - Parameters:
    ///     - unlocalizedWeekdayIndex: an unlocalized weekday index representing the desired day of
    ///         the week.  0 is always Sunday.
    ///
    /// - Returns: an index where 0 can be either Sunday or Monday depending on locale settings.
    ///
    public func localizedWeekdayIndex(unlocalizedWeekdayIndex: Int) -> Int {
        let firstZeroBasedWeekday = firstWeekday - 1

        return unlocalizedWeekdayIndex >= firstZeroBasedWeekday
            ? unlocalizedWeekdayIndex - firstZeroBasedWeekday
            : unlocalizedWeekdayIndex + weekdaySymbols.count - firstZeroBasedWeekday
    }
}
