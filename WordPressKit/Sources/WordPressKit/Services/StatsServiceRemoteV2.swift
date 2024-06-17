import Foundation

// This name isn't great! After finishing the work on StatsRefresh we'll get rid of the "old"
// one and rename this to not have "V2" in it, but we want to keep the old one around
// for a while still.

open class StatsServiceRemoteV2: ServiceRemoteWordPressComREST {

    public enum ResponseError: Error {
        case decodingFailure
    }

    public enum MarkAsSpamResponseError: Error {
        case unsuccessful
    }

    public let siteID: Int
    private let siteTimezone: TimeZone

    private var periodDataQueryDateFormatter: DateFormatter {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd"
        return df
    }

    private lazy var calendarForSite: Calendar = {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = siteTimezone
        return cal
    }()

    public init(wordPressComRestApi api: WordPressComRestApi, siteID: Int, siteTimezone: TimeZone) {
        self.siteID = siteID
        self.siteTimezone = siteTimezone
        super.init(wordPressComRestApi: api)
    }

    /// Responsible for fetching Stats data for Insights — latest data about a site,
    /// in general — not considering a specific slice of time.
    /// For a possible set of returned types, see objects that conform to `StatsInsightData`.
    /// - parameters:
    ///   - limit: Limit of how many objects you want returned for your query. Default is `10`. `0` means no limit.
    public func getInsight<InsightType: StatsInsightData>(limit: Int = 10,
                                                          completion: @escaping ((InsightType?, Error?) -> Void)) {
        let properties = InsightType.queryProperties(with: limit) as [String: AnyObject]
        let pathComponent = InsightType.pathComponent

        let path = self.path(forEndpoint: "sites/\(siteID)/\(pathComponent)/", withVersion: ._1_1)

        wordPressComRESTAPI.get(path, parameters: properties, success: { (response, _) in
            guard
                let jsonResponse = response as? [String: AnyObject],
                let insight = InsightType(jsonDictionary: jsonResponse)
            else {
                completion(nil, ResponseError.decodingFailure)
                return
            }

            completion(insight, nil)
        }, failure: { (error, _) in
            completion(nil, error)
        })
    }

    /// Used to mark or unmark referrer as spam, depending of the current value.
    /// - parameters:
    ///   - referrerDomain: A referrer's domain.
    ///   - currentValue: Current value of the `isSpam` referrer's property.
    open func toggleSpamState(for referrerDomain: String,
                                currentValue: Bool,
                                success: @escaping () -> Void,
                                failure: @escaping (Error) -> Void) {
        let path = pathForToggleSpamStateEndpoint(referrerDomain: referrerDomain, markAsSpam: !currentValue)
        wordPressComRESTAPI.post(path, parameters: nil, success: { object, _ in
            guard
                let dictionary = object as? [String: AnyObject],
                let response = MarkAsSpamResponse(dictionary: dictionary) else {
                failure(ResponseError.decodingFailure)
                return
            }

            guard response.success else {
                failure(MarkAsSpamResponseError.unsuccessful)
                return
            }

            success()
        }, failure: { error, _ in
            failure(error)
        })
    }

    /// Used to fetch data about site over a specific timeframe.
    /// - parameters:
    ///   - period: An enum representing whether either a day, a week, a month or a year worth's of data.
    ///   - unit: An enum representing whether the data is retuned in a day, a week, a month or a year granularity. Default is `period`.
    ///   - endingOn: Date on which the `period` for which data you're interested in **is ending**.
    ///    e.g. if you want data spanning 11-17 Feb 2019, you should pass in a period of `.week` and an
    ///    ending date of `Feb 17 2019`.
    ///   - limit: Limit of how many objects you want returned for your query. Default is `10`. `0` means no limit.
    public func getData<TimeStatsType: StatsTimeIntervalData>(for period: StatsPeriodUnit,
                                                              unit: StatsPeriodUnit? = nil,
                                                              endingOn: Date,
                                                              limit: Int = 10,
                                                              completion: @escaping ((TimeStatsType?, Error?) -> Void)) {
        let pathComponent = TimeStatsType.pathComponent
        let path = self.path(forEndpoint: "sites/\(siteID)/\(pathComponent)/", withVersion: ._1_1)

        let staticProperties = ["period": period.stringValue,
                                "unit": unit?.stringValue ?? period.stringValue,
                                "date": periodDataQueryDateFormatter.string(from: endingOn)] as [String: AnyObject]

        let classProperties = TimeStatsType.queryProperties(with: endingOn, period: unit ?? period, maxCount: limit) as [String: AnyObject]

        let properties = staticProperties.merging(classProperties) { val1, _ in
            return val1
        }

        wordPressComRESTAPI.get(path, parameters: properties, success: { [weak self] (response, _) in
            guard
                let self,
                let jsonResponse = response as? [String: AnyObject],
                let dateString = jsonResponse["date"] as? String,
                let date = self.periodDataQueryDateFormatter.date(from: dateString)
                else {
                    completion(nil, ResponseError.decodingFailure)
                    return
            }

            let periodString = jsonResponse["period"] as? String
            let unitString = jsonResponse["unit"] as? String
            let parsedPeriod = periodString.flatMap { StatsPeriodUnit(string: $0) } ?? period
            let parsedUnit = unitString.flatMap { StatsPeriodUnit(string: $0) } ?? unit ?? period
            // some responses omit this field!  not a reason to fail a whole request parsing though.

            guard
                let timestats = TimeStatsType(date: date,
                                              period: parsedPeriod,
                                              unit: parsedUnit,
                                              jsonDictionary: jsonResponse)
                else {
                    completion(nil, ResponseError.decodingFailure)
                    return
            }

            completion(timestats, nil)
        }, failure: { (error, _) in
            completion(nil, error)
        })
    }

    public func getDetails(forPostID postID: Int, completion: @escaping ((StatsPostDetails?, Error?) -> Void)) {
        let path = self.path(forEndpoint: "sites/\(siteID)/stats/post/\(postID)/", withVersion: ._1_1)

        wordPressComRESTAPI.get(path, parameters: [:], success: { (response, _) in
            guard
                let jsonResponse = response as? [String: AnyObject],
                let postDetails = StatsPostDetails(jsonDictionary: jsonResponse)
                else {
                    completion(nil, ResponseError.decodingFailure)
                    return
            }

            completion(postDetails, nil)
        }, failure: { (error, _) in
            completion(nil, error)
        })
    }
}

// MARK: - StatsLastPostInsight Handling

extension StatsServiceRemoteV2 {
    // "Last Post" Insights are "fun" in the way that they require multiple requests to actually create them,
    // so we do this "fun" dance in a separate method.
    public func getInsight(limit: Int = 10, completion: @escaping ((StatsLastPostInsight?, Error?) -> Void)) {
         getLastPostInsight(completion: completion)
    }

    private func getLastPostInsight(limit: Int = 10, completion: @escaping ((StatsLastPostInsight?, Error?) -> Void)) {
        let properties = StatsLastPostInsight.queryProperties(with: limit) as [String: AnyObject]
        let pathComponent = StatsLastPostInsight.pathComponent
        let path = self.path(forEndpoint: "sites/\(siteID)/\(pathComponent)", withVersion: ._1_1)

        wordPressComRESTAPI.get(path, parameters: properties, success: { (response, _) in
            guard let jsonResponse = response as? [String: AnyObject],
                  let postCount = jsonResponse["found"] as? Int else {
                completion(nil, ResponseError.decodingFailure)
                return
            }

            guard postCount > 0 else {
                completion(nil, nil)
                return
            }

            guard
                let posts = jsonResponse["posts"] as? [[String: AnyObject]],
                let post = posts.first,
                let postID = post["ID"] as? Int else {
                    completion(nil, ResponseError.decodingFailure)
                    return
            }

            self.getPostViews(for: postID) { (views, _) in
                guard
                    let views = views,
                    let insight = StatsLastPostInsight(jsonDictionary: post, views: views) else {
                        completion(nil, ResponseError.decodingFailure)
                        return

                }

                completion(insight, nil)
            }
        }, failure: {(error, _) in
            completion(nil, error)
        })
    }

    private func getPostViews(`for` postID: Int, completion: @escaping ((Int?, Error?) -> Void)) {
        let parameters = ["fields": "views" as AnyObject]

        let path = self.path(forEndpoint: "sites/\(siteID)/stats/post/\(postID)", withVersion: ._1_1)

        wordPressComRESTAPI.get(path,
                                parameters: parameters,
                                success: { (response, _) in
                                    guard
                                        let jsonResponse = response as? [String: AnyObject],
                                        let views = jsonResponse["views"] as? Int else {
                                            completion(nil, ResponseError.decodingFailure)
                                            return
                                    }
                                    completion(views, nil)
                                }, failure: { (error, _) in
                                    completion(nil, error)
                                }
        )
    }
}

// MARK: - StatsPublishedPostsTimeIntervalData Handling

extension StatsServiceRemoteV2 {

    // StatsPublishedPostsTimeIntervalData hit a different endpoint and with different parameters
    // then the rest of the time-based types — we need to handle them separately here.
    public func getData(for period: StatsPeriodUnit,
                        endingOn: Date,
                        limit: Int = 10,
                        completion: @escaping ((StatsPublishedPostsTimeIntervalData?, Error?) -> Void)) {
        let pathComponent = StatsLastPostInsight.pathComponent
        let path = self.path(forEndpoint: "sites/\(siteID)/\(pathComponent)", withVersion: ._1_1)

        let properties = ["number": limit,
                          "fields": "ID, title, URL",
                          "after": ISO8601DateFormatter().string(from: startDate(for: period, endDate: endingOn)),
                          "before": ISO8601DateFormatter().string(from: endingOn)] as [String: AnyObject]

        wordPressComRESTAPI.get(path,
                                parameters: properties,
                                success: { (response, _) in
                                    guard
                                        let jsonResponse = response as? [String: AnyObject],
                                        let response = StatsPublishedPostsTimeIntervalData(date: endingOn, period: period, unit: nil, jsonDictionary: jsonResponse) else {
                                            completion(nil, ResponseError.decodingFailure)
                                            return
                                    }
                                    completion(response, nil)
                                }, failure: { (error, _) in
                                    completion(nil, error)
                                }
            )
    }

    private func startDate(for period: StatsPeriodUnit, endDate: Date) -> Date {
        switch  period {
        case .day:
            return calendarForSite.startOfDay(for: endDate)
        case .week:
            let weekAgo = calendarForSite.date(byAdding: .day, value: -6, to: endDate)!
            return calendarForSite.startOfDay(for: weekAgo)
        case .month:
            let monthAgo = calendarForSite.date(byAdding: .month, value: -1, to: endDate)!
            let firstOfMonth = calendarForSite.date(bySetting: .day, value: 1, of: monthAgo)!
            return calendarForSite.startOfDay(for: firstOfMonth)
        case .year:
            let yearAgo = calendarForSite.date(byAdding: .year, value: -1, to: endDate)!
            let january = calendarForSite.date(bySetting: .month, value: 1, of: yearAgo)!
            let jan1 = calendarForSite.date(bySetting: .day, value: 1, of: january)!
            return calendarForSite.startOfDay(for: jan1)
        }
    }

}

// MARK: - Mark referrer as spam helpers

private extension StatsServiceRemoteV2 {
    func pathForToggleSpamStateEndpoint(referrerDomain: String, markAsSpam: Bool) -> String {
        let action = markAsSpam ? "new" : "delete"
        return self.path(forEndpoint: "sites/\(siteID)/stats/referrers/spam/\(action)?domain=\(referrerDomain)", withVersion: ._1_1)
    }

    struct MarkAsSpamResponse {
        let success: Bool

        init?(dictionary: [String: AnyObject]) {
            guard let value = dictionary["success"] as? Bool else {
                return nil
            }
            self.success = value
        }
    }
}

// MARK: - Emails Summary

public extension StatsServiceRemoteV2 {
    func getData(quantity: Int,
                 sortField: StatsEmailsSummaryData.SortField = .opens,
                 sortOrder: StatsEmailsSummaryData.SortOrder = .descending,
                 completion: @escaping ((Result<StatsEmailsSummaryData, Error>) -> Void)) {
        let pathComponent = StatsEmailsSummaryData.pathComponent
        let path = self.path(forEndpoint: "sites/\(siteID)/\(pathComponent)/", withVersion: ._1_1)
        let properties = StatsEmailsSummaryData.queryProperties(quantity: quantity, sortField: sortField, sortOrder: sortOrder) as [String: AnyObject]

        wordPressComRESTAPI.get(path, parameters: properties, success: { (response, _) in
            guard let jsonResponse = response as? [String: AnyObject],
                  let emailsSummaryData = StatsEmailsSummaryData(jsonDictionary: jsonResponse)
            else {
                completion(.failure(ResponseError.decodingFailure))
                return
            }

            completion(.success(emailsSummaryData))
        }, failure: { (error, _) in
            completion(.failure(error))
        })
    }
}

// This serves both as a way to get the query properties in a "nice" way,
// but also as a way to narrow down the generic type in `getInsight(completion:)` method.
public protocol StatsInsightData {
    static func queryProperties(with maxCount: Int) -> [String: String]
    static var pathComponent: String { get }

    init?(jsonDictionary: [String: AnyObject])
}

public protocol StatsTimeIntervalData {
    static var pathComponent: String { get }

    var period: StatsPeriodUnit { get }
    var unit: StatsPeriodUnit? { get }
    var periodEndDate: Date { get }

    init?(date: Date, period: StatsPeriodUnit, jsonDictionary: [String: AnyObject])
    init?(date: Date, period: StatsPeriodUnit, unit: StatsPeriodUnit?, jsonDictionary: [String: AnyObject])

    static func queryProperties(with date: Date, period: StatsPeriodUnit, maxCount: Int) -> [String: String]
}

extension StatsTimeIntervalData {

    public var unit: StatsPeriodUnit? {
        return nil
    }

    public static func queryProperties(with date: Date, period: StatsPeriodUnit, maxCount: Int) -> [String: String] {
        return ["max": String(maxCount)]
    }

    public init?(date: Date, period: StatsPeriodUnit, unit: StatsPeriodUnit?, jsonDictionary: [String: AnyObject]) {
        self.init(date: date, period: period, jsonDictionary: jsonDictionary)
    }

    // Most of the responses for time data come in a unwieldy format, that requires awkwkard unwrapping
    // at the call-site — unfortunately not _all of them_, which means we can't just do it at the request level.
    static func unwrapDaysDictionary(jsonDictionary: [String: AnyObject]) -> [String: AnyObject]? {
        guard
            let days = jsonDictionary["days"] as? [String: AnyObject],
            let firstKey = days.keys.first,
            let firstDay = days[firstKey] as? [String: AnyObject]
            else {
                return nil
        }
        return firstDay
    }

}

// We'll bring `StatsPeriodUnit` into this file when the "old" `WPStatsServiceRemote` gets removed.
// For now we can piggy-back off the old type and add this as an extension.
public extension StatsPeriodUnit {
    var stringValue: String {
        switch self {
        case .day:
            return "day"
        case .week:
            return "week"
        case .month:
            return "month"
        case .year:
            return "year"
        }
    }

    init?(string: String) {
        switch string {
        case "day":
            self = .day
        case "week":
            self = .week
        case "month":
            self = .month
        case "year":
            self = .year
        default:
            return nil
        }
    }
}

extension StatsInsightData {

    // A big chunk of those use the same endpoint and queryProperties.. Let's simplify the protocol conformance in those cases.

    public static func queryProperties(with maxCount: Int) -> [String: String] {
        return ["max": String(maxCount)]
    }

    public static var pathComponent: String {
        return "stats/"
    }
}

public extension StatsInsightData where Self: Codable {
    init?(jsonDictionary: [String: AnyObject]) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonDictionary, options: [])
            let decoder = JSONDecoder()
            self = try decoder.decode(Self.self, from: jsonData)
        } catch {
            return nil
        }
    }
}
