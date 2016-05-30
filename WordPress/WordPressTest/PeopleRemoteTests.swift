import Foundation
import XCTest
import OHHTTPStubs
@testable import WordPress

class PeopleServiceTests : XCTestCase
{
    // MARK: - Constants

    let validationSuccessMockFilename   = "people-validate-invitation-success.json"
    let validationFailureMockFilename   = "people-validate-invitation-failure.json"
    let sendSuccessMockFilename         = "people-send-invitation-success.json"
    let sendFailureMockFilename         = "people-send-invitation-failure.json"
    let contentTypeJson                 = "application/json"
    let timeout                         = NSTimeInterval(1000)

    // MARK: - Properties

    var restApi : WordPressComRestApi!
    var remote : PeopleRemote!


    // MARK: - Overriden Methods

    override func setUp() {
        super.setUp()

        restApi = WordPressComRestApi(oAuthToken: nil, userAgent: nil)
        remote = PeopleRemote(wordPressComRestApi: restApi)
    }

    override func tearDown() {
        super.tearDown()
        OHHTTPStubs.removeAllStubs()
    }


    // MARK: - Helpers

    private func stubRemoteResponse(endpoint: String, filename: String) {
        stub({ request in
            return request.URL?.absoluteString.rangeOfString(endpoint) != nil
        }) { _ in
            let stubPath = OHPathForFile(filename, self.dynamicType)
            return fixture(stubPath!, headers: ["Content-Type": self.contentTypeJson])
        }
    }


    // MARK: - Tests

    func testValidateInvitationWithInvalidUsernameFails() {
        let expectation = expectationWithDescription("Send Invite")

        stubRemoteResponse("invites/validate", filename: validationFailureMockFilename)
        remote.validateInvitation(321, usernameOrEmail: "someInvalidUser", role: .Follower) { success in
            NSLog("Success: \(success)")
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)
    }

    func testValidateInvitationWithValidUsernameSucceeds() {
        let expectation = expectationWithDescription("Send Invite")

        stubRemoteResponse("invites/validate", filename: validationSuccessMockFilename)
        remote.validateInvitation(321, usernameOrEmail: "someValidUser", role: .Follower) { success in
            NSLog("Success: \(success)")
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)
    }

    func testSendInvitationToInvalidUsernameFails() {
        let expectation = expectationWithDescription("Validate Invite")

        stubRemoteResponse("invites/new", filename: sendFailureMockFilename)
        remote.sendInvitation(321, usernameOrEmail: "someInvalidUser", role: .Follower, message: "") { success in
            XCTAssertFalse(success)
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)
    }

    func testSendInvitationToValidUsernameSucceeds() {
        let expectation = expectationWithDescription("Validate Invite")

        stubRemoteResponse("invites/new", filename: sendSuccessMockFilename)
        remote.sendInvitation(321, usernameOrEmail: "someValidUser", role: .Follower, message: "") { success in
            XCTAssertTrue(success)
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(timeout, handler: nil)
    }
}
