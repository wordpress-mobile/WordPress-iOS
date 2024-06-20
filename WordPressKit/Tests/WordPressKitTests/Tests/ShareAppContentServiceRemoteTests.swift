import XCTest

@testable import WordPressKit

final class ShareAppContentServiceRemoteTests: RemoteTestCase, RESTTestable {

    var mockApi: WordPressComRestApi!
    var service: ShareAppContentServiceRemote!

    // MARK: Setup

    override func setUp() {
        super.setUp()

        mockApi = getRestApi()
        service = ShareAppContentServiceRemote(wordPressComRestApi: mockApi)
    }

    override func tearDown() {
        super.tearDown()

        mockApi = nil
        service = nil
    }

    // MARK: Tests

    func test_getContent_givenWordPressAppName_returnsContentForWordPress() {
        let appName: ShareAppName = .wordpress
        stubRemoteResponse(.getContentEndpoint, filename: .mockFilename, contentType: .ApplicationJSON)

        let expect = expectation(description: "Get share app content success")
        service.getContent(for: appName) { result in
            guard case .success(let content) = result else {
                XCTFail("Expected success result type")
                return
            }

            XCTAssertEqual(content.message, .expectedMessage)
            XCTAssertEqual(content.link, .expectedLink)
            XCTAssertNotNil(content.linkURL())
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func test_getContent_givenUnidentifiedResponseStructure_returnsFailureResult() {
        let appName: ShareAppName = .wordpress
        let mockDictionary = [
            "text": "An unknown structure",
            "destination": "https://example.blog/fairy-land"
        ]
        let data = try! JSONSerialization.data(withJSONObject: mockDictionary, options: [])
        stubRemoteResponse(.getContentEndpoint, data: data, contentType: .ApplicationJSON)

        let expect = expectation(description: "Get share app content parsing failure")
        service.getContent(for: appName) { result in
            guard case .failure(let error) = result else {
                XCTFail("Expected failure result type")
                return
            }

            XCTAssertNotNil(error)
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    // tests for network error, no internet connection, etc.
    func test_getContent_givenUnknownError_returnsFailureResult() {
        let appName: ShareAppName = .wordpress
        // somehow `stubAllNetworkRequestsWithNotConnectedError()` called in super.setUp() is not taking effect.
        // let's manually stub the error for now.
        stubRemoteResponse(.getContentEndpoint, data: Data(), contentType: .NoContentType, status: 500)

        let expect = expectation(description: "Get share app content parsing failure")
        service.getContent(for: appName) { result in
            guard case .failure(let error) = result else {
                XCTFail("Expected failure result type")
                return
            }

            XCTAssertNotNil(error)
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }
}

// MARK: - String Constants

private extension String {
    static let getContentEndpoint = "mobile/share-app-link"
    static let mockFilename = "share-app-content-success.json"
    static let expectedLink = "https://example.blog/app?campaign=wordpress"
    static let expectedMessage = "Example message for WordPress"
}
