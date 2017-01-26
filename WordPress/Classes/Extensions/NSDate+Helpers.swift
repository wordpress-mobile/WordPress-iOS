import Foundation
import FormatterKit

extension Date {
    /// Private Date Formatters
    ///
    fileprivate struct DateFormatters {
        static let iso8601: DateFormatter = {
            let formatter           = DateFormatter()
            formatter.locale        = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat    = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
            formatter.timeZone      = TimeZone(secondsFromGMT: 0)
            return formatter
        }()

        static let rfc1123: DateFormatter = {
            let formatter           = DateFormatter()
            formatter.locale        = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat    = "EEE, dd MMM yyyy HH:mm:ss z"
            formatter.timeZone      = TimeZone(secondsFromGMT: 0)
            return formatter
        }()

        static let mediumDate: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter
        }()

        static let mediumDateTime: DateFormatter = {
            let formatter = DateFormatter()
            formatter.doesRelativeDateFormatting = true
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter
        }()

        static let shortDateTime: DateFormatter = {
            let formatter = DateFormatter()
            formatter.doesRelativeDateFormatting = true
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter
        }()
    }

    /// Returns a NSDate Instance, given it's ISO8601 String Representation
    ///
    public static func dateWithISO8601String(_ string: String) -> Date? {
        return DateFormatters.iso8601.date(from: string)
    }

    /// Returns a NSDate instance with only its Year / Month / Weekday / Day set. Removes the time!
    ///
    public func normalizedDate() -> Date {

        var calendar        = Calendar.current
        calendar.timeZone   = TimeZone.autoupdatingCurrent

        let flags: NSCalendar.Unit = [.day, .weekOfYear, .month, .year]

        let components      = (calendar as NSCalendar).components(flags, from: self)

        var normalized      = DateComponents()
        normalized.year     = components.year
        normalized.month    = components.month
        normalized.weekday  = components.weekday
        normalized.day      = components.day

        return calendar.date(from: normalized) ?? self
    }

    /// Formats the current NSDate instance using the RFC1123 Standard
    ///
    public func toStringAsRFC1123() -> String {
        return DateFormatters.rfc1123.string(from: self)
    }

    public func mediumString() -> String {
        let relativeFormatter = TTTTimeIntervalFormatter()
        let absoluteFormatter = DateFormatters.mediumDate

        let components = Calendar.current.dateComponents([.day], from: self, to: Date())
        if let days = components.day, abs(days) < 7 {
            return relativeFormatter.string(forTimeInterval: timeIntervalSinceNow)
        } else {
            return absoluteFormatter.string(from: self)
        }
    }

    public func mediumStringWithTime() -> String {
        return DateFormatters.mediumDateTime.string(from: self)
    }

    public func shortStringWithTime() -> String {
        return DateFormatters.shortDateTime.string(from: self)
    }
}

extension NSDate {
    public static func dateWithISO8601String(_ string: String) -> NSDate? {
        return Date.DateFormatters.iso8601.date(from: string) as NSDate?
    }

    public func mediumString() -> String {
        return (self as Date).mediumString()
    }

    public func mediumStringWithTime() -> String {
        return (self as Date).mediumStringWithTime()
    }

    public func shortStringWithTime() -> String {
        return (self as Date).shortStringWithTime()
    }
}
