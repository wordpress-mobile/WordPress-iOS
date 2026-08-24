import Foundation
import Testing
@preconcurrency import WordPressKit
@testable import JetpackStats

@Suite
@MainActor
struct TopListViewModelTests {
    @Test("Refreshes top-list data after invalidating its cache")
    func refreshesTopListData() async throws {
        let referrer = TopListItem.Referrer(
            name: "example.com",
            domain: "example.com",
            url: URL(string: "https://example.com"),
            iconURL: nil,
            children: [],
            metrics: SiteMetricsSet(views: 10)
        )
        let service = CachingStatsService(response: TopListResponse(items: [referrer]))
        let calendar = Calendar.mock()
        let dateRange = StatsDateRange(
            interval: calendar.makeDateInterval(for: .today),
            component: .day,
            comparison: .off,
            calendar: calendar
        )
        let viewModel = TopListViewModel(
            configuration: TopListCardConfiguration(item: .referrers, metric: .views),
            dateRange: dateRange,
            service: service
        )

        viewModel.onAppear()
        try await waitUntil { viewModel.data != nil && !viewModel.isLoading }
        #expect(viewModel.data?.items.count == 1)

        await service.setResponse(TopListResponse(items: []))
        viewModel.refresh()

        try await waitUntil { viewModel.data?.items.isEmpty == true && !viewModel.isLoading }
    }

    private func waitUntil(_ condition: () -> Bool) async throws {
        let clock = ContinuousClock()
        let deadline = clock.now + .seconds(2)
        while !condition() {
            guard clock.now < deadline else {
                throw TestError.timedOut
            }
            try await Task.sleep(for: .milliseconds(10))
        }
    }
}

private enum TestError: Error {
    case timedOut
}

private actor CachingStatsService: StatsServiceProtocol {
    nonisolated let supportedMetrics: [SiteMetric] = [.views]
    nonisolated let supportedItems: [TopListItemType] = [.referrers]

    private var response: TopListResponse
    private var cachedResponse: TopListResponse?

    init(response: TopListResponse) {
        self.response = response
    }

    nonisolated func getSupportedMetrics(for item: TopListItemType) -> [SiteMetric] {
        [.views]
    }

    func setResponse(_ response: TopListResponse) {
        self.response = response
    }

    func invalidateTopListData(for item: TopListItemType) async {
        guard item == .referrers else { return }
        cachedResponse = nil
    }

    func getTopListData(
        _ item: TopListItemType,
        metric: SiteMetric,
        interval: DateInterval,
        granularity: DateRangeGranularity,
        limit: Int?,
        options: TopListItemOptions
    ) async throws -> TopListResponse {
        if let cachedResponse {
            return cachedResponse
        }
        cachedResponse = response
        return response
    }

    func getSiteStats(interval: DateInterval, granularity: DateRangeGranularity) async throws -> SiteMetricsResponse {
        fatalError("Unused")
    }

    func getWordAdsStats(date: Date, granularity: DateRangeGranularity) async throws -> WordAdsMetricsResponse {
        fatalError("Unused")
    }

    func getWordAdsEarnings() async throws -> WordPressKit.StatsWordAdsEarningsResponse {
        fatalError("Unused")
    }

    func getRealtimeTopListData(_ item: TopListItemType) async throws -> TopListResponse {
        fatalError("Unused")
    }

    func getPostDetails(for postID: Int) async throws -> StatsPostDetails {
        fatalError("Unused")
    }

    func getPostLikes(for postID: Int, count: Int) async throws -> PostLikesData {
        fatalError("Unused")
    }

    func getEmailOpens(for postID: Int) async throws -> StatsEmailOpensData {
        fatalError("Unused")
    }

    func toggleSpamState(for referrerDomain: String, currentValue: Bool) async throws {
        fatalError("Unused")
    }
}
