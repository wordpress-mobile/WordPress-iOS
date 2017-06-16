@testable import WordPressKit
import XCTest

class AccountSettingsRemoteTests: RemoteTestCase, RESTTestable {

    // MARK: - Constants

    let siteID   = 321
    let username = "jimthetester"
    let email    = "jimthetester@thetestemail.org"
    let token    = "token"
    let userURL  = "http://jimthetester.blog"

    let changedSiteID       = 11112222
    let changedFirstName    = "Jimmy"
    let changedLastName     = "Test"
    let changedDisplayName  = "jimmy"
    let changedEmail        = "jimthetester-newemail@thetestemail.org"
    let changedUserURL      = "http://jimthetester.wordpress.com"
    let changedAboutMe      = "I like the color blue and paperclips!"

    let meSettingsEndpoint  = "me/settings"

    let getAccountSettingsSuccessMockFilename        = "me-settings-success.json"
    let getAccountSettingsAuthFailureMockFilename    = "me-settings-auth-failure.json"
    let getAccountSettingsBadJsonFailureMockFilename = "me-settings-bad-json-failure.json"

    let updateSettingsChangeEmailSuccessMockFilename               = "me-settings-change-email-success.json"
    let updateSettingsRevertEmailSuccessMockFilename               = "me-settings-revert-email-success.json"
    let updateSettingsChangeSiteSuccessMockFilename                = "me-settings-change-primary-site-success.json"
    let updateSettingsChangeWebAddressSuccessMockFilename          = "me-settings-change-web-address-success.json"
    let updateSettingsChangeAboutMeSuccessMockFilename             = "me-settings-change-aboutme-success.json"
    let updateSettingsChangeFirstNameSuccessMockFilename           = "me-settings-change-firstname-success.json"
    let updateSettingsChangeLastNameSuccessMockFilename            = "me-settings-change-lastname-success.json"
    let updateSettingsChangeDisplayNameSuccessMockFilename         = "me-settings-change-display-name-success.json"
    let updateSettingsChangeDisplayNameBadJsonFailureMockFilename  = "me-settings-change-display-name-bad-json-failure.json"
    let updateSettingsInvalidInputFailureMockFilename              = "me-settings-change-invalid-input-failure.json"

    // MARK: - Properties

    var remote: AccountSettingsRemote!

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()

        remote = AccountSettingsRemote.remoteWithApi(getRestApi())
    }

    override func tearDown() {
        super.tearDown()

        remote = nil
    }

    // MARK: - Get Account Settings Tests

    func testGetAccountSettingsSucceeds() {
        let expect = expectation(description: "Get account settings success")

        stubRemoteResponse(meSettingsEndpoint, filename: getAccountSettingsSuccessMockFilename, contentType: .ApplicationJSON)
        remote.getSettings(success: { settings in
            XCTAssertEqual(settings.username, self.username, "The usernames should be equal.")
            XCTAssertEqual(settings.email, self.email, "The email addresses should be equal.")
            XCTAssertEqual(settings.webAddress, self.userURL, "The web addresses should be equal.")
            XCTAssertEqual(settings.primarySiteID, self.siteID, "The primary site ID's should be equal.")
            expect.fulfill()
        }) { error in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetAccountSettingsWithServerErrorFails() {
        let expect = expectation(description: "Get account settings server error failure")

        stubRemoteResponse(meSettingsEndpoint, data: Data(), contentType: .NoContentType, status: 500)
        remote.getSettings(success: { settings in
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

    func testGetAccountSettingsWithBadAuthFails() {
        let expect = expectation(description: "Get account settings with bad auth failure")

        stubRemoteResponse(meSettingsEndpoint, filename: getAccountSettingsAuthFailureMockFilename, contentType: .ApplicationJSON, status: 403)
        remote.getSettings(success: { settings in
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

    func testGetAccountSettingsWithBadJsonFails() {
        let expect = expectation(description: "Get account settings with invalid json response failure")

        stubRemoteResponse(meSettingsEndpoint, filename: getAccountSettingsBadJsonFailureMockFilename, contentType: .ApplicationJSON, status: 200)
        remote.getSettings(success: { settings in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    // MARK: - Update Account Settings Tests

    func testChangeAccountEmailSucceeds() {
        let expect = expectation(description: "Change account email success")

        stubRemoteResponse(meSettingsEndpoint, filename: updateSettingsChangeEmailSuccessMockFilename, contentType: .ApplicationJSON)
        let change = AccountSettingsChange.email(changedEmail)
        remote.updateSetting(change, success: { something in
            expect.fulfill()
        }, failure: { error in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testRevertAccountEmailSucceeds() {
        let expect = expectation(description: "Revert account email success")

        stubRemoteResponse(meSettingsEndpoint, filename: updateSettingsRevertEmailSuccessMockFilename, contentType: .ApplicationJSON)
        remote.updateSetting(.emailRevertPendingChange, success: { something in
            expect.fulfill()
        }, failure: { error in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testChangeAccountPrimarySiteSucceeds() {
        let expect = expectation(description: "Change account primary site success")

        stubRemoteResponse(meSettingsEndpoint, filename: updateSettingsChangeSiteSuccessMockFilename, contentType: .ApplicationJSON)
        let change = AccountSettingsChange.primarySite(changedSiteID)
        remote.updateSetting(change, success: { something in
            expect.fulfill()
        }, failure: { error in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testChangeAccountWebAddressSucceeds() {
        let expect = expectation(description: "Change account web address success")

        stubRemoteResponse(meSettingsEndpoint, filename: updateSettingsChangeWebAddressSuccessMockFilename, contentType: .ApplicationJSON)
        let change = AccountSettingsChange.webAddress(changedUserURL)
        remote.updateSetting(change, success: { something in
            expect.fulfill()
        }, failure: { error in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testChangeAccountAboutMeSucceeds() {
        let expect = expectation(description: "Change account about me success")

        stubRemoteResponse(meSettingsEndpoint, filename: updateSettingsChangeAboutMeSuccessMockFilename, contentType: .ApplicationJSON)
        let change = AccountSettingsChange.aboutMe(changedAboutMe)
        remote.updateSetting(change, success: { something in
            expect.fulfill()
        }, failure: { error in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testChangeAccountFirstNameSucceeds() {
        let expect = expectation(description: "Change account first name success")

        stubRemoteResponse(meSettingsEndpoint, filename: updateSettingsChangeFirstNameSuccessMockFilename, contentType: .ApplicationJSON)
        let change = AccountSettingsChange.firstName(changedFirstName)
        remote.updateSetting(change, success: { something in
            expect.fulfill()
        }, failure: { error in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testChangeAccountLastNameSucceeds() {
        let expect = expectation(description: "Change account last name success")

        stubRemoteResponse(meSettingsEndpoint, filename: updateSettingsChangeLastNameSuccessMockFilename, contentType: .ApplicationJSON)
        let change = AccountSettingsChange.lastName(changedLastName)
        remote.updateSetting(change, success: { something in
            expect.fulfill()
        }, failure: { error in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testChangeAccountDisplayNameSucceeds() {
        let expect = expectation(description: "Change account display name success")

        stubRemoteResponse(meSettingsEndpoint, filename: updateSettingsChangeDisplayNameSuccessMockFilename, contentType: .ApplicationJSON)
        let change = AccountSettingsChange.displayName(changedDisplayName)
        remote.updateSetting(change, success: { something in
            expect.fulfill()
        }, failure: { error in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testChangeAccountSettingsWithServerErrorFails() {
        let expect = expectation(description: "Change account settings server error failure")

        stubRemoteResponse(meSettingsEndpoint, data: Data(), contentType: .NoContentType, status: 500)
        let change = AccountSettingsChange.displayName(changedDisplayName)
        remote.updateSetting(change, success: { something in
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

    func testChangeAccountSettingsWithBadJsonFails() {
        let expect = expectation(description: "Change account settings with invalid json response failure")

        stubRemoteResponse(meSettingsEndpoint, filename: updateSettingsChangeDisplayNameBadJsonFailureMockFilename, contentType: .ApplicationJSON, status: 200)
        let change = AccountSettingsChange.displayName(changedDisplayName)
        remote.updateSetting(change, success: { something in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testChangeAccountSettingsWithInvalidInputResponseFails() {
        let expect = expectation(description: "Change account settings with invalid input response error failure")

        stubRemoteResponse(meSettingsEndpoint, filename: updateSettingsInvalidInputFailureMockFilename, contentType: .ApplicationJSON, status: 400)
        let change = AccountSettingsChange.displayName(changedDisplayName)
        remote.updateSetting(change, success: { something in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            let error = error as NSError
            XCTAssertEqual(error.domain, String(reflecting: WordPressComRestApiError.self), "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, WordPressComRestApiError.invalidInput.rawValue, "The error code should be 0 - invalid input")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }
}
