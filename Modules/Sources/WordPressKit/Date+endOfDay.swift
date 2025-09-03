import Foundation

extension Date {
    /// Returns a Date representing the last second of the given day
    ///
    func endOfDay() -> Date? {
        Calendar.current.date(byAdding: .second, value: 86399, to: self)
    }
}
