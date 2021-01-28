import WordPressKit

/// Type that wraps the backend request for new today stats
class HomeWidgetTodayRemoteService {

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


    func fetchStats(for widgetData: HomeWidgetTodayData,
                    completion: @escaping (Result<HomeWidgetTodayData, Error>) -> Void) {

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
                    completion(.failure(HomeWidgetTodayError.nilStats))
                    self.state = .error
                    return
                }

                let newWidgetData = HomeWidgetTodayData(siteID: widgetData.siteID,
                                                        siteName: widgetData.siteName,
                                                        iconURL: widgetData.iconURL,
                                                        url: widgetData.url,
                                                        timeZone: widgetData.timeZone,
                                                        date: Date(),
                                                        stats: TodayWidgetStats(views: insight.viewsCount,
                                                                                visitors: insight.visitorsCount,
                                                                                likes: insight.likesCount,
                                                                                comments: insight.commentsCount))
                completion(.success(newWidgetData))
                self.state = .ready
            }
        } catch {
            completion(.failure(error))
            self.state = .error
        }
    }
}

enum HomeWidgetTodayError: Error {
    case nilStats
}
