import Foundation
import XCTest

class PushAuthenticationServiceRemoteTests : XCTestCase {

    var pushAuthenticationServiceRemote:PushAuthenticationServiceRemote?
    var mockRemoteApi:MockWordPressComApi?
    let token = "token"
    override func setUp() {
        super.setUp()
        mockRemoteApi = MockWordPressComApi()
        pushAuthenticationServiceRemote = PushAuthenticationServiceRemote(remoteApi: mockRemoteApi)
    }
    
    func testAuthorizeLoginUsesTheCorrectPath() {
        pushAuthenticationServiceRemote?.authorizeLogin(token, success: nil, failure: nil)
        
        XCTAssertTrue(mockRemoteApi!.postMethodCalled, "Method was not called")
        XCTAssertEqual(mockRemoteApi!.URLStringPassedIn!, "me/two-step/push-authentication", "Incorrect URL passed in")
    }
    
    func testAuthorizeLoginUsesTheCorrectParameters() {
        pushAuthenticationServiceRemote?.authorizeLogin(token, success: nil, failure: nil)
        
        var parameters:NSDictionary = mockRemoteApi!.parametersPassedIn as! NSDictionary
        
        XCTAssertTrue(mockRemoteApi!.postMethodCalled, "Method was not called")
        XCTAssertEqual(parameters["action"] as! String, "authorize_login", "incorrect action parameter")
        XCTAssertEqual(parameters["push_token"] as! String, token, "incorrect token parameter")
    }
    
    func testAuthorizeLoginCallsSuccessBlock() {
        var successBlockCalled = false
        pushAuthenticationServiceRemote!.authorizeLogin(token, success: { () -> () in
           successBlockCalled = true
        }, failure: nil)
        mockRemoteApi?.successBlockPassedIn?(AFHTTPRequestOperation(), [])
        
        XCTAssertTrue(mockRemoteApi!.postMethodCalled, "Method was not called")
        XCTAssertTrue(successBlockCalled, "Success block not called")
    }
    
    func testAuthorizeLoginCallsFailureBlock() {
        var failureBlockCalled = false
        pushAuthenticationServiceRemote!.authorizeLogin(token, success: nil, failure: { () -> () in
            failureBlockCalled = true
        })
        mockRemoteApi?.failureBlockPassedIn?(AFHTTPRequestOperation(), NSError())
        
        XCTAssertTrue(mockRemoteApi!.postMethodCalled, "Method was not called")
        XCTAssertTrue(failureBlockCalled, "Failure block not called")
    }
    
}