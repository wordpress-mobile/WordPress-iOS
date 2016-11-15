import XCTest
@testable import WordPress

class CommentServiceRemoteRESTTests: XCTestCase {

    let mockRemoteApi = MockWordPressComRestApi()
    var commentServiceRemote: CommentServiceRemoteREST!
    let siteID = NSNumber(integer: 999999)

    override func setUp() {
        super.setUp()
        commentServiceRemote = CommentServiceRemoteREST(wordPressComRestApi: mockRemoteApi, siteID: siteID)
    }

    func mockComment() -> RemoteComment {
        let comment = RemoteComment()
        comment.commentID = 10
        comment.postID = 100
        comment.content = "Content"
        return comment
    }

    func testGetCommentCorrectPath() {
        commentServiceRemote.getCommentsWithMaximumCount(siteID.integerValue, success:nil, failure: nil)
        XCTAssertTrue(mockRemoteApi.getMethodCalled, "Wrong method, expected GET got \(mockRemoteApi.methodCalled())")
        XCTAssertEqual(mockRemoteApi.URLStringPassedIn, "v1.1/sites/\(siteID)/comments", "Wrong path")
    }

    func testGetCommentsSucess() {

        let response = ["comments" : [["ID" : 1], ["ID" : 2]]]
        var comments : [RemoteComment] = []
        commentServiceRemote.getCommentsWithMaximumCount(siteID.integerValue,
            success: {
                if let remoteComments = $0 as? [RemoteComment] {
                    comments = remoteComments
                }
            },
            failure: nil)
        mockRemoteApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertFalse(comments.isEmpty, "Comments shouldn't be empty")
    }

    func testCreateCommentPath() {
        let comment = mockComment()
        commentServiceRemote.createComment(comment, success:nil, failure: nil)
        XCTAssertTrue(mockRemoteApi.postMethodCalled, "Wrong method, expected POST got \(mockRemoteApi.methodCalled())")
        XCTAssertEqual(mockRemoteApi.URLStringPassedIn, "v1.1/sites/\(siteID)/posts/\(comment.postID)/replies/new", "Wrong path")
    }

    func testCreateReplyPath() {
        let comment = mockComment()
        comment.parentID = 200
        commentServiceRemote.createComment(comment, success:nil, failure: nil)
        XCTAssertTrue(mockRemoteApi.postMethodCalled, "Wrong method, expected POST got \(mockRemoteApi.methodCalled())")
        XCTAssertEqual(mockRemoteApi.URLStringPassedIn, "v1.1/sites/\(siteID)/comments/\(comment.parentID)/replies/new", "Wrong path")
    }

    func testCreateComment() {

        let response = ["ID" : 1]
        var comment : RemoteComment? = nil
        commentServiceRemote.createComment(mockComment(),
            success: {
                    comment = $0
            },
            failure: nil)
        mockRemoteApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertNotNil(comment)
    }

    func testReplyPostWithID() {

        let response = ["ID" : 1]
        var comment : RemoteComment? = nil
        commentServiceRemote.replyToPostWithID(1,
            content: "content",
            success: {
                comment = $0
            },
            failure: nil)
        mockRemoteApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertNotNil(comment)
    }

    func testReplyCommentWithID() {

        let response = ["ID" : 1]
        var comment : RemoteComment? = nil
        commentServiceRemote.replyToCommentWithID(1,
            content: "content",
            success: {
                comment = $0
            },
            failure: nil)
        mockRemoteApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertNotNil(comment)
    }

    func testUpdateCommentPath() {
        let comment = mockComment()
        commentServiceRemote.updateComment(comment, success:nil, failure: nil)
        XCTAssertTrue(mockRemoteApi.postMethodCalled, "Wrong method, expected POST got \(mockRemoteApi.methodCalled())")
        XCTAssertEqual(mockRemoteApi.URLStringPassedIn, "v1.1/sites/\(siteID)/comments/\(comment.commentID)", "Wrong path")
    }

    func testUpdateComment() {

        let response = ["ID" : 1]
        var comment : RemoteComment? = nil
        commentServiceRemote.updateComment(mockComment(),
            success: {
                comment = $0
            },
            failure: nil)
        mockRemoteApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertNotNil(comment)
    }

    func testUpdateCommentWithID() {

        let response = ["ID" : 1]
        var success = false
        commentServiceRemote.updateCommentWithID(1,
            content: "context",
            success: {
                success = true
            },
            failure: nil)
        mockRemoteApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertTrue(success)
    }

    func testModerateCommentPath() {
        let comment = mockComment()
        comment.status = "spam"
        commentServiceRemote.moderateComment(comment, success:nil, failure: nil)
        XCTAssertTrue(mockRemoteApi.postMethodCalled, "Wrong method, expected POST got \(mockRemoteApi.methodCalled())")
        XCTAssertEqual(mockRemoteApi.URLStringPassedIn, "v1.1/sites/\(siteID)/comments/\(comment.commentID)", "Wrong path")
    }

    func testModerateComment() {

        let comment = mockComment()
        comment.status = "spam"
        let response = ["ID" : 1]
        var responseComment : RemoteComment? = nil
        commentServiceRemote.moderateComment(comment,
           success: {
            responseComment = $0
            },
           failure: nil)
        mockRemoteApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertNotNil(responseComment)
    }

    func testModerateCommentWithID() {

        let comment = mockComment()
        comment.status = "spam"
        let response = ["ID" : 1]
        var success = false
        commentServiceRemote.moderateCommentWithID(1,
             status: "spam",
             success: {
                success = true
            },
             failure: nil)
        mockRemoteApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertTrue(success)
    }

    func testTrashCommentPath() {
        let comment = mockComment()
        commentServiceRemote.trashComment(comment, success:nil, failure: nil)
        XCTAssertTrue(mockRemoteApi.postMethodCalled, "Wrong method, expected POST got \(mockRemoteApi.methodCalled())")
        XCTAssertEqual(mockRemoteApi.URLStringPassedIn, "v1.1/sites/\(siteID)/comments/\(comment.commentID)/delete", "Wrong path")
    }

    func testTrashComment() {

        let comment = mockComment()
        let response = ["ID" : 1]
        var success = false
        commentServiceRemote.trashComment(comment,
           success: {
            success = true
            },
           failure: nil)
        mockRemoteApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertTrue(success)
    }

    func testTrashCommentWithID() {

        var success = false
        let response = ["ID" : 1]
        commentServiceRemote.trashCommentWithID(1,
            success: {
                success = true
            },
            failure: nil)
        mockRemoteApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertTrue(success)
    }

    func testLikeCommentPath() {
        let comment = mockComment()
        commentServiceRemote.likeCommentWithID(comment.commentID, success:nil, failure: nil)
        XCTAssertTrue(mockRemoteApi.postMethodCalled, "Wrong method, expected POST got \(mockRemoteApi.methodCalled())")
        XCTAssertEqual(mockRemoteApi.URLStringPassedIn, "v1.1/sites/\(siteID)/comments/\(comment.commentID)/likes/new", "Wrong path")
    }

    func testLikeCommentWithID() {

        var success = false
        let response = ["ID" : 1]
        commentServiceRemote.likeCommentWithID(1,
            success: {
                success = true
            },
            failure: nil)
        mockRemoteApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertTrue(success)
    }

    func testUnlikeCommentPath() {
        let comment = mockComment()
        commentServiceRemote.unlikeCommentWithID(comment.commentID, success:nil, failure: nil)
        XCTAssertTrue(mockRemoteApi.postMethodCalled, "Wrong method, expected GET got \(mockRemoteApi.methodCalled())")
        XCTAssertEqual(mockRemoteApi.URLStringPassedIn, "v1.1/sites/\(siteID)/comments/\(comment.commentID)/likes/mine/delete", "Wrong path")
    }

    func testUnlikeCommentWithID() {

        var success = false
        let response = ["ID" : 1]
        commentServiceRemote.unlikeCommentWithID(1,
            success: {
                success = true
            },
            failure: nil)
        mockRemoteApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertTrue(success)
    }
}
