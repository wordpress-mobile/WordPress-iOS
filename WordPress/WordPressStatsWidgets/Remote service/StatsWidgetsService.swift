import WordPressKit

/// Type that wraps the backend request for new stats
class StatsWidgetsService {

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
                    completion: @escaping (Result<HomeWidgetData, Error>) -> Void) {

        guard !state.isLoading else {
            return
        }
        state = .loading

        do {
            let token = try SFHFKeychainUtils.getPasswordForUsername(WPStatsTodayWidgetKeychainTokenKey,
                                                                     andServiceName: WPStatsTodayWidgetKeychainServiceName,
                                                                     accessGroup: WPAppKeychainAccessGroup)

            let wpApi = WordPressComRestApi(oAuthToken: token)
            let service = StatsServiceRemoteV2(wordPressComRestApi: wpApi, siteID: widgetData.siteID, siteTimezone: widgetData.timeZone)

            // handle fetching depending on concrete type
            // we need to do like this as there is no unique service call
            if let widgetData = widgetData as? HomeWidgetTodayData {
                fetchTodayStats(service: service, widgetData: widgetData, completion: completion)
            } else if let widgetData = widgetData as? HomeWidgetAllTimeData {
                fetchAllTimeStats(service: service, widgetData: widgetData, completion: completion)
            } else if let widgetData = widgetData as? HomeWidgetThisWeekData {
                fetchThisWeekStats(service: service, widgetData: widgetData, completion: completion)
            }
        } catch {
            completion(.failure(error))
            self.state = .error
        }
    }

    private func fetchTodayStats(service: StatsServiceRemoteV2,
                                 widgetData: HomeWidgetTodayData,
                                 completion: @escaping (Result<HomeWidgetData, Error>) -> Void) {

        service.getInsight { [weak self] (insight: StatsTodayInsight?, error) in
            guard let self = self else {
                return
            }

            if let error = error {
                completion(.failure(error))
                self.state = .error
                return
            }

            guard let insight = insight else {
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

    private func fetchAllTimeStats(service: StatsServiceRemoteV2,
                                   widgetData: HomeWidgetAllTimeData,
                                   completion: @escaping (Result<HomeWidgetData, Error>) -> Void) {

        service.getInsight { [weak self] (insight: StatsAllTimesInsight?, error) in

            guard let self = self else {
                return
            }

            if let error = error {
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

    private func fetchThisWeekStats(service: StatsServiceRemoteV2,
                                    widgetData: HomeWidgetThisWeekData,
                                    completion: @escaping (Result<HomeWidgetData, Error>) -> Void) {

        // Get the current date in the site's time zone.
        let siteTimeZone = widgetData.timeZone
        let weekEndingDate = Date().convert(from: siteTimeZone).normalizedDate()

        // Include an extra day. It's needed to get the dailyChange for the last day.
        service.getData(for: .day, endingOn: weekEndingDate,
                        limit: ThisWeekWidgetStats.maxDaysToDisplay + 1) { [weak self] (summary: StatsSummaryTimeIntervalData?, error: Error?) in

            guard let self = self else {
                return
            }

            if let error = error {
                DDLogError("This Week Widget: Error fetching summary: \(String(describing: error.localizedDescription))")
                completion(.failure(error))
                self.state = .error
                return
            }

            let summaryData = summary?.summaryData.reversed() ?? []
            let newWidgetData = HomeWidgetThisWeekData(siteID: widgetData.siteID,
                                                       siteName: widgetData.siteName,
                                                       url: widgetData.url,
                                                       timeZone: widgetData.timeZone,
                                                       date: Date(),
                                                       stats: ThisWeekWidgetStats(days: ThisWeekWidgetStats.daysFrom(summaryData: summaryData)))
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
