import Foundation
import XCTest

@testable import WordPressKit

class PostServiceRemoteRESTRevisionsTest: RemoteTestCase, RESTTestable {
    private let performRevisionsSuccessFilename = "post-revisions-success.json"
    private let performRevisionsMappingSuccessFilename = "post-revisions-mapping-success.json"
    private let performRevisionsFailureFilename = "post-revisions-failure.json"
    private let siteId = 0
    private let postId = 1
    private var remote: PostServiceRemoteREST!

    private var performEndpoint: String {
        return "sites/\(siteId)/post/\(postId)/diffs"
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

    func testPerformRevisionsSuccessfully() {
        let expect = expectation(description: "Perform Post Revisions successfully")

        stubRemoteResponse(performEndpoint, filename: performRevisionsSuccessFilename, contentType: .ApplicationJSON)
        remote.getPostRevisions(for: siteId,
                                postId: postId,
                                success: { (revisions) in
                                    XCTAssertNotNil(revisions, "Revisions shouldn't be nil")
                                    expect.fulfill()
        }) { (_) in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }
        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testPerformRevisionsFailure() {
        let expect = expectation(description: "Perform Post Revisions failure")

        stubRemoteResponse(performEndpoint, filename: performRevisionsFailureFilename, contentType: .ApplicationJSON)
        remote.getPostRevisions(for: siteId,
                                postId: postId,
                                success: { (_) in
                                    XCTFail("This callback shouldn't get called")
                                    expect.fulfill()
        }) { (error) in
            XCTAssertNotNil(error)
            expect.fulfill()
        }
        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testPerformRevisionsMappingSuccessfully() {
        let expect = expectation(description: "Perform Post Revisions successfully")

        stubRemoteResponse(performEndpoint, filename: performRevisionsMappingSuccessFilename, contentType: .ApplicationJSON)
        remote.getPostRevisions(for: siteId,
                                postId: postId,
                                success: { (revisions) in
                                    XCTAssertNotNil(revisions, "Revisions shouldn't be nil")
                                    XCTAssertNotNil(revisions?.first, "Revision model shouldn't be nil")
                                    XCTAssertNotNil(revisions?.first?.diff, "Revision diff shouldn't be nil")
                                    XCTAssertNotNil(revisions?.first?.diff?.values, "Revision diff values shouldn't be nil")
                                    XCTAssertNotNil(revisions?.first?.diff?.values.totals, "Revision diff values total shouldn't be nil")

                                    let revision = revisions!.first!
                                    let diff = revision.diff!

                                    XCTAssertEqual(revision.id, 93)
                                    XCTAssertEqual(revision.postAuthorId, "136610416")
                                    XCTAssertEqual(revision.postDateGmt, "2018-10-24 15:38:28Z")
                                    XCTAssertEqual(revision.postModifiedGmt, "2018-10-24 15:38:28Z")
                                    XCTAssertEqual(revision.postTitle, "Lorem ipsum dolor sit amet")
                                    XCTAssertEqual(revision.postContent, "Etiam in convallis orci. Dolor sit amet, consectetur adipiscing elit. Cras eget consequat magna, quis gravida sapien.")

                                    XCTAssertEqual(diff.toRevisionId, revision.id)
                                    XCTAssertEqual(diff.values.totals?.totalAdditions, 2)
                                    XCTAssertEqual(diff.values.totals?.totalDeletions, 2)

                                    XCTAssertFalse(diff.values.titleDiffs.isEmpty)
                                    XCTAssertFalse(diff.values.contentDiffs.isEmpty)

                                    XCTAssertEqual(diff.values.titleDiffs.first?.value, "Lorem ipsum dolor sit amet")
                                    XCTAssertEqual(diff.values.titleDiffs.first?.operation, .copy)

                                    XCTAssertEqual(diff.values.contentDiffs[0].value, "Lorem ipsum d")
                                    XCTAssertEqual(diff.values.contentDiffs[0].operation, .del)

                                    XCTAssertEqual(diff.values.contentDiffs[1].value, "Etiam in convallis orci. D")
                                    XCTAssertEqual(diff.values.contentDiffs[1].operation, .add)

                                    XCTAssertEqual(diff.values.contentDiffs[2].value, "olor sit amet, consectetur adipiscing elit. ")
                                    XCTAssertEqual(diff.values.contentDiffs[2].operation, .copy)

                                    XCTAssertEqual(diff.values.contentDiffs[3].value, "Aenean et urna libero.")
                                    XCTAssertEqual(diff.values.contentDiffs[3].operation, .del)

                                    XCTAssertEqual(diff.values.contentDiffs[4].value, "Cras eget consequat magna, quis gravida sapien.")
                                    XCTAssertEqual(diff.values.contentDiffs[4].operation, .add)

                                    XCTAssertEqual(diff.values.contentDiffs[5].value, "\n")
                                    XCTAssertEqual(diff.values.contentDiffs[5].operation, .copy)

                                    expect.fulfill()
        }) { (_) in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }
        waitForExpectations(timeout: timeout, handler: nil)
    }
}
