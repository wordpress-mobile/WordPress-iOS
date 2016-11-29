import Foundation


extension Calendar
{
    public func daysElapsedSinceDate(_ date: Date) -> Int {
        let fromDate = (date as NSDate).normalizedDate()
        let toDate = NSDate().normalizedDate()

        let components = dateComponents([.day], from: fromDate, to: toDate)
        return components.day!
    }
}
