import XCTest

@testable import WordPress

final class DashboardBlazeCardCellViewModelTest: CoreDataTestCase {
    private let service = MockBlazeService()
    private let store = MockDashboardBlazeStore()
    private var blog: Blog!
    private var sut: DashboardBlazeCardCellViewModel!
    private var isBlazeCampaignsFlagEnabled = true

    override func setUp() {
        super.setUp()

        blog = ModelTestHelper.insertDotComBlog(context: mainContext)
        blog.dotComID = 1

        createSUT()
    }

    private func createSUT() {
        sut = DashboardBlazeCardCellViewModel(
            blog: blog,
            service: service,
            store: store,
            isBlazeCampaignsFlagEnabled: isBlazeCampaignsFlagEnabled
        )
    }

    func testInitialState() {
        switch sut.state {
        case .promo:
            break // Expected
        case .campaign:
            XCTFail("The card should show promo before the app fetches the data")
        }
    }

    func testCampaignRefresh() {
        let expectation = self.expectation(description: "didRefresh")
        sut.onRefresh = { _ in
            expectation.fulfill()
        }

        // When
        sut.refresh()
        XCTAssertTrue(service.didPerformRequest)
        wait(for: [expectation], timeout: 1)

        // Then
        switch sut.state {
        case .promo:
            XCTFail("The card should display the latest campaign")
        case .campaign(let viewModel):
            XCTAssertEqual(viewModel.title, "Test Post - don't approve")
        }
    }

    func testThatCampaignIsCached() {
        // Given
        let expectation = self.expectation(description: "didRefresh")
        sut.onRefresh = { _ in expectation.fulfill() }
        sut.refresh()
        wait(for: [expectation], timeout: 1)

        // When the ViewModel is re-created
        createSUT()

        // Then it shows the cached campaign
        switch sut.state {
        case .promo:
            XCTFail("The card should display the latest campaign")
        case .campaign(let viewModel):
            XCTAssertEqual(viewModel.title, "Test Post - don't approve")
        }
    }

    func testThatNoRequestsAreMadeWhenFlagDisabled() {
        // Given
        isBlazeCampaignsFlagEnabled = false
        createSUT()

        // When
        sut.refresh()

        // Then
        XCTAssertFalse(service.didPerformRequest)

        // Then still shows promo
        switch sut.state {
        case .promo:
            break // Expected
        case .campaign:
            XCTFail("The card should show promo before the app fetches the data")
        }
    }
}

private final class MockBlazeService: BlazeServiceProtocol {
    var didPerformRequest = false

    func getRecentCampaigns(for blog: Blog, completion: @escaping (Result<BlazeCampaignsSearchResponse, Error>) -> Void) {
        didPerformRequest = true
        DispatchQueue.main.async {
            completion(.success(response))
        }
    }
}

private final class MockDashboardBlazeStore: DashboardBlazeStoreProtocol {
    private var campaigns: [Int: BlazeCampaign] = [:]

    func getBlazeCampaign(forBlogID blogID: Int) -> BlazeCampaign? {
        campaigns[blogID]
    }

    func setBlazeCampaign(_ campaign: BlazeCampaign?, forBlogID blogID: Int) {
        campaigns[blogID] = campaign
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
        ]
    }
    """.data(using: .utf8)!)
}()
