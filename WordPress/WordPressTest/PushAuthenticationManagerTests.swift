import Foundation
import XCTest

class PushAuthenticationManagerTests : XCTestCase {
    
    class MockUIAlertViewProxy : UIAlertViewProxy {
       
        var titlePassedIn:String?
        var messagePassedIn:String?
        var cancelButtonTitlePassedIn:String?
        var otherButtonTitlesPassedIn:[AnyObject]?
        var tapBlockPassedIn:UIAlertViewCompletionBlock?
        var showWithTitleCalled = false
        
        override func showWithTitle(title: String!, message: String!, cancelButtonTitle: String!, otherButtonTitles: [AnyObject]!, tapBlock: UIAlertViewCompletionBlock!) -> UIAlertView! {
            showWithTitleCalled = true
            titlePassedIn = title
            messagePassedIn = message
            cancelButtonTitlePassedIn = cancelButtonTitle
            otherButtonTitlesPassedIn = otherButtonTitles
            tapBlockPassedIn = tapBlock
            return  UIAlertView()
        }
    }
    
    class MockPushAuthenticationService : PushAuthenticationService {
       
        var tokenPassedIn:String?
        var completionBlockPassedIn:((Bool) -> ())?
        var authorizedLoginCalled = false
        var numberOfTimesAuthorizedLoginCalled = 0
        
        override func authorizeLogin(token: String, completion: ((Bool) -> ())) {
            authorizedLoginCalled = true
            numberOfTimesAuthorizedLoginCalled++
            tokenPassedIn = token
            completionBlockPassedIn = completion
        }
    }
    
    var mockPushAuthenticationService = MockPushAuthenticationService(managedObjectContext: TestContextManager().mainContext)
    var mockAlertViewProxy = MockUIAlertViewProxy()
    var pushAuthenticationManager:PushAuthenticationManager?
    
    override func setUp() {
        super.setUp()
        pushAuthenticationManager = PushAuthenticationManager(pushAuthenticationService: mockPushAuthenticationService)
        pushAuthenticationManager?.alertViewProxy = mockAlertViewProxy;
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
        
        XCTAssertTrue(mockAlertViewProxy.showWithTitleCalled, "Should show the login expired alert if the notification has expired")
        XCTAssertEqual(mockAlertViewProxy.titlePassedIn!, NSLocalizedString("Login Request Expired", comment:""), "")
    }
    
    func testHandlePushAuthenticationNotificationDoesNotShowTheLoginExpiredAlertIfNotificationHasNotExpired(){
        pushAuthenticationManager!.handlePushAuthenticationNotification([:])
        
        XCTAssertFalse(mockAlertViewProxy.showWithTitleCalled, "Should not show the login expired alert if the notification hasn't expired")
    }
    
    func testHandlePushAuthenticationNotificationWithBlankTokenDoesNotShowLoginVerificationAlert(){
        var pushNotificationDictionary = validPushAuthenticationDictionary()
        pushNotificationDictionary.removeObjectForKey("push_auth_token")
        
        pushAuthenticationManager!.handlePushAuthenticationNotification(pushNotificationDictionary)
        
        XCTAssertFalse(mockAlertViewProxy.showWithTitleCalled, "Should not show the login verification")
    }
    
    func testHandlePushAuthenticationNotificationWithBlankMessageDoesNotShowLoginVerificationAlert(){
        pushAuthenticationManager!.handlePushAuthenticationNotification(["push_auth_token" : "token"])
        
        XCTAssertFalse(mockAlertViewProxy.showWithTitleCalled, "Should not show the login verification")
    }
    
    func testHandlePushAuthenticationNotificationWithValidDataShouldShowLoginVerification() {
        pushAuthenticationManager!.handlePushAuthenticationNotification(validPushAuthenticationDictionary())
        
        XCTAssertTrue(mockAlertViewProxy.showWithTitleCalled, "Should show the login verification")
        XCTAssertEqual(mockAlertViewProxy.titlePassedIn!, NSLocalizedString("Verify Login", comment: ""), "")
    }
    
    func testHandlePushAuthenticationNotificationShouldAttemptToAuthorizeTheLoginIfTheUserIndicatesTheyWantTo() {
        pushAuthenticationManager!.handlePushAuthenticationNotification(validPushAuthenticationDictionary())
        let alertView = UIAlertView()
        mockAlertViewProxy.tapBlockPassedIn?(alertView, 1)
        
        XCTAssertTrue(mockPushAuthenticationService.authorizedLoginCalled, "Should have attempted to authorize the login")
    }
    
    func testHandlePushAuthenticationNotificationWhenAttemptingToLoginShouldAttemptToRetryTheLoginIfItFailed() {
        pushAuthenticationManager!.handlePushAuthenticationNotification(validPushAuthenticationDictionary())
        let alertView = UIAlertView()
        mockAlertViewProxy.tapBlockPassedIn?(alertView, 1)
        mockPushAuthenticationService.completionBlockPassedIn?(false)
        
        XCTAssertEqual(mockPushAuthenticationService.numberOfTimesAuthorizedLoginCalled, 2, "Should have attempted to retry a failed login")
    }
    
    func testHandlePushAuthenticationNotificationShouldNotAttemptToAuthorizeTheLoginIfTheUserIndicatesTheyDontWantTo() {
        pushAuthenticationManager!.handlePushAuthenticationNotification(validPushAuthenticationDictionary())
        
        let alertView = UIAlertView()
        mockAlertViewProxy.tapBlockPassedIn?(alertView, alertView.cancelButtonIndex)
        
        XCTAssertFalse(mockPushAuthenticationService.authorizedLoginCalled, "Should not have attempted to authorize the login")
    }
}
