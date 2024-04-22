import Foundation
import Combine
import WordPressKit

protocol StatsSubscribersStoreProtocol {
    var emailsSummary: CurrentValueSubject<StatsSubscribersStore.State<StatsEmailsSummaryData>, Never> { get }
    var chartSummary: CurrentValueSubject<StatsSubscribersStore.State<StatsSubscribersSummaryData>, Never> { get }
    func updateEmailsSummary(quantity: Int, sortField: StatsEmailsSummaryData.SortField)
    func updateChartSummary()
}

struct StatsSubscribersStore: StatsSubscribersStoreProtocol {
    private let siteID: NSNumber
    private let cache: StatsSubscribersCache = .shared
    private let statsService: StatsServiceRemoteV2

    var emailsSummary: CurrentValueSubject<State<StatsEmailsSummaryData>, Never> = .init(.idle)
    var chartSummary: CurrentValueSubject<State<StatsSubscribersSummaryData>, Never> = .init(.idle)

    init() {
        self.siteID = SiteStatsInformation.sharedInstance.siteID ?? 0
        let timeZone = SiteStatsInformation.sharedInstance.siteTimeZone ?? .current
        let wpApi = WordPressComRestApi.defaultApi(oAuthToken: SiteStatsInformation.sharedInstance.oauth2Token, userAgent: WPUserAgent.wordPress())
        statsService = StatsServiceRemoteV2(wordPressComRestApi: wpApi, siteID: siteID.intValue, siteTimezone: timeZone)
    }

    func updateEmailsSummary(quantity: Int, sortField: StatsEmailsSummaryData.SortField) {
        guard emailsSummary.value != .loading else { return }

        let sortOrder = StatsEmailsSummaryData.SortOrder.descending
        let cacheKey = StatsSubscribersCache.CacheKey.emailsSummary(quantity: quantity, sortField: sortField.rawValue, sortOrder: sortOrder.rawValue, siteId: siteID)
        let cachedData: StatsEmailsSummaryData? = cache.getValue(key: cacheKey)

        if let cachedData = cachedData {
            self.emailsSummary.send(.success(cachedData))
        } else {
            emailsSummary.send(.loading)
        }

        statsService.getData(quantity: quantity, sortField: sortField, sortOrder: sortOrder) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    cache.setValue(data, key: cacheKey)
                    self.emailsSummary.send(.success(data))
                case .failure:
                    if cachedData == nil {
                        self.emailsSummary.send(.error)
                    }
                }
            }
        }
    }

    func updateChartSummary() {
        guard chartSummary.value != .loading else { return }

        let unit = StatsSubscribersSummaryData.Unit.day
        let cacheKey = StatsSubscribersCache.CacheKey.chartSummary(unit: unit.rawValue, siteId: siteID)
        let cachedData: StatsSubscribersSummaryData? = cache.getValue(key: cacheKey)

        if let cachedData = cachedData {
            self.chartSummary.send(.success(cachedData))
        } else {
            chartSummary.send(.loading)
        }

        statsService.getSubscribers(unit: unit) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    cache.setValue(data, key: cacheKey)
                    self.chartSummary.send(.success(data))
                case .failure:
                    if cachedData == nil {
                        self.chartSummary.send(.error)
                    }
                }
            }
        }
    }
}

extension StatsSubscribersStore {
    enum State<Value: Equatable>: Equatable {
        case idle
        case loading
        case success(Value)
        case error
    }
}
