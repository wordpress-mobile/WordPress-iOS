import Foundation


extension NSCalendar
{
    public func daysElapsedSinceDate(date: NSDate) -> Int {
        let fromDate = date.normalizedDate()
        let toDate = NSDate().normalizedDate()
        
        let delta = components(.Day, fromDate: fromDate, toDate: toDate, options: .MatchFirst)
        
        return delta.day
    }
}
