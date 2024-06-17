import XCTest
@testable import WordPressKit

final class SiteCreationVerticalsTests: RemoteTestCase, RESTTestable {

    func testSiteVerticalsRequest_Succeeds() {
        // Given
        let endpoint = "verticals"
        let fileName = "site-verticals-multiple.json"
        stubRemoteResponse(endpoint, filename: fileName, contentType: .ApplicationJSON)

        let expectedSearch = "landscap"
        let expectedLimit = 5

        let request = SiteVerticalsRequest(search: expectedSearch, limit: expectedLimit)

        // When, Then
        let verticalsExpectation = expectation(description: "Initiate site verticals request")
        let remote = WordPressComServiceRemote(wordPressComRestApi: getRestApi())
        remote.retrieveVerticals(request: request) { result in
            verticalsExpectation.fulfill()

            switch result {
            case .success(let verticals):
                XCTAssertNotNil(verticals)

                let actualLimit = verticals.count
                XCTAssertEqual(actualLimit, expectedLimit)

            case .failure:
                XCTFail()
            }
        }

        waitForExpectations(timeout: timeout)
    }
}
