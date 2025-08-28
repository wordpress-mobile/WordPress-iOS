import Foundation

import XCTest

@testable import WordPressKit

class ReaderTopicServiceRemoteInterestsTests: RemoteTestCase, RESTTestable {
    let mockRemoteApi = MockWordPressComRestApi()
    var readerTopicServiceRemote: ReaderTopicServiceRemote!

    override func setUp() {
        super.setUp()

        readerTopicServiceRemote = ReaderTopicServiceRemote(wordPressComRestApi: getRestApi())
    }

    // Return an array of interests
    //
    func testReturnInterests() {
        let expect = expectation(description: "Get reader interests returns successfully")
        stubRemoteResponse("read/interests", filename: "reader-interests-success.json", contentType: .ApplicationJSON)

        readerTopicServiceRemote.fetchInterests({ (interests) in
            XCTAssertTrue(interests.count == 5)
            expect.fulfill()
        }, failure: { _ in })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testValidInterestsOrder() {
        let expect = expectation(description: "Get reader interests returns successfully")
        stubRemoteResponse("read/interests", filename: "reader-interests-success.json", contentType: .ApplicationJSON)

        // Title, slug
        let expectedInterests = [
            ["One", "one"],
            ["Two", "two"],
            ["Three", "three"],
            ["Four", "four"],
            ["Five", "five"]
        ]
        readerTopicServiceRemote.fetchInterests({ (interests) in
            let mapped = interests.map { return [$0.title, $0.slug ]}

            XCTAssertEqual(mapped, expectedInterests)

            expect.fulfill()
        }, failure: { _ in })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    // Test failure block is called correctly
    //
    func testReturnError() {
        let expect = expectation(description: "Get reader interests fails")
        stubRemoteResponse("read/interests", filename: "reader-interests-success.json", contentType: .ApplicationJSON, status: 503)

        readerTopicServiceRemote.fetchInterests({ _ in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            XCTAssertNotNil(error)
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testPathForTopic() {
        let urlWithoutTrailingSlash = URL(string: "https://public-api.wordpress.com")!
        let urlWithTrailingSlash = URL(string: "https://public-api.wordpress.com/")!

        XCTAssertEqual(
            ReaderTopicServiceRemote(wordPressComRestApi: .init(baseURL: urlWithoutTrailingSlash)).pathForTopic(slug: "foo"),
            "https://public-api.wordpress.com/rest/v1.2/read/tags/foo/posts"
        )
        XCTAssertEqual(
            ReaderTopicServiceRemote(wordPressComRestApi: .init(baseURL: urlWithTrailingSlash)).pathForTopic(slug: "foo"),
            "https://public-api.wordpress.com/rest/v1.2/read/tags/foo/posts"
        )
    }

}
