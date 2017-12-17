import Foundation

enum TimeZoneSelected {
    case timeZoneString(String)
    case manualOffset(NSNumber)

    var selectedLabel: String? {
        let selectedCellLabel: String?
        switch self {
        case .timeZoneString(let timeZoneString):
            if !timeZoneString.isEmpty {
                selectedCellLabel = timeZoneString
            } else {
                selectedCellLabel = nil
            }
        case .manualOffset(let offset):
            let utcString: String = TimeZoneSettingHelper.getDecimalBasedTimeZone(from: offset)
            selectedCellLabel = utcString
        }
        return selectedCellLabel
    }

    init?(timeZoneString: String?, manualOffset: NSNumber?) {
        if let timeZoneString = timeZoneString, !timeZoneString.isEmpty {
            self = .timeZoneString(timeZoneString)
        } else if let offset = manualOffset {
            self = .manualOffset(offset)
        } else {
            return nil
        }
    }
}

class TimeZoneSettingHelper: NSObject {

    /// Returns a formatted 'UTC hour:min' string using DateComponentsFormatter
    ///
    /// Parameters
    /// - hours: The hours to be formatted
    /// - minutes: The minutes to be formatted, if 0, the minutes are ommitted in the formatted string
    @objc static func getFormattedString(hours: NSInteger, minutes: NSInteger) -> String? {
        precondition(minutes >= 0 && minutes <= 60, "Minutes should range between 0 and 60")
        precondition(hours >= -12 && hours <= +14, "Hours should range between -12 and +14")
        let dateFormatter = DateComponentsFormatter()
        dateFormatter.allowedUnits = [.hour, .minute]
        dateFormatter.zeroFormattingBehavior = .dropTrailing
        var dateComponents = DateComponents()
        // use an abs integer because -ve hours and +ve minutes lead to minutes being subtracted
        // from the hours
        dateComponents.hour = abs(hours)
        dateComponents.minute = minutes
        let formatString: String
        if hours >= 0 {
            formatString = "\(TimeZoneSettingHelper.UTCString) +%@"
        } else {
            formatString = "\(TimeZoneSettingHelper.UTCString) -%@"
        }
        let dateComponentString = dateFormatter.string(from: dateComponents)!
        return String(format: formatString, dateComponentString)
    }

    static func getDecimalBasedTimeZone(from manualOffset: NSNumber) -> String {
        return String(format: "\(TimeZoneSettingHelper.UTCString)%+g", manualOffset.floatValue)
    }

    static let UTCString: String = "UTC"
}
