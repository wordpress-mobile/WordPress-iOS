import XCTest
@testable import WordPress

final class ReaderSubscribeCommentsActionTests: XCTestCase {
    let sut = ReaderSubscribeCommentsAction()
    private var contextManager: TestContextManager!
    private var context: NSManagedObjectContext!

    func testExecuteSuccessInvokesCompletion() {
        contextManager = TestContextManager()
        context = contextManager.mainContext
        let readerPost = ReaderPost(context: self.context!)

        guard let service = MockFollowCommentsService(subscribeSuccess: true, notificationSuccess: true, post: readerPost) else {
            XCTFail("MockFollowCommentsService instantiation failed.")
            return
        }

        let testExpectation = expectation(description: "Must be fulfilled on execute.")

        sut.execute(
            with: readerPost,
            context: context,
            followCommentsService: service) {
                XCTAssertEqual(service.toggleNotificationSettingsCallCount, 1)
                XCTAssertEqual(service.toggleSubscribedCallCount, 1)
                testExpectation.fulfill()
            }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testExecuteSubscribeFailureDoesNotInvokeToggleNotification() {
        contextManager = TestContextManager()
        context = contextManager.mainContext
        let readerPost = ReaderPost(context: self.context!)

        guard let service = MockFollowCommentsService(subscribeSuccess: false, notificationSuccess: true, post: readerPost) else {
            XCTFail("MockFollowCommentsService instantiation failed.")
            return
        }

        let testExpectation = expectation(description: "Must be fulfilled on execute.")

        sut.execute(
            with: readerPost,
            context: context,
            followCommentsService: service,
            completion: nil) { error in
                XCTAssertEqual(service.toggleSubscribedCallCount, 1)
                XCTAssertEqual(service.toggleNotificationSettingsCallCount, 0)
                testExpectation.fulfill()
            }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testExecuteNotificationFailureInvokesFailureHandler() {
        contextManager = TestContextManager()
        context = contextManager.mainContext
        let readerPost = ReaderPost(context: self.context!)

        guard let service = MockFollowCommentsService(subscribeSuccess: true, notificationSuccess: false, post: readerPost) else {
            XCTFail("MockFollowCommentsService instantiation failed.")
            return
        }

        let testExpectation = expectation(description: "Must be fulfilled on execute.")

        sut.execute(
            with: readerPost,
            context: context,
            followCommentsService: service,
            completion: nil) { error in
                XCTAssertEqual(service.toggleSubscribedCallCount, 1)
                XCTAssertEqual(service.toggleNotificationSettingsCallCount, 1)
                testExpectation.fulfill()
            }

        waitForExpectations(timeout: 1, handler: nil)
    }
}

private class MockFollowCommentsService: FollowCommentsService {
    var toggleNotificationSettingsCallCount = 0
    var toggleSubscribedCallCount = 0

    private var subscribeSuccess: Bool = true
    private var notificationSuccess: Bool = true

    init?(subscribeSuccess: Bool, notificationSuccess: Bool, post: ReaderPost) {
        self.subscribeSuccess = subscribeSuccess
        self.notificationSuccess = notificationSuccess
        super.init(post: post)
    }

    @objc required init?(post: ReaderPost, remote: ReaderPostServiceRemote = ReaderPostServiceRemote.withDefaultApi()) {
        super.init(post: post, remote: remote)
    }

    @objc override func toggleSubscribed(
        _ isSubscribed: Bool,
        success: @escaping (Bool) -> Void,
        failure: @escaping (Error?) -> Void) {
            toggleSubscribedCallCount += 1

            if subscribeSuccess {
                success(true)
            } else {
                failure(nil)
            }
        }

    @objc override func toggleNotificationSettings(
        _ isNotificationsEnabled: Bool,
        success: @escaping () -> Void,
        failure: @escaping (Error?) -> Void) {
            toggleNotificationSettingsCallCount += 1

            if notificationSuccess {
                success()
            } else {
                failure(nil)
            }
        }
}
