import XCTest
@testable import WordPress

final class LikeCommentActionTests: XCTestCase {
    private class TestableLikeComment: LikeComment {
        let service = MockNotificationActionsService(managedObjectContext: TestContextManager.sharedInstance().mainContext)
        override var actionsService: NotificationActionsService? {
            return service
        }
    }

    private class MockNotificationActionsService: NotificationActionsService {
        var likeWasCalled: Bool = false
        var unlikeWasCalled: Bool = false

        override func likeCommentWithBlock(_ block: FormattableCommentContent, completion: ((Bool) -> Void)?) {
            likeWasCalled = true
            completion?(true)
        }

        override func unlikeCommentWithBlock(_ block: FormattableCommentContent, completion: ((Bool) -> Void)?) {
            unlikeWasCalled = true
            completion?(true)
        }
    }

    private var action: LikeComment?
    private let utility = NotificationUtility()

    private struct Constants {
        static let initialStatus: Bool = false
    }

    override func setUp() {
        super.setUp()
        utility.setUp()
        action = TestableLikeComment(on: Constants.initialStatus)
        makeNetworkAvailable()
    }

    override func tearDown() {
        action = nil
        makeNetworkUnavailable()
        utility.tearDown()
        super.tearDown()
    }

    func testStatusPassedInInitialiserIsPreserved() {
        XCTAssertEqual(action?.on, Constants.initialStatus)
    }

    func testSettingActionOnSetsExpectedTitle() {
        action?.on = true

        XCTAssertEqual(action?.actionTitle, LikeComment.TitleStrings.like)
    }

    func testSettingActionOffSetsExpectedTitle() {
        action?.on = false

        XCTAssertEqual(action?.actionTitle, LikeComment.TitleStrings.unlike)
    }

    func testExecuteCallsUnlikeWhenActionIsOn() {
        action?.on = true

        action?.execute(context: utility.mockCommentContext())

        guard let mockService = action?.actionsService as? MockNotificationActionsService else {
            XCTFail()
            return
        }

        XCTAssertTrue(mockService.unlikeWasCalled)
    }

    func testExecuteUpdatesActionTitleWhenActionIsOn() {
        action?.on = true

        action?.execute(context: utility.mockCommentContext())

        XCTAssertEqual(action?.actionTitle, LikeComment.TitleStrings.like)
    }

    func testExecuteCallsLikeWhenActionIsOff() {
        action?.on = false

        action?.execute(context: utility.mockCommentContext())

        guard let mockService = action?.actionsService as? MockNotificationActionsService else {
            XCTFail()
            return
        }

        XCTAssertTrue(mockService.likeWasCalled)
    }

    func testExecuteUpdatesActionTitleWhenActionIsOff() {
        action?.on = false

        action?.execute(context: utility.mockCommentContext())

        XCTAssertEqual(action?.actionTitle, LikeComment.TitleStrings.unlike)
    }
}
