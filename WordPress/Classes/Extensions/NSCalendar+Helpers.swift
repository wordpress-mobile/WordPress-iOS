import Foundation


extension NSCalendar
{
    public func daysElapsedSinceDate(date: NSDate) -> Int {
        let fromDate = date.normalizedDate()
        let toDate = NSDate().normalizedDate()
        
        let flags = NSCalendarUnit.DayCalendarUnit
        let delta = components(flags, fromDate: fromDate, toDate: toDate, options: nil)
        
        return delta.day
    }
}
