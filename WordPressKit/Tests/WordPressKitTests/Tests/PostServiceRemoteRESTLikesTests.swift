import Foundation
import XCTest

@testable import WordPressKit

final class PostServiceRemoteRESTLikesTests: RemoteTestCase, RESTTestable {
    private let fetchPostLikesSuccessFilename = "post-likes-success.json"
    private let fetchPostLikesFailureFilename = "post-likes-failure.json"
    private let siteId = 0
    private let postId = 1
    private var remote: PostServiceRemoteREST!
    private var postLikesEndpoint: String {
        return "sites/\(siteId)/posts/\(postId)/likes"
    }

    override func setUp() {
        super.setUp()
        remote = PostServiceRemoteREST(wordPressComRestApi: getRestApi(), siteID: NSNumber(value: siteId))
    }

    override func tearDown() {
        remote = nil
        super.tearDown()
    }

    // MARK: Tests

    func testThatFetchPostLikesWorks() {
        let expect = expectation(description: "Fetch likes should succeed")

        stubRemoteResponse(postLikesEndpoint, filename: fetchPostLikesSuccessFilename, contentType: .ApplicationJSON)
        remote.getLikesForPostID(NSNumber(value: postId),
                                 count: 0,
                                 before: nil,
                                 excludeUserIDs: nil,
                                 success: { users, totalLikes in
            guard let user = users.first else {
                XCTFail("Failed to retrieve mock post likes")
                return
            }

            XCTAssertEqual(user.userID, NSNumber(value: 12345))
            XCTAssertEqual(user.username, "johndoe")
            XCTAssertEqual(user.displayName, "John Doe")
            XCTAssertEqual(user.primaryBlogID, NSNumber(value: 54321))
            XCTAssertEqual(user.avatarURL, "avatar URL")
            XCTAssertEqual(user.bio, "user bio")
            XCTAssertEqual(user.likedPostID, NSNumber(value: 1))
            XCTAssertEqual(user.likedSiteID, NSNumber(value: 0))
            XCTAssertEqual(totalLikes, NSNumber(value: 3))
            expect.fulfill()

        }, failure: { _ in
            XCTFail("This callback shouldn't get called")
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testFailureBlockCalledWhenFetchingFails() {
        let expect = expectation(description: "Failure block should be called when fetching post likes fails")

        stubRemoteResponse(postLikesEndpoint, filename: fetchPostLikesFailureFilename, contentType: .ApplicationJSON, status: 403)
        remote.getLikesForPostID(NSNumber(value: postId),
                                 count: 0,
                                 before: nil,
                                 excludeUserIDs: nil,
                                 success: { _, _ in
        XCTFail("This callback shouldn't get called")
        }, failure: { error in
            XCTAssertNotNil(error)
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testThatParsingPreferredBlogWorks() {
        let expect = expectation(description: "Fetch likes should succeed")

        stubRemoteResponse(postLikesEndpoint, filename: fetchPostLikesSuccessFilename, contentType: .ApplicationJSON)
        remote.getLikesForPostID(NSNumber(value: postId),
                                 count: 0,
                                 before: nil,
                                 excludeUserIDs: nil,
                                 success: { users, _ in
            guard let userWithPreferredBlog = users.first,
                  let userWithoutPreferredBlog = users.last else {
                XCTFail("Failed to retrieve mock post likes")
                return
            }

            XCTAssertEqual(userWithPreferredBlog.preferredBlog?.blogUrl, "blog URL")
            XCTAssert((userWithoutPreferredBlog.preferredBlog == nil), "preferredBlog should be nil.")
            expect.fulfill()

        }, failure: { _ in
            XCTFail("This callback shouldn't get called")
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }
}
