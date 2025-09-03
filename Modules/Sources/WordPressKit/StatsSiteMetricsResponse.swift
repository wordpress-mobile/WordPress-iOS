import Foundation

public struct StatsSiteMetricsResponse {
    public var period: StatsPeriodUnit
    public var periodEndDate: Date
    public let data: [PeriodData]

    public enum Metric: String, CaseIterable {
        case views
        case visitors
        case likes
        case comments
        case posts
    }

    public struct PeriodData {
        /// Periods date in the site timezone.
        public var date: Date
        public var views: Int?
        public var visitors: Int?
        public var likes: Int?
        public var comments: Int?
        public var posts: Int?

        public subscript(metric: Metric) -> Int? {
            switch metric {
            case .views: views
            case .visitors: visitors
            case .likes: likes
            case .comments: comments
            case .posts: posts
            }
        }
    }
}

extension StatsSiteMetricsResponse: StatsTimeIntervalData {
    public static var pathComponent: String {
        "stats/visits"
    }

    public static func queryProperties(with date: Date, period: StatsPeriodUnit, maxCount: Int) -> [String: String] {
        return [
            "unit": period.stringValue,
            "quantity": String(maxCount),
            "stat_fields": Metric.allCases.map(\.rawValue).joined(separator: ",")
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
            views: fields.firstIndex(of: Metric.views.rawValue),
            visitors: fields.firstIndex(of: Metric.visitors.rawValue),
            likes: fields.firstIndex(of: Metric.likes.rawValue),
            comments: fields.firstIndex(of: Metric.comments.rawValue),
            posts: fields.firstIndex(of: Metric.posts.rawValue)
        )

        let dateFormatter = makeDateFormatter(for: period)

        self.data = data.compactMap { data in
            guard let date = dateFormatter.date(from: data[periodIndex] as? String ?? "") else {
                return nil
            }
            func getValue(at index: Int?) -> Int? {
                guard let index else { return nil }
                return data[index] as? Int
            }
            return PeriodData(
                date: date,
                views: getValue(at: indices.views),
                visitors: getValue(at: indices.visitors),
                likes: getValue(at: indices.likes),
                comments: getValue(at: indices.comments),
                posts: getValue(at: indices.posts)
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
        case .week: "yyyy'W'MM'W'dd"
        case .day, .month, .year: "yyyy-MM-dd"
        }
    }()
    return formatter
}
