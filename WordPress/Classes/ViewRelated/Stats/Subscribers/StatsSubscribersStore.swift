import Foundation
import Combine
import WordPressKit

protocol StatsSubscribersStoreProtocol {
    var emailsSummary: CurrentValueSubject<StatsSubscribersStore.State<StatsEmailsSummaryData>, Never> { get }
    var chartSummary: CurrentValueSubject<StatsSubscribersStore.State<StatsSubscribersSummaryData>, Never> { get }
    var subscribersList: CurrentValueSubject<StatsSubscribersStore.State<StatsSubscribersData>, Never> { get }

    func updateEmailsSummary(quantity: Int, sortField: StatsEmailsSummaryData.SortField)
    func updateChartSummary()
    func updateSubscribersList(quantity: Int)
}

struct StatsSubscribersStore: StatsSubscribersStoreProtocol {
    private let siteID: NSNumber
    private let cache: StatsSubscribersCache = .shared
    private let statsService: StatsServiceRemoteV2

    var emailsSummary: CurrentValueSubject<State<StatsEmailsSummaryData>, Never> = .init(.idle)
    var subscribersList: CurrentValueSubject<State<StatsSubscribersData>, Never> = .init(.idle)
    var chartSummary: CurrentValueSubject<State<StatsSubscribersSummaryData>, Never> = .init(.idle)

    init() {
        self.siteID = SiteStatsInformation.sharedInstance.siteID ?? 0
        let timeZone = SiteStatsInformation.sharedInstance.siteTimeZone ?? .current
        let wpApi = WordPressComRestApi.defaultApi(oAuthToken: SiteStatsInformation.sharedInstance.oauth2Token, userAgent: WPUserAgent.wordPress())
        statsService = StatsServiceRemoteV2(wordPressComRestApi: wpApi, siteID: siteID.intValue, siteTimezone: timeZone)
    }

    // MARK: - Emails Summary

    func updateEmailsSummary(quantity: Int, sortField: StatsEmailsSummaryData.SortField) {
        guard emailsSummary.value != .loading else { return }

        let sortOrder = StatsEmailsSummaryData.SortOrder.descending
        let cacheKey = StatsSubscribersCache.CacheKey.emailsSummary(quantity: quantity, sortField: sortField.rawValue, sortOrder: sortOrder.rawValue, siteId: siteID)
        let cachedData: StatsEmailsSummaryData? = cache.getValue(key: cacheKey)

        if let cachedData {
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

        let unit = StatsPeriodUnit.day
        let cacheKey = StatsSubscribersCache.CacheKey.chartSummary(unit: unit.stringValue, siteId: siteID)
        let cachedData: StatsSubscribersSummaryData? = cache.getValue(key: cacheKey)

        if let cachedData {
            self.chartSummary.send(.success(cachedData))
        } else {
            chartSummary.send(.loading)
        }

        statsService.getData(for: unit, endingOn: StatsDataHelper.currentDateForSite(), limit: 30) { (data: StatsSubscribersSummaryData?, error: Error?) in
            DispatchQueue.main.async {
                if let data {
                    cache.setValue(data, key: cacheKey)
                    self.chartSummary.send(.success(data))
                }
            else {
                    if cachedData == nil {
                        self.chartSummary.send(.error)
                    }
                }
            }
        }
    }

    // MARK: - Subscribers List

    func updateSubscribersList(quantity: Int) {
        let cacheKey = StatsSubscribersCache.CacheKey.subscribersList(quantity: quantity, siteId: siteID)
        let cachedData: StatsSubscribersData? = cache.getValue(key: cacheKey)

        if let cachedData {
            self.subscribersList.send(.success(cachedData))
        } else {
            subscribersList.send(.loading)
        }

        getSubscribers(quantity: quantity) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    cache.setValue(data, key: cacheKey)
                    self.subscribersList.send(.success(data))
                case .failure:
                    if cachedData == nil {
                        self.subscribersList.send(.error)
                    }
                }
            }
        }
    }

    private func getSubscribers(quantity: Int, completion: @escaping (Result<StatsSubscribersData, Error>) -> Void) {
        let group = DispatchGroup()
        var wpComFollowers: StatsDotComFollowersInsight?
        var emailFollowers: StatsEmailFollowersInsight?
        var requestError: Error?

        group.enter()
        statsService.getInsight(limit: quantity) { (followers: StatsDotComFollowersInsight?, error) in
            wpComFollowers = followers
            requestError = error
            group.leave()
        }

        group.enter()
        statsService.getInsight(limit: quantity) { (followers: StatsEmailFollowersInsight?, error) in
            emailFollowers = followers
            requestError = error
            group.leave()
        }

        group.notify(queue: .main) {
            if let error = requestError {
                completion(.failure(error))
            } else {
                // Combine both wpcom and email subscribers into a single list
                let combinedSubscribers = Array((wpComFollowers?.topDotComFollowers ?? []) + (emailFollowers?.topEmailFollowers ?? [])
                    .sorted(by: { $0.subscribedDate > $1.subscribedDate })
                    .prefix(quantity))
                let combinedTotalsCount = (wpComFollowers?.dotComFollowersCount ?? 0) + (emailFollowers?.emailFollowersCount ?? 0)

                let result = StatsSubscribersData(subscribers: combinedSubscribers, totalCount: combinedTotalsCount)
                completion(.success(result))
            }
        }
    }
}

// MARK: - State

extension StatsSubscribersStore {
    enum State<Value: Equatable>: Equatable {
        case idle
        case loading
        case success(Value)
        case error

        var data: Value? {
            switch self {
            case .success(let data):
                return data
            default:
                return nil
            }
        }

        var storeFetchingStatus: StoreFetchingStatus {
            switch self {
            case .idle:
                return .idle
            case .loading:
                return .loading
            case .success:
                return .success
            case .error:
                return .error
            }
        }
    }
}

// MARK: - Helper Entities

struct StatsSubscribersData: Equatable {
    let subscribers: [StatsFollower]
    let totalCount: Int
}
