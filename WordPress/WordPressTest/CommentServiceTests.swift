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

    private func createRemoteUser() -> RemoteUser {
         let remoteUser = RemoteUser()
         remoteUser.userID = NSNumber(value: 123)
         remoteUser.primaryBlogID = NSNumber(value: 456)
         remoteUser.username = "johndoe"
         remoteUser.displayName = "John Doe"
         remoteUser.avatarURL = "avatar URL"

         return remoteUser
     }
}

// MARK: - Tests

extension CommentServiceTests {

    // MARK: Fetch Likes

    func testFetchingCommentLikesSuccessfullyShouldCallSuccessBlock() {
        // Arrange
        let commentID = NSNumber(value: 1)
        let siteID = NSNumber(value: 2)
        let expectedUsers = [createRemoteUser()]
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
    var remoteUsersToReturnOnGetLikes: [RemoteUser]? = nil

    override func getLikesForCommentID(_ commentID: NSNumber!, success: (([RemoteUser]?) -> Void)!, failure: ((Error?) -> Void)!) {
        DispatchQueue.global().async {
            if self.fetchLikesShouldSucceed {
                success(self.remoteUsersToReturnOnGetLikes)
            } else {
                failure(nil)
            }
        }
    }
}
