import Foundation
import XCTest
@testable import WordPress

class PushAuthenticationServiceTests: XCTestCase {

    var testContextManager: TestContextManager!
    var pushAuthenticationService: PushAuthenticationService!
    var mockPushAuthenticationServiceRemote: MockPushAuthenticationServiceRemote!
    var mockRemoteApi: MockWordPressComRestApi!
    let token = "token"

    class MockPushAuthenticationServiceRemote: PushAuthenticationServiceRemote {

        var authorizeLoginCalled = false
        var successBlockPassedIn: (() -> ())?
        var failureBlockPassedIn: (() -> ())?

        override func authorizeLogin(_ token: String, success: (() -> ())?, failure: (() -> ())?) {
            authorizeLoginCalled = true
            successBlockPassedIn = success
            failureBlockPassedIn = failure
        }
    }

    override func setUp() {
        super.setUp()
        mockRemoteApi = MockWordPressComRestApi()
        testContextManager = TestContextManager()
        mockPushAuthenticationServiceRemote = MockPushAuthenticationServiceRemote(wordPressComRestApi: mockRemoteApi)
        pushAuthenticationService = PushAuthenticationService(managedObjectContext: testContextManager.mainContext)
        pushAuthenticationService.authenticationServiceRemote = mockPushAuthenticationServiceRemote
    }

    func testAuthorizeLoginDoesntCallServiceRemoteIfItsNull() {
        pushAuthenticationService.authenticationServiceRemote = nil
        pushAuthenticationService.authorizeLogin(token, completion: { (completed: Bool) -> () in
        })
        XCTAssertFalse(mockPushAuthenticationServiceRemote!.authorizeLoginCalled, "Authorize login should not have been called")
        ContextManager.overrideSharedInstance(nil)
    }

    func testAuthorizeLoginCallsServiceRemoteAuthorizeLoginWhenItsNotNull() {
        pushAuthenticationService.authorizeLogin(token, completion: { (completed: Bool) -> () in
        })
        XCTAssertTrue(mockPushAuthenticationServiceRemote.authorizeLoginCalled, "Authorize login should have been called")
    }

    func testAuthorizeLoginCallsCompletionCallbackWithTrueIfSuccessful() {
        var methodCalled = false
        pushAuthenticationService.authorizeLogin(token, completion: { (completed: Bool) -> () in
            methodCalled = true
            XCTAssertTrue(completed, "Success callback should have been called with a value of true")
        })
        mockPushAuthenticationServiceRemote.successBlockPassedIn?()

        XCTAssertTrue(methodCalled, "Success callback was not called")
    }

    func testAuthorizeLoginCallsCompletionCallbackWithFalseIfSuccessful() {
        var methodCalled = false
        pushAuthenticationService.authorizeLogin(token, completion: { (completed: Bool) -> () in
            methodCalled = true
            XCTAssertFalse(completed, "Failure callback should have been called with a value of false")
        })
        mockPushAuthenticationServiceRemote.failureBlockPassedIn?()

        XCTAssertTrue(methodCalled, "Failure callback was not called")
    }

}
