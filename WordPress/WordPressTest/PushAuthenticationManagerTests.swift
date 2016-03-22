import Foundation
import XCTest
import WordPress

class PushAuthenticationManagerTests : XCTestCase {
    
    class MockUIAlertControllerProxy : UIAlertControllerProxy {
       
        var titlePassedIn:String?
        var messagePassedIn:String?
        var cancelButtonTitlePassedIn:String?
        var otherButtonTitlesPassedIn:[AnyObject]?
        var tapBlockPassedIn:UIAlertControllerCompletionBlock?
        var showWithTitleCalled = false
        
        override func showWithTitle(title: String!, message: String!, cancelButtonTitle: String!, otherButtonTitles: [AnyObject]!, tapBlock: UIAlertControllerCompletionBlock!) -> UIAlertController! {
            showWithTitleCalled = true
            titlePassedIn = title
            messagePassedIn = message
            cancelButtonTitlePassedIn = cancelButtonTitle
            otherButtonTitlesPassedIn = otherButtonTitles
            tapBlockPassedIn = tapBlock
            return UIAlertController()
        }
    }
    
    class MockPushAuthenticationService : PushAuthenticationService {
       
        var tokenPassedIn:String?
        var completionBlockPassedIn:((Bool) -> ())?
        var authorizedLoginCalled = false
        var numberOfTimesAuthorizedLoginCalled = 0
        
        override func authorizeLogin(token: String, completion: ((Bool) -> ())) {
            authorizedLoginCalled = true
            numberOfTimesAuthorizedLoginCalled += 1
            tokenPassedIn = token
            completionBlockPassedIn = completion
        }
    }
    
    var mockPushAuthenticationService = MockPushAuthenticationService(managedObjectContext: TestContextManager().mainContext)
    var mockAlertControllerProxy = MockUIAlertControllerProxy()
    var pushAuthenticationManager :PushAuthenticationManager?
    var approvalAlertController : UIAlertController!
    
    override func setUp() {
        super.setUp()
        pushAuthenticationManager = PushAuthenticationManager(pushAuthenticationService: mockPushAuthenticationService)
        pushAuthenticationManager?.alertControllerProxy = mockAlertControllerProxy;
        
        approvalAlertController = UIAlertController()
        approvalAlertController.addCancelActionWithTitle("Ignore", handler: nil)
        approvalAlertController.addDefaultActionWithTitle("Approve", handler: nil)
    }
    
    func testIsPushAuthenticationNotificationReturnsTrueWhenPassedTheCorrectPushAuthenticationNoteType() {
        let result = pushAuthenticationManager!.isPushAuthenticationNotification(["type": "push_auth"])
        
        XCTAssertTrue(result, "Should be true when the type is 'push_auth'")
    }
    
    func testIsPushAuthenticationNotificationReturnsFalseWhenPassedIncorrectPushAuthenticationNoteType() {
        let result = pushAuthenticationManager!.isPushAuthenticationNotification(["type": "not_push"])
        
        XCTAssertFalse(result, "Should be false when the type is not 'push_auth'")
    }
    
    func expiredPushNotificationDictionary() -> NSDictionary {
       return ["expires": NSTimeInterval(3)]
    }
    
    func validPushAuthenticationDictionary() -> NSMutableDictionary {
        return ["push_auth_token" : "token", "aps" : [ "alert" : "an alert"]]
    }
    
    func testHandlePushAuthenticationNotificationShowsTheLoginExpiredAlertIfNotificationHasExpired(){
        pushAuthenticationManager!.handlePushAuthenticationNotification(expiredPushNotificationDictionary())
        
        XCTAssertTrue(mockAlertControllerProxy.showWithTitleCalled, "Should show the login expired alert if the notification has expired")
        XCTAssertEqual(mockAlertControllerProxy.titlePassedIn!, NSLocalizedString("Login Request Expired", comment:""), "")
    }
    
    func testHandlePushAuthenticationNotificationDoesNotShowTheLoginExpiredAlertIfNotificationHasNotExpired(){
        pushAuthenticationManager!.handlePushAuthenticationNotification([:])
        
        XCTAssertFalse(mockAlertControllerProxy.showWithTitleCalled, "Should not show the login expired alert if the notification hasn't expired")
    }
    
    func testHandlePushAuthenticationNotificationWithBlankTokenDoesNotShowLoginVerificationAlert(){
        let pushNotificationDictionary = validPushAuthenticationDictionary()
        pushNotificationDictionary.removeObjectForKey("push_auth_token")
        
        pushAuthenticationManager!.handlePushAuthenticationNotification(pushNotificationDictionary)
        
        XCTAssertFalse(mockAlertControllerProxy.showWithTitleCalled, "Should not show the login verification")
    }
    
    func testHandlePushAuthenticationNotificationWithBlankMessageDoesNotShowLoginVerificationAlert(){
        pushAuthenticationManager!.handlePushAuthenticationNotification(["push_auth_token" : "token"])
        
        XCTAssertFalse(mockAlertControllerProxy.showWithTitleCalled, "Should not show the login verification")
    }
    
    func testHandlePushAuthenticationNotificationWithValidDataShouldShowLoginVerification() {
        pushAuthenticationManager!.handlePushAuthenticationNotification(validPushAuthenticationDictionary())
        
        XCTAssertTrue(mockAlertControllerProxy.showWithTitleCalled, "Should show the login verification")
        XCTAssertEqual(mockAlertControllerProxy.titlePassedIn!, NSLocalizedString("Verify Sign In", comment: ""), "")
    }
    
    func testHandlePushAuthenticationNotificationShouldAttemptToAuthorizeTheLoginIfTheUserIndicatesTheyWantTo() {
        pushAuthenticationManager!.handlePushAuthenticationNotification(validPushAuthenticationDictionary())
        mockAlertControllerProxy.tapBlockPassedIn?(approvalAlertController, 1)
        
        XCTAssertTrue(mockPushAuthenticationService.authorizedLoginCalled, "Should have attempted to authorize the login")
    }
    
    func testHandlePushAuthenticationNotificationWhenAttemptingToLoginShouldAttemptToRetryTheLoginIfItFailed() {
        pushAuthenticationManager!.handlePushAuthenticationNotification(validPushAuthenticationDictionary())
        mockAlertControllerProxy.tapBlockPassedIn?(approvalAlertController, 1)
        mockPushAuthenticationService.completionBlockPassedIn?(false)
        
        XCTAssertEqual(mockPushAuthenticationService.numberOfTimesAuthorizedLoginCalled, 2, "Should have attempted to retry a failed login")
    }
    
    func testHandlePushAuthenticationNotificationShouldNotAttemptToAuthorizeTheLoginIfTheUserIndicatesTheyDontWantTo() {
        pushAuthenticationManager!.handlePushAuthenticationNotification(validPushAuthenticationDictionary())
        mockAlertControllerProxy.tapBlockPassedIn?(approvalAlertController, 0)
        
        XCTAssertFalse(mockPushAuthenticationService.authorizedLoginCalled, "Should not have attempted to authorize the login")
    }
}
