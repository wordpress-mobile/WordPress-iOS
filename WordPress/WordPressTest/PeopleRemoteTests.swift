import Foundation
import XCTest
import OHHTTPStubs
@testable import WordPress

class PeopleServiceTests: XCTestCase {
    // MARK: - Constants

    let validationSuccessMockFilename       = "people-validate-invitation-success.json"
    let validationFailureMockFilename       = "people-validate-invitation-failure.json"
    let sendSuccessMockFilename             = "people-send-invitation-success.json"
    let sendFailureMockFilename             = "people-send-invitation-failure.json"
    let deleteFollowerFailureMockFilename   = "people-delete-follower-failure.json"
    let deleteFollowerSuccessMockFilename   = "people-delete-follower-success.json"
    let contentTypeJson                     = "application/json"
    let timeout                             = TimeInterval(1000)

    // MARK: - Properties

    var restApi: WordPressComRestApi!
    var remote: PeopleRemote!


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

    fileprivate func stubRemoteResponse(_ endpoint: String, filename: String, status: Int32 = 200) {
        stub(condition: { request in
            return request.url?.absoluteString.range(of: endpoint) != nil
        }) { _ in
            let stubPath = OHPathForFile(filename, type(of: self))
            return fixture(filePath: stubPath!, status: status, headers: ["Content-Type" as NSObject: self.contentTypeJson as AnyObject])
        }
    }


    // MARK: - Tests

    func testValidateInvitationWithInvalidUsernameFails() {
        let expect = expectation(description: "Send Invite")

        stubRemoteResponse("invites/validate", filename: validationFailureMockFilename)
        remote.validateInvitation(321, usernameOrEmail: "someInvalidUser", role: .Follower, success: {
            XCTAssert(false, "This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testValidateInvitationWithValidUsernameSucceeds() {
        let expect = expectation(description: "Send Invite")

        stubRemoteResponse("invites/validate", filename: validationSuccessMockFilename)
        remote.validateInvitation(321, usernameOrEmail: "someValidUser", role: .Follower, success: {
            expect.fulfill()
        }, failure: { error in
            XCTAssert(false, "This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testSendInvitationToInvalidUsernameFails() {
        let expect = expectation(description: "Validate Invite")

        stubRemoteResponse("invites/new", filename: sendFailureMockFilename)
        remote.sendInvitation(321, usernameOrEmail: "someInvalidUser", role: .Follower, message: "", success: {
            XCTAssert(false, "This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testSendInvitationToValidUsernameSucceeds() {
        let expect = expectation(description: "Validate Invite")

        stubRemoteResponse("invites/new", filename: sendSuccessMockFilename)
        remote.sendInvitation(321, usernameOrEmail: "someValidUser", role: .Follower, message: "", success: {
            expect.fulfill()
        }, failure: { error in
            XCTAssert(false, "This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testDeleteFollowerWithInvalidUserFails() {
        let expect = expectation(description: "Delete Follower")
        let followerID = 123
        let siteID = 321

        stubRemoteResponse("sites/\(siteID)/followers/\(followerID)/delete", filename: deleteFollowerFailureMockFilename, status: 404)
        remote.deleteFollower(siteID, userID: followerID, success: {
            XCTAssert(false, "This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testDeleteFollowerWithValidUserSucceeds() {
        let expect = expectation(description: "Delete Follower")
        let followerID = 123
        let siteID = 321

        stubRemoteResponse("sites/\(siteID)/followers/\(followerID)/delete", filename: deleteFollowerSuccessMockFilename)
        remote.deleteFollower(siteID, userID: followerID, success: {
            expect.fulfill()
        }, failure: { error in
            XCTAssert(false, "This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }
}
