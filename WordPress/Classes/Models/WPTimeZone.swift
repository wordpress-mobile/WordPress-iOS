import Foundation

/// A model to represent known WordPress.com timezones
///
protocol WPTimeZone {
    var label: String { get }
    var value: String { get }
    func updateBlogSettings(_ settings: BlogSettings)
}

extension BlogSettings {
    @objc var timezoneLabel: String? {
        if let timezoneString = timezoneString?.nonEmptyString() {
            return timezoneString
        } else if let gmtOffset = gmtOffset {
            return OffsetTimeZone(offset: gmtOffset.floatValue).label
        } else {
            return nil
        }
    }
}

struct NamedTimeZone: WPTimeZone {
    let label: String
    let value: String

    func updateBlogSettings(_ settings: BlogSettings) {
        settings.gmtOffset = nil
        settings.timezoneString = value
    }
}

struct OffsetTimeZone: WPTimeZone {
    let offset: Float

    var label: String {
        if offset == 0 {
            return "UTC"
        } else if offset > 0 {
            return "UTC+\(hourOffset)\(minuteOffsetString)"
        } else {
            return "UTC\(hourOffset)\(minuteOffsetString)"
        }
    }

    var value: String {
        if offset == 0 {
            return "UTC"
        } else if offset > 0 {
            return "UTC+\(offset)"
        } else {
            return "UTC\(offset)"
        }
    }

    func updateBlogSettings(_ settings: BlogSettings) {
        settings.gmtOffset = offset as NSNumber
        settings.timezoneString = nil
    }

    private var hourOffset: Int {
        return Int(offset.rounded(.towardZero))
    }

    private var minuteOffset: Int {
        return Int(abs(offset.truncatingRemainder(dividingBy: 1) * 60))
    }

    private var minuteOffsetString: String {
        if minuteOffset != 0 {
            return ":\(minuteOffset)"
        } else {
            return ""
        }
    }
}
