import SFHFKeychainUtils
import WordPressKit
import JetpackStatsWidgetsCore
import WordPressShared

/// Type that wraps the backend request for new stats
class StatsWidgetsService {
    private var service: StatsServiceRemoteV2?

    typealias ResultType = HomeWidgetData

    private enum State {
        case loading
        case ready
        case error

        var isLoading: Bool {
            switch self {
            case .loading:
                return true
            case .error, .ready:
                return false
            }
        }
    }

    private var state: State = .ready

    func fetchStats(for widgetData: HomeWidgetData,
                    completion: @escaping (Result<ResultType, Error>) -> Void) {

        guard !state.isLoading else {
            return
        }
        state = .loading

        // handle fetching depending on concrete type
        // we need to do like this as there is no unique service call
        if let widgetData = widgetData as? HomeWidgetTodayData {
            fetchTodayStats(widgetData: widgetData, completion: completion)
        } else if let widgetData = widgetData as? HomeWidgetAllTimeData {
            fetchAllTimeStats(widgetData: widgetData, completion: completion)
        } else if let widgetData = widgetData as? HomeWidgetThisWeekData {
            fetchThisWeekStats(widgetData: widgetData, completion: completion)
        }
    }

    private func fetchTodayStats(widgetData: HomeWidgetTodayData,
                                 completion: @escaping (Result<ResultType, Error>) -> Void) {

        getInsight(widgetData: widgetData) { [weak self] (insight: StatsTodayInsight?, error) in
            guard let self else {
                return
            }

            if let error {
                completion(.failure(error))
                self.state = .error
                return
            }

            guard let insight else {
                completion(.failure(StatsWidgetsError.nilStats))
                self.state = .error
                return
            }

            let newWidgetData = HomeWidgetTodayData(siteID: widgetData.siteID,
                                                    siteName: widgetData.siteName,
                                                    url: widgetData.url,
                                                    timeZone: widgetData.timeZone,
                                                    date: Date(),
                                                    stats: TodayWidgetStats(views: insight.viewsCount,
                                                                            visitors: insight.visitorsCount,
                                                                            likes: insight.likesCount,
                                                                            comments: insight.commentsCount))
            completion(.success(newWidgetData))
            DispatchQueue.main.async {
                // update the item in the local cache
                HomeWidgetTodayData.setItem(item: newWidgetData)
            }
            self.state = .ready
        }
    }

    private func fetchAllTimeStats(widgetData: HomeWidgetAllTimeData,
                                   completion: @escaping (Result<ResultType, Error>) -> Void) {

        getInsight(widgetData: widgetData) { [weak self] (insight: StatsAllTimesInsight?, error) in

            guard let self else {
                return
            }

            if let error {
                completion(.failure(error))
                self.state = .error
                return
            }

            let newWidgetData = HomeWidgetAllTimeData(siteID: widgetData.siteID,
                                                      siteName: widgetData.siteName,
                                                      url: widgetData.url,
                                                      timeZone: widgetData.timeZone,
                                                      date: Date(),
                                                      stats: AllTimeWidgetStats(views:
                                                                                    insight?.viewsCount,
                                                                                visitors: insight?.visitorsCount,
                                                                                posts: insight?.postsCount,
                                                                                bestViews: insight?.bestViewsPerDayCount))
            completion(.success(newWidgetData))
            DispatchQueue.main.async {
                // update the item in the local cache
                HomeWidgetAllTimeData.setItem(item: newWidgetData)
            }
            self.state = .ready
        }
    }

    private func fetchThisWeekStats(widgetData: HomeWidgetThisWeekData,
                                    completion: @escaping (Result<ResultType, Error>) -> Void) {

        // Get the current date in the site's time zone.
        let siteTimeZone = widgetData.timeZone
        let weekEndingDate = Date().convert(from: siteTimeZone).normalizedDate()

        // Include an extra day. It's needed to get the dailyChange for the last day.
        getData(widgetData: widgetData,
                for: .day,
                endingOn: weekEndingDate,
                limit: ThisWeekWidgetStats.maxDaysToDisplay + 1) { [weak self] (summary: StatsSummaryTimeIntervalData?, error: Error?) in

            guard let self else {
                return
            }

            if let error {
                DDLogError("This Week Widget: Error fetching summary: \(String(describing: error.localizedDescription))")
                completion(.failure(error))
                self.state = .error
                return
            }

            let summaryData = summary?.summaryData.reversed() ?? []
            let newWidgetData = HomeWidgetThisWeekData(
                siteID: widgetData.siteID,
                siteName: widgetData.siteName,
                url: widgetData.url,
                timeZone: widgetData.timeZone,
                date: Date(),
                stats: ThisWeekWidgetStats(
                    days: ThisWeekWidgetStats.daysFrom(
                        summaryData: summaryData.map {
                            ThisWeekWidgetStats.Input(
                                periodStartDate: $0.periodStartDate,
                                viewsCount: $0.viewsCount)
                        }
                    )
                )
            )
            completion(.success(newWidgetData))

            DispatchQueue.global().async {
                HomeWidgetThisWeekData.setItem(item: newWidgetData)
            }
            self.state = .ready
        }
    }
}

enum StatsWidgetsError: Error {
    case nilStats
}

private extension Date {
    func convert(from timeZone: TimeZone, comparedWith target: TimeZone = TimeZone.current) -> Date {
        let delta = TimeInterval(timeZone.secondsFromGMT(for: self) - target.secondsFromGMT(for: self))
        return addingTimeInterval(delta)
    }
}

private extension StatsWidgetsService {
    private func getInsight<InsightType: StatsInsightData>(
        widgetData: HomeWidgetData,
        limit: Int = 10,
        completion: @escaping ((InsightType?, Error?) -> Void)
    ) {
        do {
            self.service = try createStatsService(for: widgetData)
            self.service?.getInsight(limit: limit, completion: { [weak self] in
                completion($0, $1)
                self?.service = nil
            })
        } catch {
            completion(nil, error)
            self.state = .error
        }
    }

    private func getData<TimeStatsType: StatsTimeIntervalData>(
        widgetData: HomeWidgetData,
        for period: StatsPeriodUnit,
        unit: StatsPeriodUnit? = nil,
        endingOn: Date,
        limit: Int = 10,
        completion: @escaping ((TimeStatsType?, Error?) -> Void)
    ) {
        do {
            self.service = try createStatsService(for: widgetData)
            self.service?.getData(for: period, unit: unit, endingOn: endingOn, limit: limit, completion: { [weak self] in
                completion($0, $1)
                self?.service = nil
            })
        } catch {
            completion(nil, error)
            self.state = .error
        }
    }

    private func createStatsService(for widgetData: HomeWidgetData) throws -> StatsServiceRemoteV2 {
        let token = try SFHFKeychainUtils.getPasswordForUsername(
            AppConfiguration.Widget.Stats.keychainTokenKey,
            andServiceName: AppConfiguration.Widget.Stats.keychainServiceName,
            accessGroup: WPAppKeychainAccessGroup
        )
        let wpApi = WordPressComRestApi(oAuthToken: token)
        return StatsServiceRemoteV2(wordPressComRestApi: wpApi, siteID: widgetData.siteID, siteTimezone: widgetData.timeZone)
    }
}
