import Foundation

class ReaderRelativeTimeFormatter: NSObject {
    /// Date formatter used for dates older than a year
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    /// Date formatter used for dates older than a week but earlier than a year
    private lazy var recentDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM dd")
        return formatter
    }()

    private let calendar: Calendar

    init(calendar: Calendar = Calendar.autoupdatingCurrent) {
        self.calendar = calendar
    }

    public func string(from date: Date) -> String {
        let now = Date()

        let deltaComponents = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)

        // If the date year is not equal to the current year:
        // Example: Today is May 25th 2020 and the date is Dec 19th 2019
        // (MMM dd, YYYY): Dec 19, 2019
        let dateYear = calendar.component(.year, from: date)
        let nowYear = calendar.component(.year, from: now)

        if dateYear != nowYear {
            return dateFormatter.string(from: date)
        }

        // If the date is older than a week:
        // (MMM dd): Jan 12, Feb 28
        if let day = deltaComponents.day, day >= 7 {
            return recentDateFormatter.string(from: date)
        }

        // If the date is within a week display a relative time in days:
        // 1d, 3d, 6d
        if let day = deltaComponents.day, day > 0 {
            let format = NSLocalizedString("%dd", comment: "Relative time format with day unit abbreviation (d): Xd, 1d, 3d, 6d")
            return String(format: format, day)
        }

        // If the date is within 24 hours display the relative time in hours
        // 1h, 12h, 23h
        if let hour = deltaComponents.hour, hour > 0 {
            let format = NSLocalizedString("%dh", comment: "Relative time format with hour unit abbreviation (h): Xh, 1h, 10h, 23h")
            return String(format: format, hour)
        }

        // If the date is within an hour, display the relative time in minutes
        // 1m, 50m, 59m
        if let minute = deltaComponents.minute, minute >= 0 {
            // If the minute value is 0 round it up to 1 so we don't display "0m"
            // Example being if the date is 30 seconds old
            let value = (minute == 0) ? 1 : minute

            let format = NSLocalizedString("%dm", comment: "Relative time format with minute unit abbreviation (m): Xm, 1m, 10m, 59m")
            return String(format: format, value)
        }

        // If the date is in the future, display "just now"
        return NSLocalizedString("just now", comment: "Relative time format ")
    }
}
