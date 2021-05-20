import Foundation

struct SiteDateFormatters {

    static func dateFormatter(for timeZone: TimeZone, dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        formatter.timeZone = timeZone
        return formatter
    }
}
