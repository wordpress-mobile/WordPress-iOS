import Foundation

public struct StatsWordAdsResponse {
    public var period: StatsPeriodUnit
    public var periodEndDate: Date
    public let data: [PeriodData]

    public enum Metric: String, CaseIterable {
        case impressions
        case revenue
        case cpm
    }

    public struct PeriodData {
        /// Period date in the site timezone.
        public var date: Date
        public var impressions: Int?
        public var revenue: Double?
        public var cpm: Double?

        public subscript(metric: Metric) -> Double? {
            switch metric {
            case .impressions: impressions.map(Double.init)
            case .revenue: revenue
            case .cpm: cpm
            }
        }
    }
}

extension StatsWordAdsResponse: StatsTimeIntervalData {
    public static var pathComponent: String {
        "wordads/stats"
    }

    public static func queryProperties(with date: Date, period: StatsPeriodUnit, maxCount: Int) -> [String: String] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        let dateString = dateFormatter.string(from: date)

        return [
            "unit": period.stringValue,
            "date": dateString,
            "quantity": String(maxCount)
        ]
    }

    public init?(date: Date, period: StatsPeriodUnit, jsonDictionary: [String: AnyObject]) {
        self.init(date: date, period: period, unit: nil, jsonDictionary: jsonDictionary)
    }

    public init?(date: Date, period: StatsPeriodUnit, unit: StatsPeriodUnit?, jsonDictionary: [String: AnyObject]) {
        guard let fields = jsonDictionary["fields"] as? [String],
              let data = jsonDictionary["data"] as? [[Any]] else {
            return nil
        }

        guard let periodIndex = fields.firstIndex(of: "period") else {
            return nil
        }

        self.period = period
        self.periodEndDate = date

        let indices = (
            impressions: fields.firstIndex(of: Metric.impressions.rawValue),
            revenue: fields.firstIndex(of: Metric.revenue.rawValue),
            cpm: fields.firstIndex(of: Metric.cpm.rawValue)
        )

        let dateFormatter = makeDateFormatter(for: period)

        self.data = data.compactMap { data in
            guard let date = dateFormatter.date(from: data[periodIndex] as? String ?? "") else {
                return nil
            }

            func getIntValue(at index: Int?) -> Int? {
                guard let index else { return nil }
                return data[index] as? Int
            }

            func getDoubleValue(at index: Int?) -> Double? {
                guard let index else { return nil }
                if let doubleValue = data[index] as? Double {
                    return doubleValue
                } else if let intValue = data[index] as? Int {
                    return Double(intValue)
                }
                return nil
            }

            return PeriodData(
                date: date,
                impressions: getIntValue(at: indices.impressions),
                revenue: getDoubleValue(at: indices.revenue),
                cpm: getDoubleValue(at: indices.cpm)
            )
        }
    }
}

private func makeDateFormatter(for unit: StatsPeriodUnit) -> DateFormatter {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = {
        switch unit {
        case .hour: "yyyy-MM-dd HH:mm:ss"
        case .day, .week, .month, .year: "yyyy-MM-dd"
        }
    }()
    return formatter
}
