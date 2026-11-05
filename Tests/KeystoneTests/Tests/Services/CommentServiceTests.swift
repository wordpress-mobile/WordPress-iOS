import Foundation
import XCTest

@testable import WordPress
@testable import WordPressData

final class CommentServiceTests: CoreDataTestCase {

    private var remoteMock: CommentServiceRemoteRESTMock!
    private var service: CommentService!

    // MARK: Lifecycle

    override func setUp() {
        super.setUp()

        contextManager.useAsSharedInstance(untilTestFinished: self)
        remoteMock = CommentServiceRemoteRESTMock()

        let remoteFactory = CommentServiceRemoteFactoryMock()
        remoteFactory.restRemote = remoteMock
        service = CommentService(coreDataStack: contextManager, commentServiceRemoteFactory: remoteFactory)
    }

    override func tearDown() {
        super.tearDown()

        service = nil
        remoteMock = nil
    }

    // MARK: Helpers

    private func createRemoteLikeUser() -> RemoteLikeUser {
        let userDict: [String: Any] = [ "ID": NSNumber(value: 123),
                                        "login": "johndoe",
                                        "name": "John Doe",
                                        "site_ID": NSNumber(value: 456),
                                        "avatar_URL": "avatar URL",
                                        "date_liked": "2021-02-09 08:34:43"
        ]

        return RemoteLikeUser(dictionary: userDict, commentID: NSNumber(value: 1), siteID: NSNumber(value: 2))
    }
}

// MARK: - Tests

extension CommentServiceTests {

    // MARK: Fetch Likes

    func testFetchingCommentLikesSuccessfullyShouldCallSuccessBlock() {
        // Arrange
        let commentID = NSNumber(value: 1)
        let siteID = NSNumber(value: 2)
        let expectedUsers = [createRemoteLikeUser()]
        try! mainContext.save()
        remoteMock.remoteUsersToReturnOnGetLikes = expectedUsers

        // Act
        let exp = expectation(description: "Fetch comment likes should succeed")
        self.service.getLikesFor(commentID: commentID, siteID: siteID, success: { users, _, likesPerPage in
            // Assert
            XCTAssertNotNil(users)
            XCTAssertEqual(users.count, 1)
            XCTAssertGreaterThan(likesPerPage, 0)
            exp.fulfill()
        },
        failure: { _ in
            XCTFail("This closure should not be called")
        })
        wait(for: [exp], timeout: 2)
    }

    func testFailingFetchCommentLikesShouldCallFailureBlock() {
        // Arrange
        let commentID = NSNumber(value: 1)
        let siteID = NSNumber(value: 2)
        try! mainContext.save()
        remoteMock.fetchLikesShouldSucceed = false

        // Act
        let exp = expectation(description: "Fetch comment likes should fail")
        self.service.getLikesFor(commentID: commentID, siteID: siteID, success: { _, _, _ in
            XCTFail("this closure should not be called")
        },
        failure: { _ in
            exp.fulfill()
        })
        wait(for: [exp], timeout: 2)
    }

    // MARK: Comments Snippet

    func testReplyToPostUsesTheServerCommentIDInHierarchy() {
        let post = makeReaderPost()
        remoteMock.replyToReturn = makeRemoteComment(id: 42)

        let exp = expectation(description: "Reply should succeed")
        service.reply(to: post, content: "Reply") { comment in
            XCTAssertEqual(comment?.hierarchy, "0000000042")
            exp.fulfill()
        } failure: { error in
            XCTFail("Unexpected error: \(String(describing: error))")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2)
    }
}

// MARK: - Comments Snippet Helpers

private extension CommentServiceTests {
    static let postID: NSNumber = 2

    func makeReaderPost() -> ReaderPost {
        let post = ReaderPost(context: mainContext)
        post.siteID = 1
        post.postID = Self.postID
        contextManager.saveContextAndWait(mainContext)
        return post
    }

    func makeRemoteComment(id: Int, parentID: Int = 0) -> RemoteComment {
        let comment = RemoteComment()
        comment.commentID = NSNumber(value: id)
        comment.parentID = NSNumber(value: parentID)
        comment.postID = Self.postID
        comment.status = CommentStatusType.approved.description
        comment.content = "Comment \(id)"
        comment.date = Date()
        return comment
    }
}

// MARK: - Mocks

private class CommentServiceRemoteFactoryMock: CommentServiceRemoteFactory {

    var restRemote: CommentServiceRemoteREST = CommentServiceRemoteRESTMock()

    override func restRemote(siteID: NSNumber, api: WordPressComRestApi) -> CommentServiceRemoteREST {
        return restRemote
    }
}

private class CommentServiceRemoteRESTMock: CommentServiceRemoteREST {

    // related to fetching likes
    var fetchLikesShouldSucceed: Bool = true
    var remoteUsersToReturnOnGetLikes = [RemoteLikeUser]()
    var totalLikes: NSNumber = 3

    override func getLikesForCommentID(_ commentID: NSNumber,
                                       count: NSNumber,
                                       before: String?,
                                       excludeUserIDs: [NSNumber]?,
                                       success: (([RemoteLikeUser], NSNumber) -> Void)!,
                                       failure: ((Error?) -> Void)!) {
        DispatchQueue.global().async {
            if self.fetchLikesShouldSucceed {
                success(self.remoteUsersToReturnOnGetLikes, self.totalLikes)
            } else {
                failure(nil)
            }
        }
    }

    // related to syncing comments
    var replyToReturn: RemoteComment?

    override func replyToPost(
        withID postID: NSNumber,
        content: String,
        success: ((RemoteComment?) -> Void)?,
        failure: ((Error?) -> Void)?
    ) {
        let reply = replyToReturn
        DispatchQueue.global().async {
            success?(reply)
        }
    }
}
