public enum StatsPeriodUnit: Int {
    case day
    case week
    case month
    case year
}

public enum StatsSummaryType: Int {
    case views
    case visitors
    case likes
    case comments
}

public struct StatsSummaryTimeIntervalData {
    public let period: StatsPeriodUnit
    public let unit: StatsPeriodUnit?
    public let periodEndDate: Date

    public let summaryData: [StatsSummaryData]

    public init(period: StatsPeriodUnit,
                unit: StatsPeriodUnit?,
                periodEndDate: Date,
                summaryData: [StatsSummaryData]) {
        self.period = period
        self.unit = unit
        self.periodEndDate = periodEndDate
        self.summaryData = summaryData
    }
}

public struct StatsSummaryData {
    public let period: StatsPeriodUnit
    public let periodStartDate: Date

    public let viewsCount: Int
    public let visitorsCount: Int
    public let likesCount: Int
    public let commentsCount: Int

    public init(period: StatsPeriodUnit,
                periodStartDate: Date,
                viewsCount: Int,
                visitorsCount: Int,
                likesCount: Int,
                commentsCount: Int) {
        self.period = period
        self.periodStartDate = periodStartDate
        self.viewsCount = viewsCount
        self.visitorsCount = visitorsCount
        self.likesCount = likesCount
        self.commentsCount = commentsCount
    }
}

extension StatsSummaryTimeIntervalData: StatsTimeIntervalData {
    public static var pathComponent: String {
        return "stats/visits"
    }

    public static func queryProperties(with date: Date, period: StatsPeriodUnit, maxCount: Int) -> [String: String] {
        return ["unit": period.stringValue,
                "quantity": String(maxCount),
                "stat_fields": "views,visitors,comments,likes"]
    }

    public init?(date: Date, period: StatsPeriodUnit, jsonDictionary: [String: AnyObject]) {
        self.init(date: date, period: period, unit: nil, jsonDictionary: jsonDictionary)
    }

    public init?(date: Date, period: StatsPeriodUnit, unit: StatsPeriodUnit?, jsonDictionary: [String: AnyObject]) {
        guard
            let fieldsArray = jsonDictionary["fields"] as? [String],
            let data = jsonDictionary["data"] as? [[Any]]
            else {
                return nil
        }

        // The shape of data for this response is somewhat unconventional.
        // (you might want to take a peek at included tests fixtures files `stats-visits-*.json`)
        // There's a `fields` arrray with strings that correspond to requested properties
        // (e.g. something like ["period", "views", "visitors"].
        // The actual data we're after is then contained in the `data`... array of arrays?
        // The "inner" arrays contain multiple entries, whose indexes correspond to
        // the positions of the appropriate keys in the `fields` array, so in our example the array looks something like this:
        // [["2019-01-01", 9001, 1234], ["2019-02-01", 1234, 1234]], where the first object in the "inner" array
        // is the `period`, second is `views`, etc.

        guard
            let periodIndex = fieldsArray.firstIndex(of: "period"),
            let viewsIndex = fieldsArray.firstIndex(of: "views"),
            let visitorsIndex = fieldsArray.firstIndex(of: "visitors"),
            let commentsIndex = fieldsArray.firstIndex(of: "comments"),
            let likesIndex = fieldsArray.firstIndex(of: "likes")
            else {
                return nil
        }

        self.period = period
        self.unit = unit
        self.periodEndDate = date
        self.summaryData = data.compactMap { StatsSummaryData(dataArray: $0,
                                                              period: unit ?? period,
                                                              periodIndex: periodIndex,
                                                              viewsIndex: viewsIndex,
                                                              visitorsIndex: visitorsIndex,
                                                              likesIndex: likesIndex,
                                                              commentsIndex: commentsIndex) }
    }
}

private extension StatsSummaryData {
    init?(dataArray: [Any],
          period: StatsPeriodUnit,
          periodIndex: Int,
          viewsIndex: Int?,
          visitorsIndex: Int?,
          likesIndex: Int?,
          commentsIndex: Int?) {

        guard
            let periodString = dataArray[periodIndex] as? String,
            let periodStart = type(of: self).parsedDate(from: periodString, for: period) else {
                return nil
        }

        let viewsCount: Int
        let visitorsCount: Int
        let likesCount: Int
        let commentsCount: Int

        if let viewsIndex = viewsIndex {
            guard let count = dataArray[viewsIndex] as? Int else {
                return nil
            }
            viewsCount = count
        } else {
            viewsCount = 0
        }

        if let visitorsIndex = visitorsIndex {
            guard let count = dataArray[visitorsIndex] as? Int else {
                return nil
            }
            visitorsCount = count
        } else {
            visitorsCount = 0
        }

        if let likesIndex = likesIndex {
            guard let count = dataArray[likesIndex] as? Int else {
                return nil
            }
            likesCount = count
        } else {
            likesCount = 0
        }

        if let commentsIndex = commentsIndex {
            guard let count = dataArray[commentsIndex] as? Int else {
                return nil
            }
            commentsCount = count
        } else {
            commentsCount = 0
        }

        self.period = period
        self.periodStartDate = periodStart

        self.viewsCount = viewsCount
        self.visitorsCount = visitorsCount
        self.likesCount = likesCount
        self.commentsCount = commentsCount
    }

    static func parsedDate(from dateString: String, for period: StatsPeriodUnit) -> Date? {
        switch period {
        case .week:
            return self.weeksDateFormatter.date(from: dateString)
        case .day, .month, .year:
            return self.regularDateFormatter.date(from: dateString)
        }
    }

    static var regularDateFormatter: DateFormatter {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POS")
        df.dateFormat = "yyyy-MM-dd"
        return df
    }

    // We have our own handrolled date format for data broken up on week basis.
    // Example dates in this format are `2019W02W18` or `2019W02W11`.
    // The structure is `aaaaWbbWcc`, where:
    // - `aaaa` is four-digit year number,
    // - `bb` is two-digit month number
    // - `cc` is two-digit day number
    // Note that in contrast to almost every other date used in Stats, those dates
    // represent the _beginning_ of the period they're applying to, e.g.
    // data set for `2019W02W18` is containing data for the period of Feb 18 - Feb 24 2019.
    private static var weeksDateFormatter: DateFormatter {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POS")
        df.dateFormat = "yyyy'W'MM'W'dd"
        return df
    }
}

/// So this is very awkward and neccessiated by our API. Turns out, calculating likes
/// for long periods of times (months/years) on large sites takes _ages_ (up to a minute sometimes).
/// Thankfully, calculating views/visitors/comments takes a much shorter time. (~2s, which is still suuuuuper long, but acceptable.)
/// We don't want to wait a whole minute to display the rest of the data, so we fetch the likes separately.
public struct StatsLikesSummaryTimeIntervalData {

    public let period: StatsPeriodUnit
    public let periodEndDate: Date

    public let summaryData: [StatsSummaryData]

    public init(period: StatsPeriodUnit,
                periodEndDate: Date,
                summaryData: [StatsSummaryData]) {
        self.period = period
        self.periodEndDate = periodEndDate
        self.summaryData = summaryData
    }
}

extension StatsLikesSummaryTimeIntervalData: StatsTimeIntervalData {

    public static var pathComponent: String {
        return "stats/visits"
    }

    public static func queryProperties(with date: Date, period: StatsPeriodUnit, maxCount: Int) -> [String: String] {
        return ["unit": period.stringValue,
                "quantity": String(maxCount),
                "stat_fields": "likes"]
    }

    public init?(date: Date, period: StatsPeriodUnit, jsonDictionary: [String: AnyObject]) {
        self.init(date: date, period: period, unit: nil, jsonDictionary: jsonDictionary)
    }

    public init?(date: Date, period: StatsPeriodUnit, unit: StatsPeriodUnit?, jsonDictionary: [String: AnyObject]) {
        guard
            let fieldsArray = jsonDictionary["fields"] as? [String],
            let data = jsonDictionary["data"] as? [[Any]]
            else {
                return nil
        }

        guard
            let periodIndex = fieldsArray.firstIndex(of: "period"),
            let likesIndex = fieldsArray.firstIndex(of: "likes") else {
                return nil
        }

        self.period = period
        self.periodEndDate = date
        self.summaryData = data.compactMap { StatsSummaryData(dataArray: $0,
                                                              period: unit ?? period,
                                                              periodIndex: periodIndex,
                                                              viewsIndex: nil,
                                                              visitorsIndex: nil,
                                                              likesIndex: likesIndex,
                                                              commentsIndex: nil) }
    }
}
