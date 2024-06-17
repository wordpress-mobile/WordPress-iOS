import Foundation
import WordPressShared

public struct StatsSubscribersSummaryData: Equatable {
    public let history: [SubscriberData]
    public let period: StatsPeriodUnit
    public let periodEndDate: Date

    public init(history: [SubscriberData], period: StatsPeriodUnit, periodEndDate: Date) {
        self.history = history
        self.period = period
        self.periodEndDate = periodEndDate
    }
}

extension StatsSubscribersSummaryData: StatsTimeIntervalData {
    public static var pathComponent: String {
        return "stats/subscribers"
    }

    static var dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POS")
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()

    static var weeksDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POS")
        df.dateFormat = "yyyy'W'MM'W'dd"
        return df
    }()

    public struct SubscriberData: Equatable {
        public let date: Date
        public let count: Int

        public init(date: Date, count: Int) {
            self.date = date
            self.count = count
        }
    }

    public init?(date: Date, period: StatsPeriodUnit, jsonDictionary: [String: AnyObject]) {
        guard
            let fields = jsonDictionary["fields"] as? [String],
            let data = jsonDictionary["data"] as? [[Any]],
            let dateIndex = fields.firstIndex(of: "period"),
            let countIndex = fields.firstIndex(of: "subscribers")
        else {
            return nil
        }

        let history: [SubscriberData?] = data.map { elements in
            guard elements.indices.contains(dateIndex) && elements.indices.contains(countIndex),
                  let dateString = elements[dateIndex] as? String,
                  let date = StatsSubscribersSummaryData.parsedDate(from: dateString, for: period)
            else {
                return nil
            }

            let count = elements[countIndex] as? Int ?? 0

            return SubscriberData(date: date, count: count)
        }

        let sorted = history.compactMap { $0 }.sorted { $0.date < $1.date }

        self = .init(history: sorted, period: period, periodEndDate: date)
    }

    private static func parsedDate(from dateString: String, for period: StatsPeriodUnit) -> Date? {
        switch period {
        case .week:
            return self.weeksDateFormatter.date(from: dateString)
        case .day, .month, .year:
            return self.dateFormatter.date(from: dateString)
        }
    }

    public static func queryProperties(with date: Date, period: StatsPeriodUnit, maxCount: Int) -> [String: String] {
        return ["quantity": String(maxCount), "unit": period.stringValue]
    }
}
