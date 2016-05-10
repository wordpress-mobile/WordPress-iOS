import Foundation


extension NSDate
{
    /// Private Date Formatters
    ///
    private struct DateFormatters {
        static let iso8601 : NSDateFormatter = {
            let formatter           = NSDateFormatter()
            formatter.locale        = NSLocale(localeIdentifier: "en_US_POSIX")
            formatter.dateFormat    = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
            formatter.timeZone      = NSTimeZone(forSecondsFromGMT: 0)
            return formatter
        }()

        static let rfc1123 : NSDateFormatter = {
            let formatter           = NSDateFormatter()
            formatter.locale        = NSLocale(localeIdentifier: "en_US_POSIX")
            formatter.dateFormat    = "EEE, dd MMM yyyy HH:mm:ss z"
            formatter.timeZone      = NSTimeZone(forSecondsFromGMT: 0)
            return formatter
        }()
    }

    /// Returns a NSDate Instance, given it's ISO8601 String Representation
    ///
    public class func dateWithISO8601String(string: String) -> NSDate? {
        return DateFormatters.iso8601.dateFromString(string)
    }

    /// Returns a NSDate instance with only its Year / Month / Weekday / Day set. Removes the time!
    ///
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

    /// Formats the current NSDate instance using the RFC1123 Standard
    ///
    public func toStringAsRFC1123() -> String {
        return DateFormatters.rfc1123.stringFromDate(self)
    }
}
