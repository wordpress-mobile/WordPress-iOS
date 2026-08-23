import Testing
import Foundation
@testable import JetpackStats

@Suite
struct MockStatsServiceTests {
    let calendar = Calendar.mock(timeZone: .eastern)

    @Test("getTopListData returns valid data for posts")
    func testGetTopListDataPosts() async throws {
        // GIVEN
        let service = MockStatsService(timeZone: .eastern)
        let dateInterval = calendar.makeDateInterval(for: .today)

        // WHEN
        let startTime = CFAbsoluteTimeGetCurrent()
        let response = try await service.getTopListData(
            .postsAndPages,
            metric: .views,
            interval: dateInterval,
            granularity: dateInterval.preferredGranularity,
            limit: nil,
            options: TopListItemOptions()
        )
        print("elapsed: \((CFAbsoluteTimeGetCurrent() - startTime) * 1000) ms")

        // THEN
        #expect(!response.items.isEmpty)
        #expect(response.items.count <= 40, "Should return maximum 40 items")

        // THEN all items are posts
        for item in response.items {
            if let post = item as? TopListItem.Post {
                #expect(!post.title.isEmpty)
                #expect((post.metrics.views ?? 0) > 0)
            } else {
                Issue.record("Expected post item but got \(type(of: item))")
            }
        }
    }

    @Test("Verify getChartData returns valid data for views metric with today range")
    func testGetChartDataViewsToday() async throws {
        // GIVEN
        let service = MockStatsService(timeZone: .eastern)
        let dateInterval = calendar.makeDateInterval(for: .today)
        let granularity = dateInterval.preferredGranularity

        // WHEN
        let startTime = CFAbsoluteTimeGetCurrent()
        let response = try await service.getSiteStats(
            interval: dateInterval,
            granularity: granularity
        )
        print("elapsed: \((CFAbsoluteTimeGetCurrent() - startTime) * 1000) ms")

        // THEN - Basic validations
        #expect(!response.metrics.isEmpty, "Should return at least one data point")
    }

    @Test("Marking a referrer as spam removes it from subsequent responses")
    func markingReferrerAsSpamRemovesIt() async throws {
        let service = MockStatsService(timeZone: .eastern)
        await service.disableDelays()
        let dateInterval = calendar.makeDateInterval(for: .today)
        let response = try await service.getTopListData(
            .referrers,
            metric: .views,
            interval: dateInterval,
            granularity: dateInterval.preferredGranularity,
            limit: nil,
            options: TopListItemOptions()
        )
        let referrer = try #require(response.items.compactMap { $0 as? TopListItem.Referrer }.first)
        let domain = try #require(referrer.spamDomain)

        for _ in 0..<20 {
            do {
                try await service.toggleSpamState(for: domain, currentValue: false)
                break
            } catch {
                continue
            }
        }

        let refreshedResponse = try await service.getTopListData(
            .referrers,
            metric: .views,
            interval: dateInterval,
            granularity: dateInterval.preferredGranularity,
            limit: nil,
            options: TopListItemOptions()
        )
        let domains = refreshedResponse.items
            .compactMap { $0 as? TopListItem.Referrer }
            .compactMap(\.spamDomain)

        #expect(!domains.contains(domain))
    }
}
