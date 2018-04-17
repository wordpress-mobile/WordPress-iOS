import Foundation
import XCTest
@testable import WordPressKit

class PushAuthenticationServiceRemoteTests: XCTestCase {

    var pushAuthenticationServiceRemote: PushAuthenticationServiceRemote!
    var mockRemoteApi: MockWordPressComRestApi!
    let token = "token"
    override func setUp() {
        super.setUp()
        mockRemoteApi = MockWordPressComRestApi()
        pushAuthenticationServiceRemote = PushAuthenticationServiceRemote(wordPressComRestApi: mockRemoteApi)
    }

    func testAuthorizeLoginUsesTheCorrectPath() {
        pushAuthenticationServiceRemote.authorizeLogin(token, success: nil, failure: nil)

        XCTAssertTrue(mockRemoteApi.postMethodCalled, "Method was not called")

        let url = pushAuthenticationServiceRemote.path(forEndpoint: "me/two-step/push-authentication", withVersion: ._1_1)
        XCTAssertEqual(mockRemoteApi.URLStringPassedIn!, url, "Incorrect URL passed in")
    }

    func testAuthorizeLoginUsesTheCorrectParameters() {
        pushAuthenticationServiceRemote.authorizeLogin(token, success: nil, failure: nil)

        let parameters: NSDictionary = mockRemoteApi.parametersPassedIn as! NSDictionary

        XCTAssertTrue(mockRemoteApi.postMethodCalled, "Method was not called")
        XCTAssertEqual(parameters["action"] as! String?, "authorize_login", "incorrect action parameter")
        XCTAssertEqual(parameters["push_token"] as! String?, token, "incorrect token parameter")
    }

    func testAuthorizeLoginCallsSuccessBlock() {
        var successBlockCalled = false
        pushAuthenticationServiceRemote!.authorizeLogin(token, success: { () -> () in
           successBlockCalled = true
        }, failure: nil)
        mockRemoteApi.successBlockPassedIn?(NSString(), HTTPURLResponse())

        XCTAssertTrue(mockRemoteApi.postMethodCalled, "Method was not called")
        XCTAssertTrue(successBlockCalled, "Success block not called")
    }

    func testAuthorizeLoginCallsFailureBlock() {
        var failureBlockCalled = false
        pushAuthenticationServiceRemote.authorizeLogin(token, success: nil, failure: { () -> () in
            failureBlockCalled = true
        })
        mockRemoteApi.failureBlockPassedIn?(NSError(domain: "UnitTest", code: 0, userInfo: nil), HTTPURLResponse())

        XCTAssertTrue(mockRemoteApi.postMethodCalled, "Method was not called")
        XCTAssertTrue(failureBlockCalled, "Failure block not called")
    }

}
