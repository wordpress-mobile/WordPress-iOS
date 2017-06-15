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

        static let pageSectionFormatter: TTTTimeIntervalFormatter = {
            let formatter = TTTTimeIntervalFormatter()

            formatter.leastSignificantUnit = .day
            formatter.usesIdiomaticDeicticExpressions = true
            formatter.presentDeicticExpression = NSLocalizedString("today", comment: "Today")

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

    /// Formats the current date as relative date if it's within a week of
    /// today, or with DateFormatter.Style.medium otherwise.
    ///
    /// - Example: 22 hours from now
    /// - Example: 5 minutes ago
    /// - Example: 8 hours ago
    /// - Example: 2 days ago
    /// - Example: Jan 22, 2017
    ///
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

    /// Formats the current date as a medium relative date/time.
    ///
    /// - Example: Tomorrow, 6:45 AM
    /// - Example: Today, 8:09 AM
    /// - Example: Yesterday, 11:36 PM
    /// - Example: Jan 28, 2017, 1:51 PM
    /// - Example: Jan 22, 2017, 2:18 AM
    ///
    public func mediumStringWithTime() -> String {
        return DateFormatters.mediumDateTime.string(from: self)
    }

    /// Formats the current date as a short relative date/time.
    ///
    /// - Example: Tomorrow, 6:45 AM
    /// - Example: Today, 8:09 AM
    /// - Example: Yesterday, 11:36 PM
    /// - Example: 1/28/17, 1:51 PM
    /// - Example: 1/22/17, 2:18 AM
    ///
    public func shortStringWithTime() -> String {
        return DateFormatters.shortDateTime.string(from: self)
    }

    public func toStringForPageSections() -> String {
        let interval = timeIntervalSinceNow

        if interval > 0 && interval < 86400 {
            return NSLocalizedString("later today", comment: "Later today")
        } else {
            return DateFormatters.pageSectionFormatter.string(forTimeInterval: interval)
        }
    }
}

extension NSDate {
    public static func dateWithISO8601String(_ string: String) -> NSDate? {
        return Date.DateFormatters.iso8601.date(from: string) as NSDate?
    }

    /// Formats the current date as relative date if it's within a week of
    /// today, or with NSDateFormatterMediumStyle otherwise.
    ///
    /// - Example: 22 hours from now
    /// - Example: 5 minutes ago
    /// - Example: 8 hours ago
    /// - Example: 2 days ago
    /// - Example: Jan 22, 2017
    ///
    public func mediumString() -> String {
        return (self as Date).mediumString()
    }

    /// Formats the current date as a medium relative date/time.
    ///
    /// - Example: Tomorrow, 6:45 AM
    /// - Example: Today, 8:09 AM
    /// - Example: Yesterday, 11:36 PM
    /// - Example: Jan 28, 2017, 1:51 PM
    /// - Example: Jan 22, 2017, 2:18 AM
    ///
    public func mediumStringWithTime() -> String {
        return (self as Date).mediumStringWithTime()
    }

    /// Formats the current date as a short relative date/time.
    ///
    /// - Example: Tomorrow, 6:45 AM
    /// - Example: Today, 8:09 AM
    /// - Example: Yesterday, 11:36 PM
    /// - Example: 1/28/17, 1:51 PM
    /// - Example: 1/22/17, 2:18 AM
    ///
    public func shortStringWithTime() -> String {
        return (self as Date).shortStringWithTime()
    }

    public func toStringForPageSections() -> String {
        return (self as Date).toStringForPageSections()
    }
}
