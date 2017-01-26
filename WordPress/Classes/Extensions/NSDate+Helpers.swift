import Foundation


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

    public func toStringForPageSections() -> String {
        return (self as Date).toStringForPageSections()
    }
}
