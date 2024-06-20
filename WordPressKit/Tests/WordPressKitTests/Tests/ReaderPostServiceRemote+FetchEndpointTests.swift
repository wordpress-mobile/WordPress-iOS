import Foundation
import XCTest
import OHHTTPStubs

@testable import WordPressKit

class ReaderPostServiceRemoteFetchEndpointTests: XCTestCase {

    override func tearDown() {
        super.tearDown()

        HTTPStubs.removeAllStubs()
    }

    func testEndpointIsFullURL() throws {
        var request: URLRequest?
        stub(condition: { _ in true }) {
            request = $0
            return HTTPStubsResponse(error: URLError(.networkConnectionLost))
        }

        let complete = expectation(description: "API call completes")
        let service = ReaderPostServiceRemote(wordPressComRestApi: WordPressComRestApi())
        let endpoint = URL(string: "https://public-api.wordpress.com/rest/v1.2/read/liked")!
        service.fetchPosts(
            fromEndpoint: endpoint,
            algorithm: "none",
            count: 1,
            before: Date(),
            success: { _, _ in complete.fulfill() },
            failure: { _ in complete.fulfill() }
        )
        wait(for: [complete], timeout: 0.3)

        var url = try XCTUnwrap(URLComponents(url: XCTUnwrap(request?.url), resolvingAgainstBaseURL: true))
        url.query = nil
        XCTAssertEqual(url.url?.absoluteString, "https://public-api.wordpress.com/rest/v1.2/read/liked")
    }

}
