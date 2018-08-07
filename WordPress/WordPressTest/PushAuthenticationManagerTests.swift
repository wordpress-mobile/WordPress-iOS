import Foundation
import XCTest
@testable import WordPress
import WordPressShared

class PushAuthenticationManagerTests: XCTestCase {

    class MockUIAlertControllerProxy: UIAlertControllerProxy {

        var titlePassedIn: String?
        var messagePassedIn: String?
        var cancelButtonTitlePassedIn: String?
        var otherButtonTitlesPassedIn: [AnyObject]?
        var tapBlockPassedIn: UIAlertControllerCompletionBlock?
        var showWithTitleCalled = false

        override func show(withTitle title: String?, message: String?, cancelButtonTitle: String?, otherButtonTitles: [Any]?, tap tapBlock: UIAlertControllerCompletionBlock?) -> UIAlertController {
            showWithTitleCalled = true
            titlePassedIn = title
            messagePassedIn = message
            cancelButtonTitlePassedIn = cancelButtonTitle
            otherButtonTitlesPassedIn = otherButtonTitles as [AnyObject]?
            tapBlockPassedIn = tapBlock
            return UIAlertController()
        }
    }

    class MockPushAuthenticationService: PushAuthenticationService {

        var tokenPassedIn: String?
        var completionBlockPassedIn: ((Bool) -> ())?
        var authorizedLoginCalled = false
        var numberOfTimesAuthorizedLoginCalled = 0

        override func authorizeLogin(_ token: String, completion: @escaping ((Bool) -> ())) {
            authorizedLoginCalled = true
            numberOfTimesAuthorizedLoginCalled += 1
            tokenPassedIn = token
            completionBlockPassedIn = completion
        }
    }

    var mockPushAuthenticationService = MockPushAuthenticationService(managedObjectContext: TestContextManager().mainContext)
    var mockAlertControllerProxy = MockUIAlertControllerProxy()
    var pushAuthenticationManager: PushAuthenticationManager?
    var approvalAlertController: UIAlertController!

    override func setUp() {
        super.setUp()
        pushAuthenticationManager = PushAuthenticationManager(pushAuthenticationService: mockPushAuthenticationService)
        pushAuthenticationManager?.alertControllerProxy = mockAlertControllerProxy

        approvalAlertController = UIAlertController()
        approvalAlertController.addCancelActionWithTitle("Ignore", handler: nil)
        approvalAlertController.addDefaultActionWithTitle("Approve", handler: nil)
    }

    func testIsPushAuthenticationNotificationReturnsTrueWhenPassedTheCorrectPushAuthenticationNoteType() {
        let result = pushAuthenticationManager!.isAuthenticationNotification(["type": "push_auth"])

        XCTAssertTrue(result, "Should be true when the type is 'push_auth'")
    }

    func testIsPushAuthenticationNotificationReturnsFalseWhenPassedIncorrectPushAuthenticationNoteType() {
        let result = pushAuthenticationManager!.isAuthenticationNotification(["type": "not_push"])

        XCTAssertFalse(result, "Should be false when the type is not 'push_auth'")
    }

    var expiredAuthenticationDictionary: NSDictionary {
       return ["expires": TimeInterval(3)]
    }

    var validAuthenticationDictionary: NSMutableDictionary {
        return ["push_auth_token": "token", "aps": [ "alert": "an alert"]]
    }

    func testHandlePushAuthenticationNotificationShowsTheLoginExpiredAlertIfNotificationHasExpired() {
        pushAuthenticationManager!.handleAuthenticationNotification(expiredAuthenticationDictionary)

        XCTAssertTrue(mockAlertControllerProxy.showWithTitleCalled, "Should show the login expired alert if the notification has expired")
        XCTAssertEqual(mockAlertControllerProxy.titlePassedIn, NSLocalizedString("Login Request Expired", comment: "Error message shown when a user is trying to login."), "")
    }

    func testHandlePushAuthenticationNotificationDoesNotShowTheLoginExpiredAlertIfNotificationHasNotExpired() {
        pushAuthenticationManager!.handleAuthenticationNotification([:])

        XCTAssertFalse(mockAlertControllerProxy.showWithTitleCalled, "Should not show the login expired alert if the notification hasn't expired")
    }

    func testHandlePushAuthenticationNotificationWithBlankTokenDoesNotShowLoginVerificationAlert() {
        let pushNotificationDictionary = validAuthenticationDictionary
        pushNotificationDictionary.removeObject(forKey: "push_auth_token")

        pushAuthenticationManager!.handleAuthenticationNotification(pushNotificationDictionary)

        XCTAssertFalse(mockAlertControllerProxy.showWithTitleCalled, "Should not show the login verification")
    }

    func testHandlePushAuthenticationNotificationWithBlankMessageDoesNotShowLoginVerificationAlert() {
        pushAuthenticationManager!.handleAuthenticationNotification(["push_auth_token": "token"])

        XCTAssertFalse(mockAlertControllerProxy.showWithTitleCalled, "Should not show the login verification")
    }

    func testHandlePushAuthenticationNotificationWithValidDataShouldShowLoginVerification() {
        pushAuthenticationManager!.handleAuthenticationNotification(validAuthenticationDictionary)

        XCTAssertTrue(mockAlertControllerProxy.showWithTitleCalled, "Should show the login verification")
        XCTAssertEqual(mockAlertControllerProxy.titlePassedIn, NSLocalizedString("Verify Log In", comment: "Title of a prompt. A user must verify their login attempt."), "")
    }

    func testHandlePushAuthenticationNotificationShouldAttemptToAuthorizeTheLoginIfTheUserIndicatesTheyWantTo() {
        pushAuthenticationManager!.handleAuthenticationNotification(validAuthenticationDictionary)
        mockAlertControllerProxy.tapBlockPassedIn?(approvalAlertController, 1)

        XCTAssertTrue(mockPushAuthenticationService.authorizedLoginCalled, "Should have attempted to authorize the login")
    }

    func testHandlePushAuthenticationNotificationWhenAttemptingToLoginShouldAttemptToRetryTheLoginIfItFailed() {
        pushAuthenticationManager!.handleAuthenticationNotification(validAuthenticationDictionary)
        mockAlertControllerProxy.tapBlockPassedIn?(approvalAlertController, 1)
        mockPushAuthenticationService.completionBlockPassedIn?(false)

        XCTAssertEqual(mockPushAuthenticationService.numberOfTimesAuthorizedLoginCalled, 2, "Should have attempted to retry a failed login")
    }

    func testHandlePushAuthenticationNotificationShouldNotAttemptToAuthorizeTheLoginIfTheUserIndicatesTheyDontWantTo() {
        pushAuthenticationManager!.handleAuthenticationNotification(validAuthenticationDictionary)
        mockAlertControllerProxy.tapBlockPassedIn?(approvalAlertController, 0)

        XCTAssertFalse(mockPushAuthenticationService.authorizedLoginCalled, "Should not have attempted to authorize the login")
    }
}
