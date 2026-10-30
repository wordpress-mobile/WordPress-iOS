import Foundation

/// Formats the time of support conversations and messages relative to now.
///
/// Recent dates read like "Just now" or "5 minutes ago". Dates older than 30 days show the date instead.
enum UnifiedSupportRelativeTime {

    static func format(
        _ date: Date,
        relativeTo now: Date = .now,
        locale: Locale = .autoupdatingCurrent,
        timeZone: TimeZone = .autoupdatingCurrent
    ) -> String {
        let minute: TimeInterval = 60
        let hour = 60 * minute
        let day = 24 * hour
        let week = 7 * day

        // Dates slightly in the future (e.g., because of clock differences with the server) count as "now".
        let elapsed = max(0, now.timeIntervalSince(date))

        let components: DateComponents
        switch elapsed {
        case ..<minute:
            return UnifiedSupportLocalization.justNow
        case ..<hour:
            components = DateComponents(minute: -Int(elapsed / minute))
        case ..<day:
            components = DateComponents(hour: -Int(elapsed / hour))
        case ..<week:
            components = DateComponents(day: -Int(elapsed / day))
        case ..<(30 * day):
            components = DateComponents(weekOfMonth: -Int(elapsed / week))
        default:
            return date.formatted(
                Date.FormatStyle(date: .abbreviated, time: .omitted, locale: locale, timeZone: timeZone)
            )
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.locale = locale
        formatter.unitsStyle = .full
        formatter.dateTimeStyle = .numeric
        return formatter.localizedString(from: components)
    }
}
