@testable import WordPress

class PeopleServiceRemoteTests: RemoteTestCase {

    // MARK: - Constants

    let siteID          = 321
    let userID          = 1111
    let validUsername   = "jimthetester"
    let viewerID        = 123
    let followerID      = 987
    let invalidSiteID   = 888
    let invalidUserID   = 9999
    let invalidUsername = "someInvalidUser"

    let newInviteEndpoint       = "invites/new"
    let validateInviteEndpoint  = "invites/validate"

    let getRolesSuccessMockFilename                 = "site-roles-success.json"
    let getRolesBadJsonFailureMockFilename          = "site-roles-bad-json-failure.json"
    let getRolesBadAuthMockFilename                 = "site-roles-auth-failure.json"
    let updateRoleSuccessMockFilename               = "site-users-update-role-success.json"
    let updateRoleUnknownUserFailureMockFilename    = "site-users-update-role-unknown-user-failure.json"
    let updateRoleUnknownSiteFailureMockFilename    = "site-users-update-role-unknown-site-failure.json"
    let updateRoleBadJsonFailureMockFilename        = "site-users-update-role-bad-json-failure.json"
    let validationSuccessMockFilename               = "people-validate-invitation-success.json"
    let validationFailureMockFilename               = "people-validate-invitation-failure.json"
    let sendSuccessMockFilename                     = "people-send-invitation-success.json"
    let sendFailureMockFilename                     = "people-send-invitation-failure.json"
    let deleteFollowerFailureMockFilename           = "people-delete-follower-failure.json"
    let deleteFollowerSuccessMockFilename           = "people-delete-follower-success.json"
    let deleteViewerFailureMockFilename             = "people-delete-viewer-failure.json"
    let deleteViewerSuccessMockFilename             = "people-delete-viewer-success.json"

    // MARK: - Properties

    var remote: PeopleServiceRemote!

    var siteRolesEndpoint: String { return "sites/\(siteID)/roles" }
    var siteUserEndpoint: String { return "sites/\(siteID)/users/\(userID)" }
    var siteUnknownUserEndpoint: String { return "sites/\(siteID)/users/\(invalidUserID)" }
    var unknownSiteUserEndpoint: String { return "sites/\(invalidSiteID)/users/\(userID)" }
    var siteViewerDeleteEndpoint: String { return "sites/\(siteID)/viewers/\(viewerID)/delete" }
    var siteFollowerDeleteEndpoint: String { return "sites/\(siteID)/followers/\(followerID)/delete" }


    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
        remote = PeopleServiceRemote(wordPressComRestApi: restApi)
    }

    // MARK: - User Tests


    // MARK: - Follower Tests

    func testDeleteFollowerWithInvalidUserFails() {
        let expect = expectation(description: "Delete follower failure")

        stubRemoteResponse(siteFollowerDeleteEndpoint, filename: deleteFollowerFailureMockFilename,
                           contentType: .ApplicationJSON, status: 404)
        remote.deleteFollower(siteID, userID: followerID, success: {
            XCTFail("This callback shouldn't get called")
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
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    // MARK: - Role Tests

    func testGetSiteRolesSucceeds() {
        let expect = expectation(description: "Get site roles success")

        stubRemoteResponse(siteRolesEndpoint, filename: getRolesSuccessMockFilename,
                           contentType: .ApplicationJSON)
        remote.getUserRoles(siteID, success: { roles in
            XCTAssertFalse(roles.isEmpty, "The returned roles array should not be empty")
            XCTAssertTrue(roles.count == 4, "There should be 4 roles returned")
            expect.fulfill()
        }, failure: { error in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetSiteRolesWithServerErrorFails() {
        let expect = expectation(description: "Get site roles with server error failure")

        stubRemoteResponse(siteRolesEndpoint, data: Data(), contentType: .NoContentType, status: 500)
        remote.getUserRoles(siteID, success: { roles in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            let error = error as NSError
            XCTAssertEqual(error.domain, String(reflecting: WordPressComRestApiError.self), "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, WordPressComRestApiError.unknown.rawValue, "The error code should be 7 - unknown")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetSiteRolesWithBadAuthFails() {
        let expect = expectation(description: "Get site roles with bad auth failure")

        stubRemoteResponse(siteRolesEndpoint, filename: getRolesBadAuthMockFilename, contentType: .ApplicationJSON, status: 403)
        remote.getUserRoles(siteID, success: { roles in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            let error = error as NSError
            XCTAssertEqual(error.domain, String(reflecting: WordPressComRestApiError.self), "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, WordPressComRestApiError.authorizationRequired.rawValue, "The error code should be 2 - authorization_required")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetSiteRolesWithBadJsonFails() {
        let expect = expectation(description: "Get site roles with invalid json response failure")

        stubRemoteResponse(siteRolesEndpoint, filename: getRolesBadJsonFailureMockFilename, contentType: .ApplicationJSON, status: 200)
        remote.getUserRoles(siteID, success: { roles in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testUpdateUserRoleSucceeds() {
        let expect = expectation(description: "Update user role success")

        stubRemoteResponse(siteUserEndpoint, filename: updateRoleSuccessMockFilename, contentType: .ApplicationJSON)
        let change = Role.Admin
        remote.updateUserRole(siteID, userID: userID, newRole: change, success: { updatedPerson in
            XCTAssertEqual(updatedPerson.role, change, "The returned user's role should be the same as the updated role.")
            expect.fulfill()
        }, failure: { error in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testUpdateUserRoleWithUnknownUserFails() {
        let expect = expectation(description: "Update role with unknown user failure")

        stubRemoteResponse(siteUnknownUserEndpoint, filename: updateRoleUnknownUserFailureMockFilename, contentType: .ApplicationJSON, status: 404)
        let change = Role.Admin
        remote.updateUserRole(siteID, userID: invalidUserID, newRole: change, success: { updatedPerson in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testUpdateUserRoleWithUnknownSiteFails() {
        let expect = expectation(description: "Update role with unknown site failure")

        stubRemoteResponse(unknownSiteUserEndpoint, filename: updateRoleUnknownSiteFailureMockFilename, contentType: .ApplicationJSON, status: 403)
        let change = Role.Admin
        remote.updateUserRole(invalidSiteID, userID: userID, newRole: change, success: { updatedPerson in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testUpdateUserRoleWithServerErrorFails() {
        let expect = expectation(description: "Update role with server error failure")

        stubRemoteResponse(siteUserEndpoint, data: Data(), contentType: .NoContentType, status: 500)
        let change = Role.Admin
        remote.updateUserRole(siteID, userID: userID, newRole: change, success: { updatedPerson in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            let error = error as NSError
            XCTAssertEqual(error.domain, String(reflecting: WordPressComRestApiError.self), "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, WordPressComRestApiError.unknown.rawValue, "The error code should be 7 - unknown")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testUpdateUserRoleWithBadJsonFails() {
        let expect = expectation(description: "Update role with invalid json response failure")

        stubRemoteResponse(siteUserEndpoint, filename: updateRoleBadJsonFailureMockFilename, contentType: .ApplicationJSON, status: 200)
        let change = Role.Admin
        remote.updateUserRole(siteID, userID: userID, newRole: change, success: { updatedPerson in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            expect.fulfill()
        })
        
        waitForExpectations(timeout: timeout, handler: nil)
    }


    // MARK: - Viewer Tests

    func testDeleteViewerWithInvalidUserFails() {
        let expect = expectation(description: "Delete viewer failure")

        stubRemoteResponse(siteViewerDeleteEndpoint, filename: deleteViewerFailureMockFilename,
                           contentType: .ApplicationJSON, status: 404)
        remote.deleteViewer(siteID, userID: viewerID, success: {
            XCTFail("This callback shouldn't get called")
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
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    // MARK: - Invite Tests

    func testSendInvitationToInvalidUsernameFails() {
        let expect = expectation(description: "Send invite failure")

        stubRemoteResponse(newInviteEndpoint, filename: sendFailureMockFilename, contentType: .ApplicationJSON)
        remote.sendInvitation(siteID, usernameOrEmail: invalidUsername, role: .Follower, message: "", success: {
            XCTFail("This callback shouldn't get called")
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
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testValidateInvitationWithInvalidUsernameFails() {
        let expect = expectation(description: "Validate invite failure")

        stubRemoteResponse(validateInviteEndpoint, filename: validationFailureMockFilename, contentType: .ApplicationJSON)
        remote.validateInvitation(siteID, usernameOrEmail: invalidUsername, role: .Follower, success: {
            XCTFail("This callback shouldn't get called")
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
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }
}
