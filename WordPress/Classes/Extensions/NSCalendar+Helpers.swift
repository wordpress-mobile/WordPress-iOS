import Foundation


extension Calendar {
    public func daysElapsedSinceDate(_ date: Date) -> Int {
        let fromDate = date.normalizedDate()
        let toDate = Date().normalizedDate()

        let components = dateComponents([.day], from: fromDate, to: toDate)
        return components.day!
    }

    /// Maps a zero-based index number that represents the ordered day of the week,
    /// to a localized index that can be used to access day information from
    /// calendar properties such as `shortWeekdaySymbols`.
    /// 
    /// This is used to take into account different starting days of the week
    /// depending on the device's current locale.
    ///
    public func localizedDayIndex(_ index: Int) -> Int {
        return (index + firstWeekday - 1) % weekdaySymbols.count
    }
}
