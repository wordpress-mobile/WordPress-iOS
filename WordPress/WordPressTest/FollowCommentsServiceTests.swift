import XCTest
import WordPressKit

@testable import WordPress

class FollowCommentsServiceTests: XCTestCase {

    private var contextManager: TestContextManager!

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        contextManager = TestContextManager()
    }

    override func tearDown() {
        ContextManager.overrideSharedInstance(nil)
        super.tearDown()
    }

    // MARK: - Helpers

    func seedReaderPost() -> ReaderPost {
        let context = contextManager.mainContext
        let post = NSEntityDescription.insertNewObject(forEntityName: ReaderPost.classNameWithoutNamespaces(), into: context) as! ReaderPost
        post.siteID = NSNumber(value: 0)
        post.postID = NSNumber(value: 0)
        // Note that we don't actually need to save the context,
        // since we're just using this ReaderPost to instantiate FollowCommentsService.
        return post
    }

    // MARK: - Tests

    func testToggleSubscriptionToUnsubscribed() {
        // Arrange
        let remoteMock = ReaderPostServiceRemoteMock()
        let testPost = seedReaderPost()
        let followCommentsService = FollowCommentsService(post: testPost, remote: remoteMock)!
        let isSubscribed = true

        // Act
        followCommentsService.toggleSubscribed(isSubscribed, success: {}, failure: { _ in })

        // Assert
        XCTAssertFalse(remoteMock.subscribeToPostCalled, "subscribeToPost should not be called")
        XCTAssertTrue(remoteMock.unsubscribeFromPostCalled, "unsubscribeFromPost should be called")

    }

    func testToggleSubscriptionToSubscribed() {
        // Arrange
        let remoteMock = ReaderPostServiceRemoteMock()
        let testPost = seedReaderPost()
        let followCommentsService = FollowCommentsService(post: testPost, remote: remoteMock)!
        let isSubscribed = false

        // Act
        followCommentsService.toggleSubscribed(isSubscribed, success: {}, failure: { _ in })

        // Assert
        XCTAssertTrue(remoteMock.subscribeToPostCalled, "subscribeToPost should be called")
        XCTAssertFalse(remoteMock.unsubscribeFromPostCalled, "unsubscribeFromPost should not be called")
    }

    // MARK: - Mocks / Tester

    class ReaderPostServiceRemoteMock: ReaderPostServiceRemote {

        var subscribeToPostCalled = false
        var unsubscribeFromPostCalled = false

        override func subscribeToPost(with postID: Int,
                                      for siteID: Int,
                                      success: @escaping () -> Void,
                                      failure: @escaping (Error?) -> Void) {
            subscribeToPostCalled = true
        }

        override func unsubscribeFromPost(with postID: Int,
                                          for siteID: Int,
                                          success: @escaping () -> Void,
                                          failure: @escaping (Error) -> Void) {
            unsubscribeFromPostCalled = true
        }
    }
}
