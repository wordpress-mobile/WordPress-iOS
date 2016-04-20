import Foundation


extension NSDate
{
    private struct iso8601Date {
        static let formatter: NSDateFormatter = {
            let formatter           = NSDateFormatter()
            formatter.locale        = NSLocale(localeIdentifier: "en_US_POSIX")
            formatter.dateFormat    = "yyyy-MM-dd'T'HH:mm:ssZZZZZ";
            formatter.timeZone      = NSTimeZone(forSecondsFromGMT: 0)
            return formatter
        }()
    }
    
    public class func dateWithISO8601String(string: String) -> NSDate? {
        return iso8601Date.formatter.dateFromString(string)
    }

    public func normalizedDate() -> NSDate {

        let calendar        = NSCalendar.currentCalendar()
        calendar.timeZone   = NSTimeZone.localTimeZone()

        let flags: NSCalendarUnit = [.Day, .WeekOfYear, .Month, .Year]
  
        let components      = calendar.components(flags, fromDate: self)

        let normalized      = NSDateComponents()
        normalized.year     = components.year
        normalized.month    = components.month
        normalized.weekday  = components.weekday
        normalized.day      = components.day

        return calendar.dateFromComponents(normalized) ?? self
    }
}
