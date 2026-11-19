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

    func testSyncCommentsSnippetKeepsThreadsAfterTheSnippet() {
        let post = makeReaderPost()
        syncFirstPage(of: post, comments: [1, 2, 3, 4, 5].map { makeRemoteComment(id: $0) })

        syncSnippet(of: post, comments: [1, 2].map { makeRemoteComment(id: $0) })

        XCTAssertEqual(commentIDs(of: post), [1, 2, 3, 4, 5])
    }

    func testSyncCommentsSnippetDeletesCommentsMissingFromItsThreads() {
        let post = makeReaderPost()
        syncFirstPage(
            of: post,
            comments: [
                makeRemoteComment(id: 1),
                makeRemoteComment(id: 10, parentID: 1),
                makeRemoteComment(id: 2),
                makeRemoteComment(id: 3),
                makeRemoteComment(id: 4)
            ]
        )

        // Reply 10 and comment 2 were deleted on the server. Comment 4 is after the snippet.
        syncSnippet(of: post, comments: [1, 3].map { makeRemoteComment(id: $0) })

        XCTAssertEqual(commentIDs(of: post), [1, 3, 4])
    }

    func testSyncCommentsSnippetDeletesTrailingCommentsWhenThreadsRunOut() {
        let post = makeReaderPost()
        syncFirstPage(of: post, comments: [1, 2].map { makeRemoteComment(id: $0) })

        // The snippet asks for two threads. Comment 2 was deleted on the server, so only one comes back.
        syncSnippet(of: post, comments: [makeRemoteComment(id: 1)])

        XCTAssertEqual(commentIDs(of: post), [1])
    }

    func testSyncFirstPageDeletesCommentsMissingFromThePage() {
        let post = makeReaderPost()
        syncFirstPage(of: post, comments: [1, 2, 3, 4, 5].map { makeRemoteComment(id: $0) })

        syncFirstPage(of: post, comments: [1, 2].map { makeRemoteComment(id: $0) })

        XCTAssertEqual(commentIDs(of: post), [1, 2])
    }

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

    func syncFirstPage(of post: ReaderPost, comments: [RemoteComment]) {
        remoteMock.commentsToReturnOnSync = comments
        let exp = expectation(description: "Page sync should succeed")
        service.syncHierarchicalComments(for: post, page: 1) { _, _ in
            exp.fulfill()
        } failure: { error in
            XCTFail("Unexpected error: \(String(describing: error))")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2)
    }

    func syncSnippet(of post: ReaderPost, comments: [RemoteComment]) {
        remoteMock.commentsToReturnOnSync = comments
        let exp = expectation(description: "Snippet sync should succeed")
        service.syncCommentsSnippet(for: post, topLevelComments: 2) { _ in
            exp.fulfill()
        } failure: { error in
            XCTFail("Unexpected error: \(String(describing: error))")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2)
    }

    func commentIDs(of post: ReaderPost) -> [Int32] {
        let comments = post.comments as? Set<Comment> ?? []
        return comments.map(\.commentID).sorted()
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
    var commentsToReturnOnSync = [RemoteComment]()
    var replyToReturn: RemoteComment?

    override func syncHierarchicalComments(
        forPost postID: NSNumber,
        page: UInt,
        number: UInt,
        success: (([Any]?, NSNumber) -> Void)?,
        failure: ((Error?) -> Void)?
    ) {
        let comments = commentsToReturnOnSync
        DispatchQueue.global().async {
            success?(comments, NSNumber(value: comments.count))
        }
    }

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
