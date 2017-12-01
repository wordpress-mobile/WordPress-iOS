import Foundation

class TimeZoneSettingHelper: NSObject {

    /// Returns a formatted 'prefix hour:min' string using DateComponentsFormatter
    ///
    /// Parameters
    /// - prefix: Prefix(if any) to be added to the resulting string
    /// - hours: The hours to be formatted
    /// - minutes: The minutes to be formatted, if 0, the minutes are ommitted in the formatted string
    @objc static func getFormattedString(prefix: String, hours: NSInteger, minutes: NSInteger) -> String? {
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
            formatString = "\(prefix)+%@"
        } else {
            formatString = "\(prefix)-%@"
        }
        let dateComponentString = dateFormatter.string(from: dateComponents)!
        return String(format: formatString, dateComponentString)
    }
}
