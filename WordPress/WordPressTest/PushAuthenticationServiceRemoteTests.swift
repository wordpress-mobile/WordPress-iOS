import Foundation
import XCTest

class PushAuthenticationServiceRemoteTests : XCTestCase {
    
    class MockWordPressComApi : WordPressComApi {
        var postMethodCalled = false
        var URLStringPassedIn:String?
        var parametersPassedIn:AnyObject?
        
        var shouldCallSuccessCallback = false
        func callSuccessCallback() {
           shouldCallSuccessCallback = true
        }
        
        var shouldCallFailureCallback = false
        func callFailureCallback() {
           shouldCallFailureCallback = true
        }
    
        override func POST(URLString: String!, parameters: AnyObject!, success: ((AFHTTPRequestOperation!, AnyObject!) -> Void)!, failure: ((AFHTTPRequestOperation!, NSError!) -> Void)!) -> AFHTTPRequestOperation! {
            postMethodCalled = true
            URLStringPassedIn = URLString
            parametersPassedIn = parameters
            
            if (shouldCallSuccessCallback) {
                success?(AFHTTPRequestOperation(), [])
            } else if (shouldCallFailureCallback) {
                failure?(AFHTTPRequestOperation(), NSError())
            }
            
            return AFHTTPRequestOperation()
        }
    }
    
    var pushAuthenticationServiceRemote:PushAuthenticationServiceRemote?
    var mockRemoteApi:MockWordPressComApi?
    let token = "token"
    override func setUp() {
        super.setUp()
        mockRemoteApi = MockWordPressComApi()
        pushAuthenticationServiceRemote = PushAuthenticationServiceRemote(remoteApi: mockRemoteApi)
    }
    
    override func tearDown() {
        super.tearDown()
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
        mockRemoteApi?.callSuccessCallback()
        pushAuthenticationServiceRemote!.authorizeLogin(token, success: { () -> () in
           successBlockCalled = true
        }, failure: nil)
        
        XCTAssertTrue(mockRemoteApi!.postMethodCalled, "Method was not called")
        XCTAssertTrue(successBlockCalled, "Success block not called")
    }
    
    func testAuthorizeLoginCallsFailureBlock() {
        var failureBlockCalled = false
        mockRemoteApi?.callFailureCallback()
        pushAuthenticationServiceRemote!.authorizeLogin(token, success: nil, failure: { () -> () in
            failureBlockCalled = true
        })
        
        pushAuthenticationServiceRemote?.authorizeLogin(token, success: nil, failure: nil)
        
        XCTAssertTrue(mockRemoteApi!.postMethodCalled, "Method was not called")
        XCTAssertTrue(failureBlockCalled, "Failure block not called")
    }
    
}