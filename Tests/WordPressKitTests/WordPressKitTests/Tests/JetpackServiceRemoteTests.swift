import Foundation
import XCTest
@testable import WordPressKit

class JetpackServiceRemoteTests: RemoteTestCase, RESTTestable {
    let url = "http://www.wordpress.com"
    let encodedURL = "http%3A%2F%2Fwww.wordpress.com"
    let username = "username"
    let password = "qwertyuiop"

    let jetpackRemoteSuccessMockFilename = "jetpack-service-success.json"
    let jetpackRemoteFailureMockFilename = "jetpack-service-failure.json"

    let jetpackRemoteErrorUnknownMockFilename = "jetpack-service-error-unknown.json"
    let jetpackRemoteErrorInvalidCredentialsMockFilename = "jetpack-service-error-invalid-credentials.json"
    let jetpackRemoteErrorForbiddenMockFilename = "jetpack-service-error-forbidden.json"
    let jetpackRemoteErrorInstallFailureMockFilename = "jetpack-service-error-install-failure.json"
    let jetpackRemoteErrorInstallResponseMockFilename = "jetpack-service-error-install-response.json"
    let jetpackRemoteErrorLoginFailureMockFilename = "jetpack-service-error-login-failure.json"
    let jetpackRemoteErrorSiteIsJetpackMockFilename = "jetpack-service-error-site-is-jetpack.json"
    let jetpackRemoteErrorActivationInstallMockFilename = "jetpack-service-error-activation-install.json"
    let jetpackRemoteErrorActivationResponseMockFilename = "jetpack-service-error-activation-response.json"
    let jetpackRemoteErrorActivationFailureMockFilename = "jetpack-service-error-activation-failure.json"

    let jetpackRemoteCheckSiteSuccessMockFilename = "jetpack-service-check-site-success.json"
    let jetpackRemoteCheckSiteFailureMockFilename = "jetpack-service-check-site-success-no-jetpack.json"
    let jetpackRemoteCheckSiteDataFailureMockFilename = "jetpack-service-check-site-failure-data.json"

    var endpoint: String { return "jetpack-install/\(encodedURL)/" }
    var checkSiteEndpoint: String { return "connect/site-info" }

    var remote: JetpackServiceRemote!

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()

        remote = JetpackServiceRemote(wordPressComRestApi: getRestApi())
    }

    override func tearDown() {
        super.tearDown()

        remote = nil
    }

    func testCheckSiteHasJetpackSuccess() {
        let expect = expectation(description: "Check if the site has Jetpack success")

        stubRemoteResponse(checkSiteEndpoint, filename: jetpackRemoteCheckSiteSuccessMockFilename, contentType: .ApplicationJSON, status: 200)
        remote.checkSiteHasJetpack(URL(string: url)!, success: { (success) in
            XCTAssertTrue(success, "Success should be true")
            expect.fulfill()
        }) { (_) in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testCheckSiteHasJetpackSuccessNoJetpack() {
        let expect = expectation(description: "Check if the site has Jetpack failure")

        stubRemoteResponse(checkSiteEndpoint, filename: jetpackRemoteCheckSiteFailureMockFilename, contentType: .ApplicationJSON, status: 200)
        remote.checkSiteHasJetpack(URL(string: url)!, success: { (success) in
            XCTAssertFalse(success, "Success should be false")
            expect.fulfill()
        }) { (_) in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }
        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testCheckSiteHasJetpackFailureNetwork() {
        let expect = expectation(description: "Check if the site has Jetpack network failure")

        stubRemoteResponse(checkSiteEndpoint, filename: jetpackRemoteCheckSiteSuccessMockFilename, contentType: .ApplicationJSON, status: 400)
        remote.checkSiteHasJetpack(URL(string: url)!, success: { (_) in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }) { (error) in
            XCTAssertNotNil(error, "Error shouldn't be nil")
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testCheckSiteHasJetpackFailureData() {
        let expect = expectation(description: "Check if the site has Jetpack data failure")

        stubRemoteResponse(checkSiteEndpoint, filename: jetpackRemoteCheckSiteDataFailureMockFilename, contentType: .ApplicationJSON, status: 200)
        remote.checkSiteHasJetpack(URL(string: url)!, success: { (_) in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }) { (error) in
            XCTAssertNotNil(error, "Error shouldn't be nil")
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testJetpackRemoteInstallationSuccess() {
        let expect = expectation(description: "Install Jetpack success")

        stubRemoteResponse(endpoint, filename: jetpackRemoteSuccessMockFilename, contentType: .ApplicationJSON, status: 200)
        remote.installJetpack(url: url, username: username, password: password) { (success, _) in
            XCTAssertTrue(success, "Success should be true")
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testJetpackRemoteInstallationFailure() {
        let expect = expectation(description: "Install Jetpack failure")

        stubRemoteResponse(endpoint, filename: jetpackRemoteFailureMockFilename, contentType: .ApplicationJSON, status: 200)
        remote.installJetpack(url: url, username: username, password: password) { (success, _) in
            XCTAssertFalse(success, "Success should be false")
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testJetpackRemoteInstallationErrorInvalidCredentials() {
        let expect = expectation(description: "Install Jetpack failure")

        stubRemoteResponse(endpoint, filename: jetpackRemoteErrorInvalidCredentialsMockFilename, contentType: .ApplicationJSON, status: 400)
        remote.installJetpack(url: url, username: username, password: password) { (success, error) in
            XCTAssertFalse(success, "Success should be false")
            XCTAssertEqual(error?.type, .invalidCredentials)
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testJetpackRemoteInstallationErrorUnknown() {
        let expect = expectation(description: "Install Jetpack failure")

        stubRemoteResponse(endpoint, filename: jetpackRemoteErrorUnknownMockFilename, contentType: .ApplicationJSON, status: 400)
        remote.installJetpack(url: url, username: username, password: password) { (success, error) in
            XCTAssertFalse(success, "Success should be false")
            XCTAssertEqual(error?.type, .unknown)
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testJetpackRemoteInstallationErrorForbidden() {
        let expect = expectation(description: "Install Jetpack failure")

        stubRemoteResponse(endpoint, filename: jetpackRemoteErrorForbiddenMockFilename, contentType: .ApplicationJSON, status: 400)
        remote.installJetpack(url: url, username: username, password: password) { (success, error) in
            XCTAssertFalse(success, "Success should be false")
            XCTAssertEqual(error?.type, .forbidden)
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testJetpackRemoteInstallationInstallFailure() {
        let expect = expectation(description: "Install Jetpack failure")

        stubRemoteResponse(endpoint, filename: jetpackRemoteErrorInstallFailureMockFilename, contentType: .ApplicationJSON, status: 400)
        remote.installJetpack(url: url, username: username, password: password) { (success, error) in
            XCTAssertFalse(success, "Success should be false")
            XCTAssertEqual(error?.type, .installFailure)
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testJetpackRemoteInstallationInstallResponse() {
        let expect = expectation(description: "Install Jetpack failure")

        stubRemoteResponse(endpoint, filename: jetpackRemoteErrorInstallResponseMockFilename, contentType: .ApplicationJSON, status: 400)
        remote.installJetpack(url: url, username: username, password: password) { (success, error) in
            XCTAssertFalse(success, "Success should be false")
            XCTAssertEqual(error?.type, .installResponseError)
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testJetpackRemoteInstallationLoginFailure() {
        let expect = expectation(description: "Install Jetpack failure")

        stubRemoteResponse(endpoint, filename: jetpackRemoteErrorLoginFailureMockFilename, contentType: .ApplicationJSON, status: 400)
        remote.installJetpack(url: url, username: username, password: password) { (success, error) in
            XCTAssertFalse(success, "Success should be false")
            XCTAssertEqual(error?.type, .loginFailure)
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testJetpackRemoteInstallationSiteIsJetpack() {
        let expect = expectation(description: "Install Jetpack failure")

        stubRemoteResponse(endpoint, filename: jetpackRemoteErrorSiteIsJetpackMockFilename, contentType: .ApplicationJSON, status: 400)
        remote.installJetpack(url: url, username: username, password: password) { (success, error) in
            XCTAssertFalse(success, "Success should be false")
            XCTAssertEqual(error?.type, .siteIsJetpack)
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testJetpackRemoteInstallationActivationInstall() {
        let expect = expectation(description: "Install Jetpack failure")

        stubRemoteResponse(endpoint, filename: jetpackRemoteErrorActivationInstallMockFilename, contentType: .ApplicationJSON, status: 400)
        remote.installJetpack(url: url, username: username, password: password) { (success, error) in
            XCTAssertFalse(success, "Success should be false")
            XCTAssertEqual(error?.type, .activationOnInstallFailure)
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testJetpackRemoteInstallationActivationResponse() {
        let expect = expectation(description: "Install Jetpack failure")

        stubRemoteResponse(endpoint, filename: jetpackRemoteErrorActivationResponseMockFilename, contentType: .ApplicationJSON, status: 400)
        remote.installJetpack(url: url, username: username, password: password) { (success, error) in
            XCTAssertFalse(success, "Success should be false")
            XCTAssertEqual(error?.type, .activationResponseError)
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testJetpackRemoteInstallationActivationFailure() {
        let expect = expectation(description: "Install Jetpack failure")

        stubRemoteResponse(endpoint, filename: jetpackRemoteErrorActivationFailureMockFilename, contentType: .ApplicationJSON, status: 400)
        remote.installJetpack(url: url, username: username, password: password) { (success, error) in
            XCTAssertFalse(success, "Success should be false")
            XCTAssertEqual(error?.type, .activationFailure)
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }
}
