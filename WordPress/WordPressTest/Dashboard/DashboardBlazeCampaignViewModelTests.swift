import XCTest

@testable import WordPress

final class DashboardBlazeCampaignViewModelTests: XCTestCase {
    func testViewModel() throws {
        // Given
        let viewModel = try XCTUnwrap(DashboardBlazeCampaignCardCellViewModel(response: response))

        // Then campaign is displayed
        let campaign = viewModel.campaign
        XCTAssertEqual(campaign.title, "Test Post - don't approve")
        XCTAssertEqual(campaign.imageURL, URL(string: "https://i0.wp.com/public-api.wordpress.com/wpcom/v2/wordads/dsp/api/v1/dsp/creatives/56259/image?w=600&zoom=2"))

        // Then stats are displayed
        XCTAssertEqual(campaign.impressions, 1000)
        XCTAssertEqual(campaign.clicks, 235)
        XCTAssertTrue(campaign.isShowingStats)

        // Then "show more" button is displayed
        XCTAssertEqual(viewModel.totalCampaignCount, 3)
        XCTAssertFalse(viewModel.isButtonShowMoreHidden)
    }
}

private let response: BlazeCampaignsSearchResponse = {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    decoder.dateDecodingStrategy = .iso8601
    return try! decoder.decode(BlazeCampaignsSearchResponse.self, from: """
    {
        "totalItems": 3,
        "campaigns": [
            {
                "campaign_id": 26916,
                "name": "Test Post - don't approve",
                "start_date": "2023-06-13T00:00:00Z",
                "end_date": "2023-06-01T19:15:45Z",
                "status": "finished",
                "avatar_url": "https://0.gravatar.com/avatar/614d27bcc21db12e7c49b516b4750387?s=96&amp;d=identicon&amp;r=G",
                "budget_cents": 500,
                "target_url": "https://alextest9123.wordpress.com/2023/06/01/test-post/",
                "content_config": {
                    "title": "Test Post - don't approve",
                    "snippet": "Test Post Empty Empty",
                    "clickUrl": "https://alextest9123.wordpress.com/2023/06/01/test-post/",
                    "imageUrl": "https://i0.wp.com/public-api.wordpress.com/wpcom/v2/wordads/dsp/api/v1/dsp/creatives/56259/image?w=600&zoom=2"
                },
                "campaign_stats": {
                    "impressions_total": 1000,
                    "clicks_total": 235
                }
            }
        ]
    }
    """.data(using: .utf8)!)
}()
