import Foundation
import XCTest

@testable import WordPressKit

class PostServiceRemoteRESTAutosaveTests: RemoteTestCase, RESTTestable {
    private let performPostsAutosaveSuccessFilename = "post-autosave-mapping-success.json"
    private let siteId = 0
    private var remote: PostServiceRemoteREST!
    private var postsEndpoint: String {
        return "sites/\(siteId)/posts"
    }

    override func setUp() {
        super.setUp()
        remote = PostServiceRemoteREST(wordPressComRestApi: getRestApi(), siteID: NSNumber(value: siteId))
    }

    override func tearDown() {
        super.tearDown()
        remote = nil
    }

    // MARK: Perform tests

    func testFetchPostsPerformsAutosaveMappingSuccessfully() {
        let expect = expectation(description: "Fetch posts fetches autosaves successfully")

        stubRemoteResponse(postsEndpoint, filename: performPostsAutosaveSuccessFilename, contentType: .ApplicationJSON)
        remote.getPostsOfType("", options: [:], success: { remotePosts in

            guard let remotePost = remotePosts?.first else {
                XCTFail("Failed to retrieve mock post")
                return
            }

            XCTAssertEqual(remotePost.autosave.identifier?.intValue, 100)
            XCTAssertEqual(remotePost.autosave.authorID, "12345678")
            XCTAssertEqual(remotePost.autosave.postID, 102)
            XCTAssertEqual(remotePost.autosave.title, "Hello, world!")
            XCTAssertEqual(remotePost.autosave.content, "<!-- wp:paragraph -->\n<p>Uno.</p>\n<!-- /wp:paragraph -->")
            XCTAssertEqual(remotePost.autosave.excerpt, "abc")
            XCTAssertEqual(remotePost.autosave.previewURL, "https://hello.wordpress.com/2019/10/28/hello-world/?preview=true&preview_nonce=07346f4e5d")
            XCTAssertEqual(remotePost.autosave.modifiedDate, NSDate.with(wordPressComJSONString: "2019-10-28T02:06:39+00:00"))
            expect.fulfill()
        }, failure: { _ in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })
        waitForExpectations(timeout: timeout, handler: nil)
    }
}
