import Foundation
import XCTest
@testable import WordPressKit

class PeopleServiceRemoteTests: RemoteTestCase, RESTTestable {

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

    let deleteUserSuccessMockFilename               = "site-users-delete-success.json"
    let deleteUserAuthFailureMockFilename           = "site-users-delete-auth-failure.json"
    let deleteUserBadJsonFailureMockFilename        = "site-users-delete-bad-json-failure.json"
    let deleteUserNonMemberFailureMockFilename      = "site-users-delete-not-member-failure.json"
    let deleteUserSiteOwnerFailureMockFilename      = "site-users-delete-site-owner-failure.json"

    let deleteFollowerSuccessMockFilename           = "site-followers-delete-success.json"
    let deleteFollowerFailureMockFilename           = "site-followers-delete-failure.json"
    let deleteFollowerAuthFailureMockFilename       = "site-followers-delete-auth-failure.json"
    let deleteFollowerBadJsonFailureMockFilename    = "site-followers-delete-bad-json-failure.json"

    let deleteViewerSuccessMockFilename             = "site-viewers-delete-success.json"
    let deleteViewerFailureMockFilename             = "site-viewers-delete-failure.json"
    let deleteViewerAuthFailureMockFilename         = "site-viewers-delete-auth-failure.json"
    let deleteViewerBadJsonFailureMockFilename      = "site-viewers-delete-bad-json.json"

    let inviteLinksFetchInvitesMockFilename         = "sites-invites.json"
    let inviteLinksGenerateMockFilename             = "sites-invites-links-generate.json"
    let inviteLinksDisableMockFilename              = "sites-invites-links-disable.json"
    let inviteLinksDisableEmptyMockFilename         = "sites-invites-links-disable-empty.json"

    let emailFollowersSuccessMockFilename           = "site-email-followers-get-success.json"
    let emailFollowersSuccessMorePagesMockFilename  = "site-email-followers-get-success-more-pages.json"

    let emailFollowersAuthFailureMockFilename       = "site-email-followers-get-auth-failure.json"
    let emailFollowersFailureMockFilename           = "site-email-followers-get-failure.json"

    // MARK: - Properties

    var remote: PeopleServiceRemote!

    var siteRolesEndpoint: String { return "sites/\(siteID)/roles" }
    var siteUserEndpoint: String { return "sites/\(siteID)/users/\(userID)" }
    var siteUnknownUserEndpoint: String { return "sites/\(siteID)/users/\(invalidUserID)" }
    var unknownSiteUserEndpoint: String { return "sites/\(invalidSiteID)/users/\(userID)" }
    var siteEmailFollowersEndpoint: String { return "sites/\(siteID)/stats/followers" }

    var siteUserDeleteEndpoint: String { return "sites/\(siteID)/users/\(userID)/delete" }
    var siteViewerDeleteEndpoint: String { return "sites/\(siteID)/viewers/\(viewerID)/delete" }
    var siteFollowerDeleteEndpoint: String { return "sites/\(siteID)/followers/\(followerID)/delete" }
    var siteEmailFollowerDeleteEndpoint: String { return "sites/\(siteID)/email-followers/\(followerID)/delete" }

    var siteInvitesEndpoint: String { return "sites/\(siteID)/invites" }
    var siteInvitesLinksGenerate: String { return "sites/\(siteID)/invites/links/generate" }
    var siteInvitesLinksDisable: String { return "sites/\(siteID)/invites/links/disable" }

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()

        remote = PeopleServiceRemote(wordPressComRestApi: getRestApi())
    }

    override func tearDown() {
        super.tearDown()

        remote = nil
    }

    // MARK: - User Tests

    func testDeleteUserWithBadAuthUserFails() {
        let expect = expectation(description: "Delete user with bad auth failure")

        stubRemoteResponse(siteUserDeleteEndpoint, filename: deleteUserAuthFailureMockFilename, contentType: .ApplicationJSON, status: 403)
        remote.deleteUser(siteID, userID: userID, success: { () in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            let error = error as NSError
            XCTAssertEqual(error.domain, "WordPressKit.WordPressComRestApiError", "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, WordPressComRestApiErrorCode.authorizationRequired.rawValue, "The error code should be 2 - authorization_required")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testDeleteUserWithSiteOwnerFails() {
        let expect = expectation(description: "Delete user with site owner failure")

        stubRemoteResponse(siteUserDeleteEndpoint, filename: deleteUserSiteOwnerFailureMockFilename, contentType: .ApplicationJSON, status: 403)
        remote.deleteUser(siteID, userID: userID, success: { () in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            let error = error as NSError
            XCTAssertEqual(error.domain, "WordPressKit.WordPressComRestApiError", "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, WordPressComRestApiErrorCode.unknown.rawValue, "The error code should be 7 - unknown")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testDeleteUserWithNonMemberFails() {
        let expect = expectation(description: "Delete user with non site member failure")

        stubRemoteResponse(siteUserDeleteEndpoint, filename: deleteUserNonMemberFailureMockFilename, contentType: .ApplicationJSON, status: 400)
        remote.deleteUser(siteID, userID: userID, success: { () in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            let error = error as NSError
            XCTAssertEqual(error.domain, "WordPressKit.WordPressComRestApiError", "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, WordPressComRestApiErrorCode.invalidInput.rawValue, "The error code should be 0 - invalid input")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testDeleteUserWithValidUserSucceeds() {
        let expect = expectation(description: "Delete user success")

        stubRemoteResponse(siteUserDeleteEndpoint, filename: deleteUserSuccessMockFilename,
                           contentType: .ApplicationJSON)
        remote.deleteUser(siteID, userID: userID, success: {
            expect.fulfill()
        }, failure: { _ in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testDeleteUserWithServerErrorFails() {
        let expect = expectation(description: "Delete user with server error failure")

        stubRemoteResponse(siteUserDeleteEndpoint, data: Data(), contentType: .NoContentType, status: 500)
        remote.deleteUser(siteID, userID: userID, success: {
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            let error = error as NSError
            XCTAssertEqual(error.domain, "WordPressKit.WordPressComRestApiError", "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, WordPressComRestApiErrorCode.unknown.rawValue, "The error code should be 7 - unknown")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testDeleteUserWithBadJsonFails() {
        let expect = expectation(description: "Delete user with invalid json response failure")

        stubRemoteResponse(siteUserDeleteEndpoint, filename: deleteUserBadJsonFailureMockFilename, contentType: .ApplicationJSON, status: 200)
        remote.deleteUser(siteID, userID: userID, success: {
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { _ in
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    // MARK: - Follower Tests

    func testDeleteFollowerWithInvalidFollowerFails() {
        let expect = expectation(description: "Delete non-follower failure")

        stubRemoteResponse(siteFollowerDeleteEndpoint, filename: deleteFollowerFailureMockFilename,
                           contentType: .ApplicationJSON, status: 404)
        remote.deleteFollower(siteID, userID: followerID, success: {
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            let error = error as NSError
            XCTAssertEqual(error.domain, "WordPressKit.WordPressComRestApiError", "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, WordPressComRestApiErrorCode.unknown.rawValue, "The error code should be 7 - unknown")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testDeleteFollowerWithBadAuthFails() {
        let expect = expectation(description: "Delete follower with bad auth failure")

        stubRemoteResponse(siteFollowerDeleteEndpoint, filename: deleteFollowerAuthFailureMockFilename, contentType: .ApplicationJSON, status: 403)
        remote.deleteFollower(siteID, userID: followerID, success: {
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            let error = error as NSError
            XCTAssertEqual(error.domain, "WordPressKit.WordPressComRestApiError", "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, WordPressComRestApiErrorCode.authorizationRequired.rawValue, "The error code should be 2 - authorization_required")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testDeleteFollowerWithValidFollowerSucceeds() {
        let expect = expectation(description: "Delete follower success")

        stubRemoteResponse(siteFollowerDeleteEndpoint, filename: deleteFollowerSuccessMockFilename,
                           contentType: .ApplicationJSON)
        remote.deleteFollower(siteID, userID: followerID, success: {
            expect.fulfill()
        }, failure: { _ in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testDeleteFollowerWithServerErrorFails() {
        let expect = expectation(description: "Delete follower with server error failure")

        stubRemoteResponse(siteFollowerDeleteEndpoint, data: Data(), contentType: .NoContentType, status: 500)
        remote.deleteFollower(siteID, userID: followerID, success: {
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            let error = error as NSError
            XCTAssertEqual(error.domain, "WordPressKit.WordPressComRestApiError", "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, WordPressComRestApiErrorCode.unknown.rawValue, "The error code should be 7 - unknown")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testDeleteFollowerWithBadJsonFails() {
        let expect = expectation(description: "Delete follower with invalid json response failure")

        stubRemoteResponse(siteFollowerDeleteEndpoint, filename: deleteFollowerBadJsonFailureMockFilename, contentType: .ApplicationJSON, status: 200)
        remote.deleteFollower(siteID, userID: followerID, success: {
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { _ in
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    // MARK: - Email follower tests

    func testGetEmailFollowersSuccess() {
        // Given
        let expect = expectation(description: "Get email followers success")
        stubRemoteResponse(siteEmailFollowersEndpoint, filename: emailFollowersSuccessMockFilename, contentType: .ApplicationJSON, status: 200)

        // When
        remote.getEmailFollowers(siteID, page: 1, max: 1, success: { followers, hasMore in
            // Then
            XCTAssertTrue(followers.count > 0)
            XCTAssertFalse(hasMore)
            expect.fulfill()
        }, failure: { _ in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetEmailFollowersSuccessWithMorePages() {
        // Given
        let expect = expectation(description: "Get email followers success")
        stubRemoteResponse(siteEmailFollowersEndpoint, filename: emailFollowersSuccessMorePagesMockFilename, contentType: .ApplicationJSON, status: 200)

        // When
        remote.getEmailFollowers(siteID, page: 1, max: 1, success: { followers, hasMore in
            // Then
            XCTAssertTrue(followers.count > 0)
            XCTAssertTrue(hasMore)
            expect.fulfill()
        }, failure: { _ in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetEmailFollowersNotAuthorizedFailure() {
        // Given
        let expect = expectation(description: "Get email followers not authorized failure")
        stubRemoteResponse(siteEmailFollowersEndpoint, filename: emailFollowersAuthFailureMockFilename, contentType: .ApplicationJSON, status: 403)

        // When
        remote.getEmailFollowers(siteID, page: 1, max: 1, success: { _, _ in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            // Then
            let error = error as NSError
            XCTAssertEqual(error.domain, "WordPressKit.WordPressComRestApiError", "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, WordPressComRestApiErrorCode.authorizationRequired.rawValue, "The error code should be 2 - authorization required")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetEmailFollowersFailure() {
        // Given
        let expect = expectation(description: "Get email followers failure")
        stubRemoteResponse(siteEmailFollowersEndpoint, filename: emailFollowersFailureMockFilename, contentType: .ApplicationJSON, status: 404)

        // When
        remote.getEmailFollowers(siteID, page: 1, max: 1, success: { _, _ in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            // Then
            let error = error as NSError
            XCTAssertEqual(error.domain, "WordPressKit.WordPressComRestApiError", "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, WordPressComRestApiErrorCode.unknown.rawValue, "The error code should be 7 - unknown")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testDeleteEmailFollowerWithInvalidFollowerFails() {
        // Given
        let expect = expectation(description: "Delete non-follower failure")
        stubRemoteResponse(siteEmailFollowerDeleteEndpoint, filename: deleteFollowerFailureMockFilename, contentType: .ApplicationJSON, status: 404)

        // When
        remote.deleteEmailFollower(siteID, userID: followerID, success: {
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            // Then
            let error = error as NSError
            XCTAssertEqual(error.domain, "WordPressKit.WordPressComRestApiError", "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, WordPressComRestApiErrorCode.unknown.rawValue, "The error code should be 7 - unknown")
            expect.fulfill()
        })
        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testDeleteEmailFollowerWithBadAuthFails() {
        // Given
        let expect = expectation(description: "Delete email follower with bad auth failure")
        stubRemoteResponse(siteEmailFollowerDeleteEndpoint, filename: deleteFollowerAuthFailureMockFilename, contentType: .ApplicationJSON, status: 403)

        // When
        remote.deleteEmailFollower(siteID, userID: followerID, success: {
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            // Then
            let error = error as NSError
            XCTAssertEqual(error.domain, "WordPressKit.WordPressComRestApiError", "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, WordPressComRestApiErrorCode.authorizationRequired.rawValue, "The error code should be 2 - authorization_required")
            expect.fulfill()
        })
        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testDeleteEmailFollowerWithValidFollowerSucceeds() {
        // Given
        let expect = expectation(description: "Delete email follower success")
        stubRemoteResponse(siteEmailFollowerDeleteEndpoint, filename: deleteFollowerSuccessMockFilename, contentType: .ApplicationJSON)

        // When
        remote.deleteEmailFollower(siteID, userID: followerID, success: {
            // Then
            expect.fulfill()
        }, failure: { _ in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })
        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testDeleteEmailFollowerWithServerErrorFails() {
        // Given
        let expect = expectation(description: "Delete email follower with server error failure")
        stubRemoteResponse(siteEmailFollowerDeleteEndpoint, data: Data(), contentType: .NoContentType, status: 500)

        // When
        remote.deleteEmailFollower(siteID, userID: followerID, success: {
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            // Then
            let error = error as NSError
            XCTAssertEqual(error.domain, "WordPressKit.WordPressComRestApiError", "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, WordPressComRestApiErrorCode.unknown.rawValue, "The error code should be 7 - unknown")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testDeleteEmailFollowerWithBadJsonFails() {
        // Given
        let expect = expectation(description: "Delete email follower with invalid json response failure")
        stubRemoteResponse(siteEmailFollowerDeleteEndpoint, filename: deleteFollowerBadJsonFailureMockFilename, contentType: .ApplicationJSON, status: 200)

        // When
        remote.deleteEmailFollower(siteID, userID: followerID, success: {
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { _ in
            // Then
            expect.fulfill()
        })
        waitForExpectations(timeout: timeout, handler: nil)
    }

    // MARK: - Viewer Tests

    func testDeleteViewerWithInvalidViewerFails() {
        let expect = expectation(description: "Delete viewer failure")

        stubRemoteResponse(siteViewerDeleteEndpoint, filename: deleteViewerFailureMockFilename,
                           contentType: .ApplicationJSON, status: 404)
        remote.deleteViewer(siteID, userID: viewerID, success: {
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { _ in
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testDeleteViewerWithValidViewerSucceeds() {
        let expect = expectation(description: "Delete viewer success")

        stubRemoteResponse(siteViewerDeleteEndpoint, filename: deleteViewerSuccessMockFilename,
                           contentType: .ApplicationJSON)
        remote.deleteViewer(siteID, userID: viewerID, success: {
            expect.fulfill()
        }, failure: { _ in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testDeleteViewerWithBadAuthFails() {
        let expect = expectation(description: "Delete viewer with bad auth failure")

        stubRemoteResponse(siteViewerDeleteEndpoint, filename: deleteViewerAuthFailureMockFilename, contentType: .ApplicationJSON, status: 403)
        remote.deleteViewer(siteID, userID: viewerID, success: {
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            let error = error as NSError
            XCTAssertEqual(error.domain, "WordPressKit.WordPressComRestApiError", "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, WordPressComRestApiErrorCode.authorizationRequired.rawValue, "The error code should be 2 - authorization_required")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testDeleteViewerWithServerErrorFails() {
        let expect = expectation(description: "Delete viewer with server error failure")

        stubRemoteResponse(siteViewerDeleteEndpoint, data: Data(), contentType: .NoContentType, status: 500)
        remote.deleteViewer(siteID, userID: viewerID, success: {
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            let error = error as NSError
            XCTAssertEqual(error.domain, "WordPressKit.WordPressComRestApiError", "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, WordPressComRestApiErrorCode.unknown.rawValue, "The error code should be 7 - unknown")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testDeleteViewerWithBadJsonFails() {
        let expect = expectation(description: "Delete viewer with invalid json response failure")

        stubRemoteResponse(siteViewerDeleteEndpoint, filename: deleteViewerBadJsonFailureMockFilename, contentType: .ApplicationJSON, status: 200)
        remote.deleteViewer(siteID, userID: viewerID, success: {
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { _ in
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
        }, failure: { _ in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetSiteRolesWithServerErrorFails() {
        let expect = expectation(description: "Get site roles with server error failure")

        stubRemoteResponse(siteRolesEndpoint, data: Data(), contentType: .NoContentType, status: 500)
        remote.getUserRoles(siteID, success: { _ in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            let error = error as NSError
            XCTAssertEqual(error.domain, "WordPressKit.WordPressComRestApiError", "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, WordPressComRestApiErrorCode.unknown.rawValue, "The error code should be 7 - unknown")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetSiteRolesWithBadAuthFails() {
        let expect = expectation(description: "Get site roles with bad auth failure")

        stubRemoteResponse(siteRolesEndpoint, filename: getRolesBadAuthMockFilename, contentType: .ApplicationJSON, status: 403)
        remote.getUserRoles(siteID, success: { _ in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            let error = error as NSError
            XCTAssertEqual(error.domain, "WordPressKit.WordPressComRestApiError", "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, WordPressComRestApiErrorCode.authorizationRequired.rawValue, "The error code should be 2 - authorization_required")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetSiteRolesWithBadJsonFails() {
        let expect = expectation(description: "Get site roles with invalid json response failure")

        stubRemoteResponse(siteRolesEndpoint, filename: getRolesBadJsonFailureMockFilename, contentType: .ApplicationJSON, status: 200)
        remote.getUserRoles(siteID, success: { _ in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { _ in
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testUpdateUserRoleSucceeds() {
        let expect = expectation(description: "Update user role success")

        stubRemoteResponse(siteUserEndpoint, filename: updateRoleSuccessMockFilename, contentType: .ApplicationJSON)
        let change = "administrator"
        remote.updateUserRole(siteID, userID: userID, newRole: change, success: { updatedPerson in
            XCTAssertEqual(updatedPerson.role, change, "The returned user's role should be the same as the updated role.")
            expect.fulfill()
        }, failure: { _ in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testUpdateUserRoleWithUnknownUserFails() {
        let expect = expectation(description: "Update role with unknown user failure")

        stubRemoteResponse(siteUnknownUserEndpoint, filename: updateRoleUnknownUserFailureMockFilename, contentType: .ApplicationJSON, status: 404)
        let change = "administrator"
        remote.updateUserRole(siteID, userID: invalidUserID, newRole: change, success: { _ in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { _ in
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testUpdateUserRoleWithUnknownSiteFails() {
        let expect = expectation(description: "Update role with unknown site failure")

        stubRemoteResponse(unknownSiteUserEndpoint, filename: updateRoleUnknownSiteFailureMockFilename, contentType: .ApplicationJSON, status: 403)
        let change = "administrator"
        remote.updateUserRole(invalidSiteID, userID: userID, newRole: change, success: { _ in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { _ in
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testUpdateUserRoleWithServerErrorFails() {
        let expect = expectation(description: "Update role with server error failure")

        stubRemoteResponse(siteUserEndpoint, data: Data(), contentType: .NoContentType, status: 500)
        let change = "administrator"
        remote.updateUserRole(siteID, userID: userID, newRole: change, success: { _ in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            let error = error as NSError
            XCTAssertEqual(error.domain, "WordPressKit.WordPressComRestApiError", "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, WordPressComRestApiErrorCode.unknown.rawValue, "The error code should be 7 - unknown")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testUpdateUserRoleWithBadJsonFails() {
        let expect = expectation(description: "Update role with invalid json response failure")

        stubRemoteResponse(siteUserEndpoint, filename: updateRoleBadJsonFailureMockFilename, contentType: .ApplicationJSON, status: 200)
        let change = "administrator"
        remote.updateUserRole(siteID, userID: userID, newRole: change, success: { _ in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { _ in
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    // MARK: - Invite Tests

    func testSendInvitationToInvalidUsernameFails() {
        let expect = expectation(description: "Send invite failure")

        stubRemoteResponse(newInviteEndpoint, filename: sendFailureMockFilename, contentType: .ApplicationJSON)
        remote.sendInvitation(siteID, usernameOrEmail: invalidUsername, role: "follower", message: "", success: {
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { _ in
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testSendInvitationToValidUsernameSucceeds() {
        let expect = expectation(description: "Send invite success")

        stubRemoteResponse(newInviteEndpoint, filename: sendSuccessMockFilename, contentType: .ApplicationJSON)
        remote.sendInvitation(siteID, usernameOrEmail: validUsername, role: "follower", message: "", success: {
            expect.fulfill()
        }, failure: { _ in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testValidateInvitationWithInvalidUsernameFails() {
        let expect = expectation(description: "Validate invite failure")

        stubRemoteResponse(validateInviteEndpoint, filename: validationFailureMockFilename, contentType: .ApplicationJSON)
        remote.validateInvitation(siteID, usernameOrEmail: invalidUsername, role: "follower", success: {
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { _ in
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testValidateInvitationWithValidUsernameSucceeds() {
        let expect = expectation(description: "Validate invite success")

        stubRemoteResponse(validateInviteEndpoint, filename: validationSuccessMockFilename, contentType: .ApplicationJSON)
        remote.validateInvitation(siteID, usernameOrEmail: validUsername, role: "follower", success: {
            expect.fulfill()
        }, failure: { _ in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testFetchInvites() {
        let expect = expectation(description: "Get invite links")

        stubRemoteResponse(siteInvitesEndpoint, filename: inviteLinksFetchInvitesMockFilename,
                           contentType: .ApplicationJSON)
        remote.fetchInvites(siteID, success: { invites in
            XCTAssertFalse(invites.isEmpty, "The returned array should not be empty")
            XCTAssertTrue(invites.count == 5, "There should be 5 invites returned")
            expect.fulfill()
        }, failure: { _ in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGenerateInviteLinks() {
        let expect = expectation(description: "Generate invite links")

        stubRemoteResponse(siteInvitesLinksGenerate, filename: inviteLinksGenerateMockFilename,
                           contentType: .ApplicationJSON)
        remote.generateInviteLinks(siteID, success: { invites in
            XCTAssertFalse(invites.isEmpty, "The returned array should not be empty")
            XCTAssertTrue(invites.count == 5, "There should be 5 invites returned")
            expect.fulfill()
        }, failure: { _ in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testDisableInviteLinks() {
        let expect = expectation(description: "Disable invite links")

        stubRemoteResponse(siteInvitesLinksDisable, filename: inviteLinksDisableMockFilename,
                           contentType: .ApplicationJSON)
        remote.disableInviteLinks(siteID, success: { invites in
            XCTAssertFalse(invites.isEmpty, "The returned array should not be empty")
            XCTAssertTrue(invites.count == 5, "There should be 5 invites returned")
            expect.fulfill()
        }, failure: { _ in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testDisableInviteLinksEmptyResponse() {
        let expect = expectation(description: "Disable invite links empty response")

        stubRemoteResponse(siteInvitesLinksDisable, filename: inviteLinksDisableEmptyMockFilename,
                           contentType: .ApplicationJSON)
        remote.disableInviteLinks(siteID, success: { invites in
            XCTAssertTrue(invites.isEmpty, "The returned array should be empty")
            expect.fulfill()
        }, failure: { _ in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

}
