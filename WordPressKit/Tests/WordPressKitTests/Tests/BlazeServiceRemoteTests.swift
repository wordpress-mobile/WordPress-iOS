import XCTest
@testable import WordPressKit

final class BlazeServiceRemoteTests: RemoteTestCase, RESTTestable {

    // MARK: - Constants

    let siteId = 1

    // MARK: - Properties

    var searchEndpoint: String { "sites/\(siteId)/wordads/dsp/api/v1/search/campaigns/site/\(siteId)" }
    var service: BlazeServiceRemote!

    // MARK: - Campaigns

    func testGetCampaignsSuccess() throws {
        // Given
        let bundle = Bundle(for: BlazeServiceRemoteTests.self)
        let url = try XCTUnwrap(bundle.url(forResource: "blaze-campaigns-search", withExtension: "json"))
        stubRemoteResponse(searchEndpoint, data: try Data(contentsOf: url), contentType: .ApplicationJSON)

        // When
        let result = try getSearchCampaignsResult()

        // Then
        let response = try result.get()

        XCTAssertEqual(response.totalItems, 1)
        XCTAssertEqual(response.totalPages, 1)
        XCTAssertEqual(response.page, 1)
        XCTAssertEqual(response.campaigns?.count, 1)

        let campaign = try XCTUnwrap(response.campaigns?.first)
        XCTAssertEqual(campaign.campaignID, 26916)
        XCTAssertEqual(campaign.name, "Test Post - don't approve")
        XCTAssertEqual(campaign.startDate, ISO8601DateFormatter().date(from: "2023-06-13T00:00:00Z"))
        XCTAssertEqual(campaign.endDate, ISO8601DateFormatter().date(from: "2023-06-01T19:15:45Z"))
        XCTAssertEqual(campaign.status, .canceled)
        XCTAssertEqual(campaign.uiStatus, .canceled)
        XCTAssertEqual(campaign.budgetCents, 500)
        XCTAssertEqual(campaign.targetURL, "https://alextest9123.wordpress.com/2023/06/01/test-post/")
        XCTAssertEqual(campaign.contentConfig?.title, "Test Post - don't approve")
        XCTAssertEqual(campaign.contentConfig?.snippet, "Test Post Empty Empty")
        XCTAssertEqual(campaign.contentConfig?.clickURL, "https://alextest9123.wordpress.com/2023/06/01/test-post/")
        XCTAssertEqual(campaign.contentConfig?.imageURL, "https://i0.wp.com/public-api.wordpress.com/wpcom/v2/wordads/dsp/api/v1/dsp/creatives/56259/image?w=600&zoom=2")

        let stats = try XCTUnwrap(campaign.stats)
        XCTAssertEqual(stats.impressionsTotal, 1000)
        XCTAssertEqual(stats.clicksTotal, 235)
    }

    func testGetCampaignsSuccessFailureInvalidJSON() throws {
        // Given
        let data = #"{ "campaigns": "XXXX" }"#.data(using: .utf8)!
        stubRemoteResponse(searchEndpoint, data: data, contentType: .ApplicationJSON)

        // When
        let result = try getSearchCampaignsResult()

        // Then
        switch result {
        case .success:
            XCTFail("Expected failure")
        case .failure:
            break // OK
        }
    }

    func testGetCampaignsSuccessFailureUnauthorized() throws {
        // Given
        stubRemoteResponse(searchEndpoint, data: Data(), contentType: .NoContentType, status: 403)

        // When
        let result = try getSearchCampaignsResult()

        // Then
        switch result {
        case .success:
            XCTFail("Expected failure")
        case .failure:
            break // OK
        }
    }

    private func getSearchCampaignsResult() throws -> Result<BlazeCampaignsSearchResponse, Error> {
        var result: Result<BlazeCampaignsSearchResponse, Error>?
        let expectation = self.expectation(description: "requestCompleted")
        BlazeServiceRemote(wordPressComRestApi: getRestApi()).searchCampaigns(forSiteId: siteId) {
            result = $0
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
        return try XCTUnwrap(result)
    }
}
