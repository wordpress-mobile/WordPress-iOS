import Foundation

struct StatsDateFormatter: Sendable {
    enum Context {
        case compact
        case regular
    }

    private let formatters: CachedFormatters
    private let calendar: Calendar
    private let now: @Sendable () -> Date

    final class CachedFormatters: Sendable {
        let hour: DateFormatter

        let compactDay: DateFormatter
        let compactMonth: DateFormatter

        let regularDay: DateFormatter
        let regularMonth: DateFormatter

        let year: DateFormatter
        let week: StatsDateRangeFormatter

        let timeOffset: DateFormatter

        init(locale: Locale, timeZone: TimeZone) {
            func makeFormatter(_ dateFormat: String) -> DateFormatter {
                let formatter = DateFormatter()
                formatter.locale = locale
                formatter.timeZone = timeZone
                formatter.dateFormat = dateFormat
                return formatter
            }

            hour = makeFormatter("h a")

            compactDay = makeFormatter("MMM d")
            compactMonth = makeFormatter("MMM")

            regularDay = makeFormatter("EEEE, MMMM d")
            regularMonth = makeFormatter("MMMM yyyy")

            year = makeFormatter("yyyy")

            timeOffset = makeFormatter("ZZZZ")

            week = StatsDateRangeFormatter(locale: locale, timeZone: timeZone)
        }

        func formatter(granularity: DateRangeGranularity, context: Context) -> DateFormatter {
            switch context {
            case .compact:
                switch granularity {
                case .hour: hour
                case .day: compactDay
                case .week: compactDay
                case .month: compactMonth
                case .year: year
                }
            case .regular:
                switch granularity {
                case .hour: hour
                case .day: regularDay
                case .week: regularDay
                case .month: regularMonth
                case .year: year
                }
            }
        }
    }

    init(
        locale: Locale = .current,
        timeZone: TimeZone = .current,
        now: @Sendable @escaping () -> Date = { Date() }
    ) {
        self.formatters = CachedFormatters(locale: locale, timeZone: timeZone)
        self.calendar = {
            var calendar = Calendar.current
            calendar.timeZone = timeZone
            return calendar
        }()
        self.now = now
    }

    func formatDate(_ date: Date, granularity: DateRangeGranularity, context: Context = .compact) -> String {
        if granularity == .week && context == .regular {
            return formatWeekRange(containing: date)
        }
        let formatter = formatters.formatter(granularity: granularity, context: context)
        return formatter.string(from: date)
    }

    private func formatWeekRange(containing date: Date) -> String {
        guard var weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) else {
            return formatters.formatter(granularity: .day, context: .compact).string(from: date)
        }
        weekInterval.end = weekInterval.end.addingTimeInterval(-1)
        return formatters.week.string(from: weekInterval, now: now())
    }

    var formattedTimeOffset: String {
        formatters.timeOffset.string(from: .now)
    }
}
