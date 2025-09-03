import Foundation
import XCTest
import OHHTTPStubs
import OHHTTPStubsSwift

@testable import WordPressKit

class WordPressComOAuthClientTests: XCTestCase {

    enum OAuthURL: String {
        case oAuthTokenUrl = "https://public-api.wordpress.com/oauth2/token"
        case socialLoginNewSMS2FA = "https://wordpress.com/wp-login.php?action=send-sms-code-endpoint"
        case socialLogin2FA = "https://wordpress.com/wp-login.php?action=two-step-authentication-endpoint&version=1.0"
        case socialLogin = "https://wordpress.com/wp-login.php?action=social-login-endpoint&version=1.0"
        case requestWebauthnChallenge = "https://wordpress.com/wp-login.php?action=webauthn-challenge-endpoint"
        case verifySignature = "https://wordpress.com/wp-login.php?action=webauthn-authentication-endpoint"
    }

    override func tearDown() {
        super.tearDown()
        HTTPStubs.removeAllStubs()
    }

    private func isOauthTokenRequest(url: OAuthURL) -> HTTPStubsTestBlock {
        return { request in
            return request.url?.absoluteString == url.rawValue
        }
    }

    func testAuthenticateUsernameNo2FASuccessCase() throws {
        let stubPath = try XCTUnwrap(OHPathForFileInBundle("WordPressComOAuthSuccess.json", Bundle.coreAPITestsBundle))
        stub(condition: isOauthTokenRequest(url: .oAuthTokenUrl)) { _ in
            return fixture(filePath: stubPath, headers: ["Content-Type" as NSObject: "application/json" as AnyObject])
        }

        let expect = expectation(description: "One callback should be invoked")
        let client = WordPressComOAuthClient(clientID: "Fake", secret: "Fake")
        client.authenticate(
            username: "fakeUser",
            password: "fakePass",
            multifactorCode: nil,
            needsMultifactor: { _, _ in XCTFail("This closure should not be called") },
            success: { (token) in
                expect.fulfill()
                XCTAssert(!token!.isEmpty, "There should be a token available")
                XCTAssert(token == "fakeToken", "There should be a token available")
            },
            failure: { (_) in
                expect.fulfill()
                XCTFail("This call should be successful")
            }
        )
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testAuthenticateUsernameNo2FASuccessCase_withMFAClosure() throws {
        let stubPath = try XCTUnwrap(OHPathForFileInBundle("WordPressComOAuthSuccess.json", Bundle.coreAPITestsBundle))
        stub(condition: isOauthTokenRequest(url: .oAuthTokenUrl)) { _ in
            return fixture(filePath: stubPath, headers: ["Content-Type" as NSObject: "application/json" as AnyObject])
        }

        let expect = expectation(description: "One callback should be invoked")
        let client = WordPressComOAuthClient(clientID: "Fake", secret: "Fake")
        client.authenticate(
            username: "fakeUser",
            password: "fakePass",
            multifactorCode: nil,
            needsMultifactor: { _, _ in
                expect.fulfill()
                XCTFail("This call should be successful")
            },
            success: { (token) in
                expect.fulfill()
                XCTAssert(!token!.isEmpty, "There should be a token available")
                XCTAssert(token == "fakeToken", "There should be a token available")
            },
            failure: { (_) in
                expect.fulfill()
                XCTFail("This call should be successful")
            }
        )
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testAuthenticateUsernameNo2FAFailureWrongPasswordCase() throws {
        let stubPath = try XCTUnwrap(
            OHPathForFileInBundle("WordPressComOAuthWrongPasswordFail.json", Bundle.coreAPITestsBundle)
        )
        stub(condition: isOauthTokenRequest(url: .oAuthTokenUrl)) { _ in
            return fixture(filePath: stubPath, status: 400, headers: ["Content-Type" as NSObject: "application/json" as AnyObject])
        }

        let expect = expectation(description: "One callback should be invoked")
        let client = WordPressComOAuthClient(clientID: "Fake", secret: "Fake")
        client.authenticate(
            username: "fakeUser",
            password: "wrongPassword",
            multifactorCode: nil,
            needsMultifactor: { _, _ in XCTFail("This closure should not be called") },
            success: { (_) in
                expect.fulfill()
                XCTFail("This call should fail")
            },
            failure: { (error) in
                expect.fulfill()
                XCTAssertEqual(error.authenticationFailureKind, .invalidRequest, "The code should be invalid request")
            }
        )
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testAuthenticateUsernameNo2FAFailureWrongPasswordCase_withMFAClosure() throws {
        let stubPath = try XCTUnwrap(
            OHPathForFileInBundle("WordPressComOAuthWrongPasswordFail.json", Bundle.coreAPITestsBundle)
        )
        stub(condition: isOauthTokenRequest(url: .oAuthTokenUrl)) { _ in
            return fixture(filePath: stubPath, status: 400, headers: ["Content-Type" as NSObject: "application/json" as AnyObject])
        }

        let expect = expectation(description: "One callback should be invoked")
        let client = WordPressComOAuthClient(clientID: "Fake", secret: "Fake")
        client.authenticate(
            username: "fakeUser",
            password: "wrongPassword",
            multifactorCode: nil,
            needsMultifactor: { _, _ in
                expect.fulfill()
                XCTFail("This call should fail")
            },
            success: { (_) in
                expect.fulfill()
                XCTFail("This call should fail")
            },
            failure: { (error) in
                expect.fulfill()
                XCTAssertEqual(error.authenticationFailureKind, .invalidRequest, "The code should be invalid request")
            }
        )
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testAuthenticateUsername2FAWrong2FACase() throws {
        let stubPath = try XCTUnwrap(
            OHPathForFileInBundle("WordPressComOAuthNeeds2FAFail.json", Bundle.coreAPITestsBundle)
        )
        stub(condition: isOauthTokenRequest(url: .oAuthTokenUrl)) { _ in
            return fixture(
                filePath: stubPath,
                status: 400,
                headers: ["Content-Type" as NSObject: "application/json" as AnyObject]
            )
        }

        let expect = expectation(description: "Call should complete")
        let client = WordPressComOAuthClient(clientID: "Fake", secret: "Fake")
        client.authenticate(
            username: "fakeUser",
            password: "wrongPassword",
            multifactorCode: nil,
            needsMultifactor: { _, _ in XCTFail("This closure should not be called") },
            success: { (_) in
                expect.fulfill()
                XCTFail("This call should fail")
            },
            failure: { (error) in
                expect.fulfill()
                XCTAssertEqual(error.authenticationFailureKind, .needsMultifactorCode, "The code should 'be needs multifactor'")
            }
        )
        waitForExpectations(timeout: 2, handler: nil)

        let expectation2 = expectation(description: "Call should complete")
        client.authenticate(
            username: "fakeUser",
            password: "fakePassword",
            multifactorCode: "fakeMultifactor",
            needsMultifactor: { _, _ in
                expect.fulfill()
                XCTFail("This call should fail")
            },
            success: { (_) in
                expectation2.fulfill()
                XCTFail("This call should fail")
            },
            failure: { (error) in
                expectation2.fulfill()
                XCTAssertEqual(error.authenticationFailureKind, .needsMultifactorCode, "The code should be needs multifactor")
            }
        )
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testAuthenticateUsername2FAWrong2FACase_withMFAClosure() throws {
        let stubPath = try XCTUnwrap(
            OHPathForFileInBundle("WordPressComOAuthNeeds2FAFail.json", Bundle.coreAPITestsBundle)
        )
        stub(condition: isOauthTokenRequest(url: .oAuthTokenUrl)) { _ in
            return fixture(
                filePath: stubPath,
                status: 400,
                headers: ["Content-Type" as NSObject: "application/json" as AnyObject]
            )
        }

        let expect = expectation(description: "Call should complete")
        let client = WordPressComOAuthClient(clientID: "Fake", secret: "Fake")
        client.authenticate(
            username: "fakeUser",
            password: "wrongPassword",
            multifactorCode: nil,
            needsMultifactor: { _, _ in
                expect.fulfill()
                XCTFail("This call should fail")
            },
            success: { (_) in
                expect.fulfill()
                XCTFail("This call should fail")
            },
            failure: { (error) in
                expect.fulfill()
                XCTAssertEqual(error.authenticationFailureKind, .needsMultifactorCode, "The code should be needs multifactor")
            }
        )
        waitForExpectations(timeout: 2, handler: nil)

        let expectation2 = expectation(description: "Call should complete")
        client.authenticate(
            username: "fakeUser",
            password: "fakePassword",
            multifactorCode: "fakeMultifactor",
            needsMultifactor: { _, _ in
                expect.fulfill()
                XCTFail("This call should fail")
            },
            success: { (_) in
                expectation2.fulfill()
                XCTFail("This call should fail")
            },
            failure: { (error) in
                expectation2.fulfill()
                XCTAssertEqual(error.authenticationFailureKind, .needsMultifactorCode, "The code should be needs multifactor")
            }
        )
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testAuthenticateUsernameRequiresWebauthnMultifactorAuthentication() throws {
        let stubPath = try XCTUnwrap(
            OHPathForFileInBundle("WordPressComOAuthNeedsWebauthnMFA.json", Bundle.coreAPITestsBundle)
        )
        stub(condition: isOauthTokenRequest(url: .oAuthTokenUrl)) { _ in
            return fixture(filePath: stubPath, headers: ["Content-Type" as NSObject: "application/json" as AnyObject])
        }

        let expect = expectation(description: "Call should complete")
        let client = WordPressComOAuthClient(clientID: "Fake", secret: "Fake")
        client.authenticate(
            username: "fakeUser",
            password: "wrongPassword",
            multifactorCode: nil,
            needsMultifactor: { userID, nonceInfo in
                expect.fulfill()
                XCTAssertEqual(userID, 1234)
                XCTAssertEqual(nonceInfo.nonceWebauthn, "two_step_nonce_webauthn")
            },
            success: { (_) in
                expect.fulfill()
                XCTFail("This call should need multifactor")
            },
            failure: { (error) in
                expect.fulfill()
                XCTFail("This call should need multifactor")
            }
        )
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testRequestOneTimeCodeWithUsername() throws {
        let stubPath = try XCTUnwrap(
            OHPathForFileInBundle("WordPressComOAuthNeeds2FAFail.json", Bundle.coreAPITestsBundle)
        )
        stub(condition: isOauthTokenRequest(url: .oAuthTokenUrl)) { _ in
            return fixture(filePath: stubPath, headers: ["Content-Type" as NSObject: "application/json" as AnyObject])
        }

        let expect = expectation(description: "One callback should be invoked")
        let client = WordPressComOAuthClient(clientID: "Fake", secret: "Fake")
        client.requestOneTimeCode(username: "fakeUser", password: "fakePassword",
                                              success: { () in
                                                expect.fulfill()
        }, failure: { (_) in
            expect.fulfill()
            XCTFail("This call should be successful")

        })
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testRequestSocial2FACodeWithUserID() throws {
        let stubPath = try XCTUnwrap(
            OHPathForFileInBundle("WordPressComSocial2FACodeSuccess.json", Bundle.coreAPITestsBundle)
        )
        stub(condition: isOauthTokenRequest(url: .socialLoginNewSMS2FA)) { _ in
            return fixture(filePath: stubPath, headers: ["Content-Type" as NSObject: "application/json" as AnyObject])
        }

        let expect = expectation(description: "One callback should be invoked")
        let client = WordPressComOAuthClient(clientID: "Fake", secret: "Fake")
        client.requestSocial2FACode(userID: 0, nonce: "nonce",
        success: { (newNonce) in
            expect.fulfill()
            XCTAssert(!newNonce.isEmpty, "There should be a newNonce available")
            XCTAssert(newNonce == "two_step_nonce_sms", "The newNonce should match")
        }, failure: { (_, _) in
            expect.fulfill()
            XCTFail("This call should be successful")

        })
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testAuthenticateWithIDToken() throws {
        let stubPath = try XCTUnwrap(
            OHPathForFileInBundle("WordPressComAuthenticateWithIDTokenBearerTokenSuccess.json", Bundle.coreAPITestsBundle)
        )
        stub(condition: isOauthTokenRequest(url: .socialLogin)) { _ in
            return fixture(filePath: stubPath, headers: ["Content-Type" as NSObject: "application/json" as AnyObject])
        }

        let expect = expectation(description: "One callback should be invoked")
        let client = WordPressComOAuthClient(clientID: "Fake", secret: "Fake")
        client.authenticate(
            socialIDToken: "token",
            service: "google",
            success: { (token) in
                expect.fulfill()
                XCTAssert(!token!.isEmpty, "There should be a token available")
                XCTAssert(token == "bearer_token", "The newNonce should match")
            },
            needsMultifactor: { (_, _) in
                expect.fulfill()
                XCTFail("This call should be successful")
            },
            existingUserNeedsConnection: { _ in
                expect.fulfill()
                XCTFail("This call should be successful")
            },
            failure: { (_) in
                expect.fulfill()
                XCTFail("This call should be successful")

            }
        )
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testAuthenticateWithIDToken2FANeeded() throws {
        let stubPath = try XCTUnwrap(
            OHPathForFileInBundle("WordPressComAuthenticateWithIDToken2FANeededSuccess.json", Bundle.coreAPITestsBundle)
        )
        stub(condition: isOauthTokenRequest(url: .socialLogin)) { _ in
            return fixture(filePath: stubPath, headers: ["Content-Type" as NSObject: "application/json" as AnyObject])
        }

        let expect = expectation(description: "One callback should be invoked")
        let client = WordPressComOAuthClient(clientID: "Fake", secret: "Fake")
        client.authenticate(
            socialIDToken: "token",
            service: "google",
            success: { (_) in
                expect.fulfill()
                XCTFail("This call should need multifactor")
            },
            needsMultifactor: { (userID, nonceInfo) in
                expect.fulfill()
                XCTAssertEqual(userID, 1)
                XCTAssertEqual(nonceInfo.nonceBackup, "two_step_nonce_backup")
                XCTAssertEqual(nonceInfo.nonceWebauthn, "two_step_nonce_webauthn")
            },
            existingUserNeedsConnection: { _ in
                expect.fulfill()
                XCTFail("This call should need multifactor")
            },
            failure: { (_) in
                expect.fulfill()
                XCTFail("This call should need multifactor")

            }
        )
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testAuthenticateWithIDTokenUserNeedsConnection() throws {
        let stubPath = try XCTUnwrap(
            OHPathForFileInBundle("WordPressComAuthenticateWithIDTokenExistingUserNeedsConnection.json", Bundle.coreAPITestsBundle)
        )
        stub(condition: isOauthTokenRequest(url: .socialLogin)) { _ in
            return fixture(filePath: stubPath, status: 400, headers: ["Content-Type" as NSObject: "application/json" as AnyObject])
        }

        let expect = expectation(description: "One callback should be invoked")
        let client = WordPressComOAuthClient(clientID: "Fake", secret: "Fake")
        client.authenticate(
            socialIDToken: "token",
            service: "google",
            success: { (_) in
                expect.fulfill()
                XCTFail("This call should invoke user needs connection")
            },
            needsMultifactor: { (_, _) in
                expect.fulfill()
                XCTFail("This call should invoke user needs connection")
            },
            existingUserNeedsConnection: { email in
                expect.fulfill()
                XCTAssertEqual(email, "email")
            },
            failure: { (_) in
                expect.fulfill()
                XCTFail("This call should invoke user needs connection")

            }
        )
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testAuthenticateSocialLoginUser() throws {
        let stubPath = try XCTUnwrap(
            OHPathForFileInBundle("WordPressComAuthenticateWithIDTokenBearerTokenSuccess.json", Bundle.coreAPITestsBundle)
        )
        stub(condition: isOauthTokenRequest(url: .socialLogin2FA)) { _ in
            return fixture(filePath: stubPath, headers: ["Content-Type" as NSObject: "application/json" as AnyObject])
        }

        let expect = expectation(description: "One callback should be invoked")
        let client = WordPressComOAuthClient(clientID: "Fake", secret: "Fake")
        client.authenticate(socialLoginUserID: 1, authType: "authenticator", twoStepCode: "two_step_code", twoStepNonce: "two_step_nonce",
                                       success: { (token) in
                                        expect.fulfill()
                                        XCTAssert(!token!.isEmpty, "There should be a token available")
                                        XCTAssert(token == "bearer_token", "The newNonce should match")
        }, failure: { (_) in
            expect.fulfill()
            XCTFail("This call should be successful")

        })
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testRequestWebauthnChallengeReturnsCompleteChallengeInfo() throws {
        let stubPath = try XCTUnwrap(
            OHPathForFileInBundle("WordPressComOAuthRequestChallenge.json", Bundle.coreAPITestsBundle)
        )
        stub(condition: isOauthTokenRequest(url: .requestWebauthnChallenge)) { _ in
            return fixture(filePath: stubPath, headers: ["Content-Type" as NSObject: "application/json" as AnyObject])
        }

        let expect = expectation(description: "One callback should be invoked")
        let client = WordPressComOAuthClient(clientID: "Fake", secret: "Fake")
        client.requestWebauthnChallenge(userID: 123, twoStepNonce: "twoStepNonce", success: { challengeInfo in
            expect.fulfill()
            let expectedChallengeInfo = WebauthnChallengeInfo(challenge: "challenge", rpID: "wordpress.com", twoStepNonce: "two_step_nonce", allowedCredentialIDs: ["credential-id, credential-id-2"])
            XCTAssertEqual(challengeInfo.challenge, expectedChallengeInfo.challenge)
            XCTAssertEqual(challengeInfo.rpID, expectedChallengeInfo.rpID)
            XCTAssertEqual(challengeInfo.twoStepNonce, expectedChallengeInfo.twoStepNonce)
        }, failure: { _ in
            expect.fulfill()
            XCTFail("This call should be successful")
        })
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testAuthenticateWebauthSignatureReturnsOauthToken() throws {
        let stubPath = try XCTUnwrap(
            OHPathForFileInBundle("WordPressComOAuthAuthenticateSignature.json", Bundle.coreAPITestsBundle)
        )
        stub(condition: isOauthTokenRequest(url: .verifySignature)) { _ in
            return fixture(filePath: stubPath, headers: ["Content-Type" as NSObject: "application/json" as AnyObject])
        }

        let expect = expectation(description: "One callback should be invoked")
        let client = WordPressComOAuthClient(clientID: "Fake", secret: "Fake")
        client.authenticateWebauthnSignature(userID: 123,
                                             twoStepNonce: "twoStepNOnce",
                                             credentialID: "credential-id".data(using: .utf8) ?? Data(),
                                             clientDataJson: "{}".data(using: .utf8) ?? Data(),
                                             authenticatorData: "authenticator-data".data(using: .utf8) ?? Data(),
                                             signature: "signature".data(using: .utf8) ?? Data(),
                                             userHandle: "user-handle".data(using: .utf8) ?? Data(),
                                             success: { token in
            expect.fulfill()
            XCTAssertEqual(token, "bearer_token")
        },
                                             failure: { _ in
            expect.fulfill()
            XCTFail("This call should be successful")
        })
        waitForExpectations(timeout: 2, handler: nil)
    }
}
