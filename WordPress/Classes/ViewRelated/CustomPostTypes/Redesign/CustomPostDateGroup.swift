import Foundation

/// Date bucket a row falls into, used to draw the group headers in the
/// redesigned posts list ("This week", "Earlier in July", "March 2025").
enum CustomPostDateGroup: Hashable {
    case thisWeek
    /// Older than a week but still inside the current calendar month.
    case earlierThisMonth(monthName: String)
    /// Any earlier month, named with its year unless it is the current one.
    case month(label: String)

    var localizedTitle: String {
        switch self {
        case .thisWeek:
            return Strings.thisWeek
        case .earlierThisMonth(let monthName):
            return String.localizedStringWithFormat(Strings.earlierInMonth, monthName)
        case .month(let label):
            return label
        }
    }
}

/// Buckets dates into `CustomPostDateGroup`s.
///
/// Anything dated in the future lands in `.thisWeek`. Callers listing
/// future-dated content (the Scheduled tab) should turn grouping off rather
/// than rely on that.
struct CustomPostDateGrouper {
    private let now: Date
    private let calendar: Calendar
    private let monthFormatter: DateFormatter
    private let monthYearFormatter: DateFormatter

    init(now: Date = .now, calendar: Calendar = .current, locale: Locale = .current) {
        self.now = now
        self.calendar = calendar
        // Standalone month form ("LLLL"), which is what a bare header needs in
        // languages that inflect the month when it appears next to a day.
        monthFormatter = Self.makeFormatter(template: "LLLL", calendar: calendar, locale: locale)
        monthYearFormatter = Self.makeFormatter(template: "LLLL yyyy", calendar: calendar, locale: locale)
    }

    func group(for date: Date) -> CustomPostDateGroup {
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        if date >= weekAgo {
            return .thisWeek
        }
        let then = calendar.dateComponents([.year, .month], from: date)
        let today = calendar.dateComponents([.year, .month], from: now)
        if then == today {
            return .earlierThisMonth(monthName: monthFormatter.string(from: date))
        }
        let formatter = then.year == today.year ? monthFormatter : monthYearFormatter
        return .month(label: formatter.string(from: date))
    }

    private static func makeFormatter(template: String, calendar: Calendar, locale: Locale) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate(template)
        return formatter
    }
}

private enum Strings {
    static let thisWeek = NSLocalizedString(
        "customPostList.dateGroup.thisWeek",
        value: "This week",
        comment: "Section header in the posts list for posts published in the last seven days"
    )
    static let earlierInMonth = NSLocalizedString(
        "customPostList.dateGroup.earlierInMonth",
        value: "Earlier in %1$@",
        comment:
            "Section header in the posts list for posts published earlier in the current month. %1$@ is the month name."
    )
}
