import Foundation
import Nimble

@testable import WordPress

final class CommentServiceTests: XCTestCase {

    private var remoteMock: CommentServiceRemoteRESTMock!
    private var service: CommentService!
    private var context: NSManagedObjectContext!

    // MARK: Lifecycle

    override func setUp() {
        super.setUp()

        context = TestContextManager().mainContext
        remoteMock = CommentServiceRemoteRESTMock()

        let remoteFactory = CommentServiceRemoteFactoryMock()
        remoteFactory.restRemote = remoteMock
        service = CommentService(managedObjectContext: context, commentServiceRemoteFactory: remoteFactory)
    }

    override func tearDown() {
        super.tearDown()

        service = nil
        remoteMock = nil
        context = nil
        ContextManager.overrideSharedInstance(nil)
    }

    // MARK: Helpers

    private func createRemoteLikeUser() -> RemoteLikeUser {
        let userDict: [String: Any] = [ "ID": NSNumber(value: 123),
                                        "login": "johndoe",
                                        "name": "John Doe",
                                        "site_ID": NSNumber(value: 456),
                                        "avatar_URL": "avatar URL"
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
        try! context.save()
        remoteMock.remoteUsersToReturnOnGetLikes = expectedUsers

        // Act
        waitUntil(timeout: DispatchTimeInterval.seconds(2)) { done in
            self.service.getLikesForCommentID(commentID, siteID: siteID, success: { users in
                // Assert
                expect(users).toNot(beNil())
                expect(users?.count) == 1
                done()
            },
            failure: { _ in
                fail("This closure should not be called")
            })
        }
    }

    func testFailingFetchCommentLikesShouldCallFailureBlock() {
        // Arrange
        let commentID = NSNumber(value: 1)
        let siteID = NSNumber(value: 2)
        try! context.save()
        remoteMock.fetchLikesShouldSucceed = false

        // Act
        waitUntil(timeout: DispatchTimeInterval.seconds(2)) { done in
            self.service.getLikesForCommentID(commentID, siteID: siteID, success: { users in
                fail("this closure should not be called")
            },
            failure: { _ in
                done()
            })
        }
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
    var remoteUsersToReturnOnGetLikes: [RemoteLikeUser]? = nil

    override func getLikesForCommentID(_ commentID: NSNumber!, success: (([RemoteLikeUser]?) -> Void)!, failure: ((Error?) -> Void)!) {
        DispatchQueue.global().async {
            if self.fetchLikesShouldSucceed {
                success(self.remoteUsersToReturnOnGetLikes)
            } else {
                failure(nil)
            }
        }
    }
}
