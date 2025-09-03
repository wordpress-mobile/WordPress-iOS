import Foundation
import XCTest

@testable import WordPressKit

class ReaderPostServiceRelatedPostsTests: RemoteTestCase, RESTTestable {

    let mockRemoteApi = MockWordPressComRestApi()
    var readerPostServiceRemote: ReaderPostServiceRemote!

    let siteID = 70135762
    let postID = 147744

    var fetchRelatedPostsEndpoint: String {
        return "read/site/\(siteID)/post/\(postID)/related"
    }

    override func setUp() {
        super.setUp()

        readerPostServiceRemote = ReaderPostServiceRemote(wordPressComRestApi: getRestApi())
    }

    // Return an array of interests
    //
    func testReturnRelatedPosts() {
        let expect = expectation(description: "Get reader related posts successfully")
        stubRemoteResponse(fetchRelatedPostsEndpoint,
                           filename: "reader-post-related-posts-success.json",
                           contentType: .ApplicationJSON)

        readerPostServiceRemote.fetchRelatedPosts(for: postID, from: siteID, success: { relatedPosts in
            XCTAssertTrue(relatedPosts.count == 2)
            expect.fulfill()
        }, failure: { _ in })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    // Test failure block is called correctly
    //
    func testReturnError() {
        let expect = expectation(description: "Get reader related posts fails")
        stubRemoteResponse(fetchRelatedPostsEndpoint,
                           filename: "reader-post-related-posts-success.json",
                           contentType: .ApplicationJSON,
                           status: 503)

        readerPostServiceRemote.fetchRelatedPosts(for: postID, from: siteID, success: { _ in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            XCTAssertNotNil(error)
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }
}
