import XCTest

@testable import WordPress

final class DashboardBlazeCardCellViewModelTest: CoreDataTestCase {
    private var service: MockBlazeService!
    private var store: MockDashboardBlazeStore!
    private var blog: Blog!
    private var sut: DashboardBlazeCardCellViewModel!
    private var isBlazeCampaignsFlagEnabled = true

    override func setUp() {
        super.setUp()

        service = MockBlazeService()
        store = MockDashboardBlazeStore()
        blog = ModelTestHelper.insertDotComBlog(context: mainContext)
        blog.dotComID = 1

        createSUT()
    }

    private func createSUT() {
        sut = DashboardBlazeCardCellViewModel(
            blog: blog,
            service: service,
            store: store,
            isBlazeCampaignsFlagEnabled: { [unowned self] in self.isBlazeCampaignsFlagEnabled }
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
        case .campaign(let campaign):
            XCTAssertEqual(campaign.name, "Test Post - don't approve")
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
        case .campaign(let campaign):
            XCTAssertEqual(campaign.name, "Test Post - don't approve")
        }
    }

    // FIXME: This test is testing the default state of the service and exercises async behavior synchronousely.
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

    func getRecentCampaigns(for blog: Blog, page: Int, completion: @escaping (Result<BlazeCampaignsSearchResponse, Error>) -> Void) {
        didPerformRequest = true
        DispatchQueue.main.async {
            completion(Result(catching: getMockResponse))
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

private func getMockResponse() throws -> BlazeCampaignsSearchResponse {
    let data = try Bundle.test.json(named: "blaze-search-response")

    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    decoder.dateDecodingStrategy = .iso8601
    return try decoder.decode(BlazeCampaignsSearchResponse.self, from: data)
}
