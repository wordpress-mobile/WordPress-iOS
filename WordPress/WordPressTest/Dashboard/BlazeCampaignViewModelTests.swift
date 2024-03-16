import XCTest

@testable import WordPress

final class BlazeCampaignViewModelTests: XCTestCase {
    func testViewModel() throws {
        // Given
        let viewModel = BlazeCampaignViewModel(campaign: campaign)

        // Then campaign is displayed
        XCTAssertEqual(viewModel.title, "Test Post - don't approve")
        XCTAssertEqual(viewModel.imageURL, URL(string: "https://i0.wp.com/public-api.wordpress.com/wpcom/v2/wordads/dsp/api/v1/dsp/creatives/56259/image?w=600&zoom=2"))

        // Then stats are displayed
        XCTAssertEqual(viewModel.impressions, 1_000.abbreviatedString())
        XCTAssertEqual(viewModel.clicks, "235")
        XCTAssertTrue(viewModel.isShowingStats)
    }
}

private let campaign: BlazeCampaign = {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    decoder.dateDecodingStrategy = .iso8601
    return try! decoder.decode(BlazeCampaign.self, from: """
    {
        "campaign_id": 26916,
        "name": "Test Post - don't approve",
        "start_date": "2023-06-13T00:00:00Z",
        "end_date": "2023-06-01T19:15:45Z",
        "status": "finished",
        "ui_status": "finished",
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
    """.data(using: .utf8)!)
}()
