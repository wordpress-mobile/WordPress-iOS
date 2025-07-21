import Foundation

struct StatsDateFormatter: Sendable {
    enum Context {
        case compact
        case regular
    }

    var locale: Locale {
        didSet {
            updateFormatters()
        }
    }

    var timeZone: TimeZone {
        didSet {
            updateFormatters()
        }
    }

    final class CachedFormatters: Sendable {
        let hour: DateFormatter

        let compactDay: DateFormatter
        let compactMonth: DateFormatter

        let regularDay: DateFormatter
        let regularMonth: DateFormatter

        let year: DateFormatter

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
        }

        func formatter(granularity: DateRangeGranularity, context: Context) -> DateFormatter {
            switch context {
            case .compact:
                switch granularity {
                case .hour: hour
                case .day: compactDay
                case .month: compactMonth
                case .year: year
                }
            case .regular:
                switch granularity {
                case .hour: hour
                case .day: regularDay
                case .month: regularMonth
                case .year: year
                }
            }
        }
    }

    private var formatters: CachedFormatters

    private mutating func updateFormatters() {
        formatters = CachedFormatters(locale: locale, timeZone: timeZone)
    }

    init(locale: Locale = .current, timeZone: TimeZone = .current) {
        self.locale = locale
        self.timeZone = timeZone
        self.formatters = CachedFormatters(locale: locale, timeZone: timeZone)
    }

    func formatDate(_ date: Date, granularity: DateRangeGranularity, context: Context = .compact) -> String {
        let formatter = formatters.formatter(granularity: granularity, context: context)
        return formatter.string(from: date)
    }

    var formattedTimeOffset: String {
        formatters.timeOffset.string(from: .now)
    }
}
