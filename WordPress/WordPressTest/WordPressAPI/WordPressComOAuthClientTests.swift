import XCTest
import WordPress
import OHHTTPStubs

class WordPressOAuthClientTests: XCTestCase {

    let WordPressComOAuthTokenUrl = "https://public-api.wordpress.com/oauth2/token"

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
        OHHTTPStubs.removeAllStubs()
    }

    fileprivate func isOauthTokenRequest() -> OHHTTPStubsTestBlock {
        return { request in
            return request.url?.absoluteString == self.WordPressComOAuthTokenUrl
        }
    }


    func testAuthenticateUsernameNo2FASuccessCase() {
        stub(condition: isOauthTokenRequest()) { request in
            let stubPath = OHPathForFile("WordPressOAuthClientSuccess.json", type(of: self))
            return fixture(filePath: stubPath!, headers: ["Content-Type" as NSObject: "application/json" as AnyObject])
        }

        let expect = self.expectation(description: "One callback should be invoked")
        let client = WordPressComOAuthClient(clientID: "Fake", secret: "Fake")
        client.authenticateWithUsername("fakeUser", password: "fakePass", multifactorCode: nil, success: { (token) in
            expect.fulfill()
            XCTAssert(!token!.isEmpty, "There should be a token available")
            XCTAssert(token == "fakeToken", "There should be a token available")
            }, failure: { (error) in
                expect.fulfill()
                XCTFail("This call should be successfull")
        })
        self.waitForExpectations(timeout: 2, handler: nil)
    }

    func testAuthenticateUsernameNo2FAFailureWrongPasswordCase() {
        stub(condition: isOauthTokenRequest()) { request in
            let stubPath = OHPathForFile("WordPressOAuthClientWrongPasswordFail.json", type(of: self))
            return fixture(filePath: stubPath!, status: 400, headers: ["Content-Type" as NSObject: "application/json" as AnyObject])
        }

        let expect = self.expectation(description: "One callback should be invoked")
        let client = WordPressComOAuthClient(clientID: "Fake", secret: "Fake")
        client.authenticateWithUsername("fakeUser", password: "wrongPassword", multifactorCode: nil, success: { (token) in
            expect.fulfill()
            XCTFail("This call should fail")
            }, failure: { (error) in
                expect.fulfill()
                XCTAssert(error.domain == WordPressComOAuthClient.WordPressComOAuthErrorDomain, "The error should an WordPressComOAuthError")
                XCTAssert(error.code == Int(WordPressComOAuthError.invalidRequest.rawValue), "The code should be invalid request")
        })
        self.waitForExpectations(timeout: 2, handler: nil)
    }

    func testAuthenticateUsername2FAWrong2FACase() {
        stub(condition: isOauthTokenRequest()) { request in
            let stubPath = OHPathForFile("WordPressOAuthClientNeed2FAFail.json", type(of: self))
            return fixture(filePath: stubPath!, status: 400, headers: ["Content-Type" as NSObject: "application/json" as AnyObject])
        }

        let expect = self.expectation(description: "Call should complete")
        let client = WordPressComOAuthClient(clientID: "Fake", secret: "Fake")
        client.authenticateWithUsername("fakeUser", password: "wrongPassword", multifactorCode: nil, success: { (token) in
            expect.fulfill()
            XCTFail("This call should fail")
            }, failure: { (error) in
                expect.fulfill()
                XCTAssert(error.domain == WordPressComOAuthClient.WordPressComOAuthErrorDomain, "The error should an WordPressComOAuthError")
                XCTAssert(error.code == Int(WordPressComOAuthError.needsMultifactorCode.rawValue), "The code should be needs multifactor")
        })
        self.waitForExpectations(timeout: 2, handler: nil)

        let expectation2 = self.expectation(description: "Call should complete")
        client.authenticateWithUsername("fakeUser", password: "fakePassword", multifactorCode: "fakeMultifactor", success: { (token) in
            expectation2.fulfill()
            XCTFail("This call should fail")
            }, failure: { (error) in
                expectation2.fulfill()
                XCTAssert(error.domain == WordPressComOAuthClient.WordPressComOAuthErrorDomain, "The error should an WordPressComOAuthError")
                XCTAssert(error.code == Int(WordPressComOAuthError.needsMultifactorCode.rawValue), "The code should be needs multifactor")
        })
        self.waitForExpectations(timeout: 2, handler: nil)
    }

    func testrequestOneTimeCodeWithUsername() {
        stub(condition: isOauthTokenRequest()) { request in
            let stubPath = OHPathForFile("WordPressOAuthClientNeed2FAFail.json", type(of: self))
            return fixture(filePath: stubPath!, headers: ["Content-Type" as NSObject: "application/json" as AnyObject])
        }

        let expect = self.expectation(description: "One callback should be invoked")
        let client = WordPressComOAuthClient(clientID: "Fake", secret: "Fake")
        client.requestOneTimeCodeWithUsername("fakeUser", password: "fakePassword",
                                              success: { () in
                                                expect.fulfill()
            }, failure: { (error) in
                expect.fulfill()
                XCTFail("This call should be successful")

        })
        self.waitForExpectations(timeout: 2, handler: nil)
    }

}
