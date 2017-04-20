@testable import WordPress

class PeopleServiceRemoteTests: RemoteTestCase {

    // MARK: - Constants

    let viewerID        = 123
    let followerID      = 987
    let siteID          = 321
    let validUsername   = "someValidUser"
    let invalidUsername = "someInvalidUser"

    let newInviteEndpoint       = "invites/new"
    let validateInviteEndpoint  = "invites/validate"

    let validationSuccessMockFilename       = "people-validate-invitation-success.json"
    let validationFailureMockFilename       = "people-validate-invitation-failure.json"
    let sendSuccessMockFilename             = "people-send-invitation-success.json"
    let sendFailureMockFilename             = "people-send-invitation-failure.json"
    let deleteFollowerFailureMockFilename   = "people-delete-follower-failure.json"
    let deleteFollowerSuccessMockFilename   = "people-delete-follower-success.json"
    let deleteViewerFailureMockFilename     = "people-delete-viewer-failure.json"
    let deleteViewerSuccessMockFilename     = "people-delete-viewer-success.json"

    // MARK: - Properties

    var remote: PeopleServiceRemote!

    var siteViewerDeleteEndpoint: String { return "sites/\(siteID)/viewers/\(viewerID)/delete" }
    var siteFollowerDeleteEndpoint: String { return "sites/\(siteID)/followers/\(followerID)/delete" }


    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
        remote = PeopleServiceRemote(wordPressComRestApi: restApi)
    }

    // MARK: - Tests

    func testValidateInvitationWithInvalidUsernameFails() {
        let expect = expectation(description: "Validate invite failure")

        stubRemoteResponse(validateInviteEndpoint, filename: validationFailureMockFilename, contentType: .ApplicationJSON)
        remote.validateInvitation(siteID, usernameOrEmail: invalidUsername, role: .Follower, success: {
            XCTAssert(false, "This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testValidateInvitationWithValidUsernameSucceeds() {
        let expect = expectation(description: "Validate invite success")

        stubRemoteResponse(validateInviteEndpoint, filename: validationSuccessMockFilename, contentType: .ApplicationJSON)
        remote.validateInvitation(siteID, usernameOrEmail: validUsername, role: .Follower, success: {
            expect.fulfill()
        }, failure: { error in
            XCTAssert(false, "This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testSendInvitationToInvalidUsernameFails() {
        let expect = expectation(description: "Send invite failure")

        stubRemoteResponse(newInviteEndpoint, filename: sendFailureMockFilename, contentType: .ApplicationJSON)
        remote.sendInvitation(siteID, usernameOrEmail: invalidUsername, role: .Follower, message: "", success: {
            XCTAssert(false, "This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testSendInvitationToValidUsernameSucceeds() {
        let expect = expectation(description: "Send invite success")

        stubRemoteResponse(newInviteEndpoint, filename: sendSuccessMockFilename, contentType: .ApplicationJSON)
        remote.sendInvitation(siteID, usernameOrEmail: validUsername, role: .Follower, message: "", success: {
            expect.fulfill()
        }, failure: { error in
            XCTAssert(false, "This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testDeleteFollowerWithInvalidUserFails() {
        let expect = expectation(description: "Delete follower failure")

        stubRemoteResponse(siteFollowerDeleteEndpoint, filename: deleteFollowerFailureMockFilename,
                           contentType: .ApplicationJSON, status: 404)
        remote.deleteFollower(siteID, userID: followerID, success: {
            XCTAssert(false, "This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testDeleteFollowerWithValidUserSucceeds() {
        let expect = expectation(description: "Delete follower success")

        stubRemoteResponse(siteFollowerDeleteEndpoint, filename: deleteFollowerSuccessMockFilename,
                           contentType: .ApplicationJSON)
        remote.deleteFollower(siteID, userID: followerID, success: {
            expect.fulfill()
        }, failure: { error in
            XCTAssert(false, "This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testDeleteViewerWithInvalidUserFails() {
        let expect = expectation(description: "Delete viewer failure")

        stubRemoteResponse(siteViewerDeleteEndpoint, filename: deleteViewerFailureMockFilename,
                           contentType: .ApplicationJSON, status: 404)
        remote.deleteViewer(siteID, userID: viewerID, success: {
            XCTAssert(false, "This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testDeleteViewerWithValidUserSucceeds() {
        let expect = expectation(description: "Delete viewer success")

        stubRemoteResponse(siteViewerDeleteEndpoint, filename: deleteViewerSuccessMockFilename,
                           contentType: .ApplicationJSON)
        remote.deleteViewer(siteID, userID: viewerID, success: {
            expect.fulfill()
        }, failure: { error in
            XCTAssert(false, "This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }
}
