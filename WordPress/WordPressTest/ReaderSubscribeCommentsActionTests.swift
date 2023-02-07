import XCTest
@testable import WordPress

final class ReaderSubscribeCommentsActionTests: CoreDataTestCase {
    let sut = ReaderSubscribeCommentsAction()

    func testExecuteSuccessInvokesCompletion() {
        let readerPost = ReaderPost(context: self.mainContext)

        guard let service = MockFollowCommentsService(subscribeSuccess: true, notificationSuccess: true, post: readerPost) else {
            XCTFail("MockFollowCommentsService instantiation failed.")
            return
        }

        let testExpectation = expectation(description: "Must be fulfilled on execute.")

        sut.execute(
            with: readerPost,
            context: mainContext,
            followCommentsService: service, sourceViewController: UIViewController()) {
                XCTAssertEqual(service.toggleNotificationSettingsCallCount, 1)
                XCTAssertEqual(service.toggleSubscribedCallCount, 1)
                testExpectation.fulfill()
            }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testExecuteSubscribeFailureDoesNotInvokeToggleNotification() {
        let readerPost = ReaderPost(context: self.mainContext)

        guard let service = MockFollowCommentsService(subscribeSuccess: false, notificationSuccess: true, post: readerPost) else {
            XCTFail("MockFollowCommentsService instantiation failed.")
            return
        }

        let testExpectation = expectation(description: "Must be fulfilled on execute.")

        sut.execute(
            with: readerPost,
            context: mainContext,
            followCommentsService: service,
            sourceViewController: UIViewController(),
            completion: nil) { error in
                XCTAssertEqual(service.toggleSubscribedCallCount, 1)
                XCTAssertEqual(service.toggleNotificationSettingsCallCount, 0)
                testExpectation.fulfill()
            }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testExecuteNotificationFailureInvokesFailureHandler() {
        let readerPost = ReaderPost(context: self.mainContext)

        guard let service = MockFollowCommentsService(subscribeSuccess: true, notificationSuccess: false, post: readerPost) else {
            XCTFail("MockFollowCommentsService instantiation failed.")
            return
        }

        let testExpectation = expectation(description: "Must be fulfilled on execute.")

        sut.execute(
            with: readerPost,
            context: mainContext,
            followCommentsService: service,
            sourceViewController: UIViewController(),
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

    required init?(post: ReaderPost, coreDataStack: CoreDataStack, remote: ReaderPostServiceRemote) {
        fatalError("unsupported initialiser")
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
