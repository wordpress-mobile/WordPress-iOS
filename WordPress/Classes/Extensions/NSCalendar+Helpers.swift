import Foundation


extension Calendar
{
    public func daysElapsedSinceDate(_ date: Date) -> Int {
        let fromDate = date.normalizedDate()
        let toDate = Date().normalizedDate()

        let delta = components(.day, from: fromDate, to: toDate, options: .matchFirst)

        return delta.day
    }
}
