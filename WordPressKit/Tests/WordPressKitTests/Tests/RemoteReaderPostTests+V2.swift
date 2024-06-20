import XCTest

@testable import WordPressKit

class RemoteReaderPostTestsV2: RemoteTestCase, RESTTestable {
    let mockRemoteApi = MockWordPressComRestApi()
    var readerPostServiceRemote: ReaderPostServiceRemote!

    override func setUp() {
        super.setUp()
        readerPostServiceRemote = ReaderPostServiceRemote(wordPressComRestApi: getRestApi())
    }

    // Return an array of cards
    //
    func testReturnPosts() {
        let expect = expectation(description: "Get cards successfully")
        stubRemoteResponse("read/tags/posts?tags%5B%5D=dogs", filename: "reader-posts-success.json", contentType: .ApplicationJSON)

        readerPostServiceRemote.fetchPosts(for: ["dogs"], success: { posts, _ in
            XCTAssertTrue(posts.count == 10)
            expect.fulfill()
        }, failure: { _ in })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    // Calls the failure block when an error happens
    //
    func testReturnError() {
        let expect = expectation(description: "Get cards successfully")
        stubRemoteResponse("read/tags/posts?tags%5B%5D=cats", filename: "reader-posts-success.json", contentType: .ApplicationJSON, status: 503)

        readerPostServiceRemote.fetchPosts(for: ["cats"], success: { _, _ in }, failure: { error in
            XCTAssertNotNil(error)
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    // Return the next page handle
    //
    func testReturnNextPageHandle() {
        let expect = expectation(description: "Returns next page handle")
        stubRemoteResponse("read/tags/posts?tags%5B%5D=dogs", filename: "reader-posts-success.json", contentType: .ApplicationJSON)

        readerPostServiceRemote.fetchPosts(for: ["dogs"], success: { _, nextPageHandle in
            XCTAssertTrue(nextPageHandle == "ZnJvbT0xMCZiZWZvcmU9MjAyMC0wOS0zMFQxNyUzQTAzJTNBMjAlMkIwMCUzQTAw")
            expect.fulfill()
        }, failure: { _ in })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    // Calls the API with the given page handle
    //
    func testCallAPIWithTheGivenPageHandle() {
        let readerPostServiceRemote = ReaderPostServiceRemote(wordPressComRestApi: mockRemoteApi)

        readerPostServiceRemote.fetchPosts(for: ["dogs"], page: "foobar", success: { _, _ in }, failure: { _ in })

        XCTAssertTrue(mockRemoteApi.URLStringPassedIn?.contains("&page_handle=foobar") ?? false)
    }
}
