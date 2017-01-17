import Foundation


extension Calendar {
    public func daysElapsedSinceDate(_ date: Date) -> Int {
        let fromDate = date.normalizedDate()
        let toDate = Date().normalizedDate()

        let components = dateComponents([.day], from: fromDate, to: toDate)
        return components.day!
    }
}
