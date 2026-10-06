#if UI_TEST_HTTP_FIXTURES
import Foundation

/// Generates the body of a stats response that has a row for every period in the interval the
/// request asks for.
///
/// A file can't hold such a response. The interval is different every day, and the app uses every
/// row it's given: a chart of the last seven days needs seven rows, dated the last seven days.
///
/// A mapping asks for one by naming the `stats-series` transformer and describing its fields:
///
/// ```json
/// "response": {
///     "status": 200,
///     "transformers": ["stats-series"],
///     "transformerParameters": {
///         "fields": [
///             {"name": "views", "average": 430, "hourly": true},
///             {"name": "visitors", "average": 265},
///             {"name": "subscribers", "level": 1200, "growth": 1.5}
///         ]
///     }
/// }
/// ```
///
/// - `average` is what the field comes to on an average day. A day's value varies around it with
///   the day of the week, and a longer period's value is the sum of its days'.
/// - `level` is for a running total instead: its value today, which was lower by `growth` for
///   every day before.
/// - `hourly` says whether the field has values when the periods are hours. The others are null
///   then, as they are from WordPress.com.
///
/// The interval comes from the request's query. It ends on `date`, and starts on `start_date` or,
/// without one, spans `quantity` periods. `unit` is the length of a period: `hour`, `day`, `week`,
/// `month` or `year`.
///
/// An average's values are computed from the dates alone, so a day has the same value whichever
/// interval it's requested in, and whenever it's requested.
struct StatsSeries: Sendable {
    struct Field: Sendable {
        enum Value: Sendable {
            case average(Double)
            case level(Double, growth: Double)
        }

        let name: String
        let value: Value
        let isHourly: Bool
    }

    struct InvalidParameters: Error {
        let reason: String
    }

    let fields: [Field]

    init(parameters: Any?) throws(InvalidParameters) {
        guard let parameters = parameters as? [String: Any], let fields = parameters["fields"] as? [[String: Any]]
        else {
            throw InvalidParameters(reason: "stats-series needs transformerParameters with a list of fields")
        }
        if let unknown = parameters.keys.sorted().first(where: { $0 != "fields" }) {
            throw InvalidParameters(reason: "stats-series doesn't support the parameter \(unknown)")
        }

        var parsed: [Field] = []
        for field in fields {
            let allowed: Set = ["name", "average", "level", "growth", "hourly"]
            if let unknown = field.keys.sorted().first(where: { !allowed.contains($0) }) {
                throw InvalidParameters(reason: "a stats-series field doesn't support \(unknown)")
            }
            guard let name = field["name"] as? String else {
                throw InvalidParameters(reason: "a stats-series field needs a name")
            }

            let value: Field.Value
            if let average = field["average"] as? Double {
                value = .average(average)
            } else if let level = field["level"] as? Double {
                value = .level(level, growth: field["growth"] as? Double ?? 0)
            } else {
                throw InvalidParameters(reason: "the stats-series field \(name) needs an average or a level")
            }
            parsed.append(Field(name: name, value: value, isHourly: field["hourly"] as? Bool ?? false))
        }
        self.fields = parsed
    }

    /// - Parameter now: The moment a `level` has its value.
    func body(for request: StubRequest, now: Date) -> String {
        let query = Dictionary(request.queryParameters.map { ($0.name, $0.value) }) { first, _ in first }
        let unit = Unit(rawValue: query["unit"] ?? query["period"] ?? "") ?? .day

        var rows: [[Any]] = []
        if let end = Self.date(from: query["date"]) {
            let start =
                Self.date(from: query["start_date"]) ?? unit.start(of: end, periods: Int(query["quantity"] ?? "") ?? 1)
            rows = unit.periods(from: start, to: end)
                .map { period in
                    [unit.label(for: period) as Any] + fields.map { value(of: $0, in: period, unit: unit, now: now) }
                }
        }

        let body: [String: Any] = [
            "date": query["date"] ?? "",
            "unit": unit.rawValue,
            "fields": ["period"] + fields.map(\.name),
            "data": rows
        ]
        return canonicalJSON(body).map { String(decoding: $0, as: UTF8.self) } ?? "{}"
    }

    // MARK: - Values

    private func value(of field: Field, in period: Date, unit: Unit, now: Date) -> Any {
        guard unit != .hour || field.isHourly else {
            return NSNull()
        }

        switch field.value {
        case .average(let average):
            if unit == .hour {
                let hour = Self.calendar.component(.hour, from: period)
                return Int(
                    (Self.dayValue(of: field.name, averaging: average, on: period) * Self.hourShares[hour]).rounded()
                )
            }
            return unit.days(in: period)
                .reduce(0) { $0 + Int(Self.dayValue(of: field.name, averaging: average, on: $1).rounded()) }
        case .level(let level, let growth):
            let lastDay = unit.days(in: period).last ?? period
            let today = Self.calendar.startOfDay(for: now)
            let daysAgo =
                Self.calendar.dateComponents([.day], from: Self.calendar.startOfDay(for: lastDay), to: today).day ?? 0
            return Int(level - growth * Double(daysAgo))
        }
    }

    /// What a field comes to on one day: its average, scaled by the day of the week and by an
    /// amount that depends only on the field and the date.
    private static func dayValue(of name: String, averaging average: Double, on date: Date) -> Double {
        let day = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: day)
        let dayNumber = Int(day.timeIntervalSince1970 / 86_400)

        // FNV-1a, for a number that looks random but is the same every time.
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in "\(name):\(dayNumber)".utf8 {
            hash = (hash ^ UInt64(byte)) &* 0x0000_0100_0000_01b3
        }
        let variation = 0.8 + 0.4 * Double(hash % 10_000) / 10_000

        return average * weekdayFactors[weekday - 1] * variation
    }

    /// Sunday to Saturday. Weekends are quieter.
    private static let weekdayFactors = [0.78, 1.04, 1.12, 1.15, 1.1, 1.0, 0.81]

    /// The share of a day's value that falls in each hour, from midnight. They add up to 1.
    private static let hourShares: [Double] = [
        0.012, 0.008, 0.006, 0.005, 0.006, 0.01, 0.02, 0.035, 0.05, 0.062, 0.068, 0.07,
        0.066, 0.064, 0.062, 0.06, 0.058, 0.057, 0.06, 0.064, 0.06, 0.047, 0.03, 0.02
    ]

    // MARK: - Dates

    /// Dates are read and written as they are in the request, without a time zone.
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        calendar.firstWeekday = 2
        return calendar
    }()

    private static func formatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = format
        return formatter
    }

    private static func date(from text: String?) -> Date? {
        guard let text else {
            return nil
        }
        return formatter("yyyy-MM-dd HH:mm:ss").date(from: text) ?? formatter("yyyy-MM-dd").date(from: text)
    }

    private enum Unit: String {
        case hour, day, week, month, year

        /// The most periods one response lists, whatever the request asks for.
        static let maximumPeriods = 1000

        var component: Calendar.Component {
            switch self {
            case .hour: .hour
            case .day: .day
            case .week: .weekOfYear
            case .month: .month
            case .year: .year
            }
        }

        /// The date `periods` periods before the one `end` is in, counting that one.
        func start(of end: Date, periods: Int) -> Date {
            StatsSeries.calendar.date(byAdding: component, value: -(max(periods, 1) - 1), to: end) ?? end
        }

        /// The start of every period from the one `start` is in to the one `end` is in.
        func periods(from start: Date, to end: Date) -> [Date] {
            let calendar = StatsSeries.calendar
            var periods: [Date] = []
            var period = calendar.dateInterval(of: component, for: start)?.start ?? start
            while period <= end, periods.count < Self.maximumPeriods {
                periods.append(period)
                guard let next = calendar.date(byAdding: component, value: 1, to: period) else {
                    break
                }
                period = next
            }
            return periods
        }

        /// The days of the period that starts on `period`.
        func days(in period: Date) -> [Date] {
            let calendar = StatsSeries.calendar
            guard self != .hour, self != .day, let end = calendar.date(byAdding: component, value: 1, to: period) else {
                return [period]
            }
            var days: [Date] = []
            var day = period
            while day < end {
                days.append(day)
                guard let next = calendar.date(byAdding: .day, value: 1, to: day) else {
                    break
                }
                day = next
            }
            return days
        }

        /// The period as WordPress.com writes it for this unit.
        func label(for period: Date) -> String {
            switch self {
            case .hour: StatsSeries.formatter("yyyy-MM-dd HH:mm:ss").string(from: period)
            case .week: StatsSeries.formatter("yyyy'W'MM'W'dd").string(from: period)
            case .day, .month, .year: StatsSeries.formatter("yyyy-MM-dd").string(from: period)
            }
        }
    }
}
#endif
