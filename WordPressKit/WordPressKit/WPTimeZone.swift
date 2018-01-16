import Foundation

/// A model to represent known WordPress.com timezones
///
public protocol WPTimeZone {
    var label: String { get }
    var value: String { get }

    var gmtOffset: Float? { get }
    var timezoneString: String? { get }
}

public struct TimeZoneGroup {
    public let name: String
    public let timezones: [WPTimeZone]
}

public struct NamedTimeZone: WPTimeZone {
    public let label: String
    public let value: String

    public var gmtOffset: Float? {
        return nil
    }

    public var timezoneString: String? {
        return value
    }
}

public struct OffsetTimeZone: WPTimeZone {
    let offset: Float

    public init(offset: Float) {
        self.offset = offset
    }

    public var label: String {
        if offset == 0 {
            return "UTC"
        } else if offset > 0 {
            return "UTC+\(hourOffset)\(minuteOffsetString)"
        } else {
            return "UTC\(hourOffset)\(minuteOffsetString)"
        }
    }

    public var value: String {
        if offset == 0 {
            return "UTC"
        } else if offset > 0 {
            return "UTC+\(offset)"
        } else {
            return "UTC\(offset)"
        }
    }

    public var gmtOffset: Float? {
        return offset
    }

    public var timezoneString: String? {
        return value
    }

    static func fromValue(_ value: String) -> OffsetTimeZone? {
        guard let offsetString = try? value.removingPrefix(pattern: "UTC") else {
            return nil
        }
        let offset: Float?
        if offsetString.isEmpty {
            offset = 0
        } else {
            offset = Float(offsetString)
        }
        return offset.map(OffsetTimeZone.init)
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
