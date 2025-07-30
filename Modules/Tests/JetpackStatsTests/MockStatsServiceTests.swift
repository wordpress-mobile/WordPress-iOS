import Testing
import Foundation
@testable import JetpackStats

@Suite
struct MockStatsServiceTests {
    let calendar = Calendar.mock(timeZone: .eastern)

    @Test("getTopListData returns valid data for posts")
    func testGetTopListDataPosts() async throws {
        // GIVEN
        let service = MockStatsService(timeZone: .current)
        let dateInterval = calendar.makeDateInterval(for: .today)

        // WHEN
        let response = try await service.getTopListData(
            .postsAndPages,
            metric: .views,
            interval: dateInterval,
            granularity: dateInterval.preferredGranularity,
            limit: nil
        )

        // THEN
        #expect(response.items.count > 0)
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
        let service = MockStatsService(timeZone: .current)
        let dateInterval = calendar.makeDateInterval(for: .today)
        let granularity = dateInterval.preferredGranularity

        // WHEN
        let response = try await service.getSiteStats(
            interval: dateInterval,
            granularity: granularity
        )

        // THEN - Basic validations
        #expect(response.metrics.count > 0, "Should return at least one data point")
    }
}
