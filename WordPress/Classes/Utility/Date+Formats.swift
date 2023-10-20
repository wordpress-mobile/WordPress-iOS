import Foundation

extension Date {
    /// Extracts the time from the passed date
    func toLocalTime() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    func toLocal24HTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }

    /// Formats the current date as a relative date if it's within a week of today, or with a medium
    /// absolute date formatter otherwise.
    ///
    /// - Example: 5 min. ago
    /// - Example: 8 hr. ago
    /// - Example: 2 days ago
    /// - Example: Jan 22, 2017
    ///
    func toShortString() -> String {
        let components = Calendar.current.dateComponents([.day], from: self, to: Date())
        if let days = components.day, abs(days) < 7 {
            let relativeFormatter = RelativeDateTimeFormatter()
            relativeFormatter.dateTimeStyle = .numeric
            relativeFormatter.unitsStyle = .abbreviated
            return relativeFormatter.localizedString(fromTimeInterval: timeIntervalSinceNow)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: self)
        }
    }
}
