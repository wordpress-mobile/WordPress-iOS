import XCTest

@testable import WordPress

class SigninHelperTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testBaseSiteURL() {
        var baseURL = "testsite.wordpress.com"
        var url = SigninHelpers.baseSiteURL(string: "http://\(baseURL)")
        XCTAssert(url == "https://\(baseURL)", "Should force https for a wpcom site having http.")

        url = SigninHelpers.baseSiteURL(string: baseURL)
        XCTAssert(url == "https://\(baseURL)", "Should force https for a wpcom site without a scheme.")

        baseURL = "www.selfhostedsite.com"
        url = SigninHelpers.baseSiteURL(string: baseURL)
        XCTAssert((url == "http://\(baseURL)"), "Should add http:\\ for a non wpcom site missing a scheme.")

        url = SigninHelpers.baseSiteURL(string: "\(baseURL)/wp-login.php")
        XCTAssert((url == "http://\(baseURL)"), "Should remove wp-login.php from the path.")

        url = SigninHelpers.baseSiteURL(string: "\(baseURL)/wp-admin")
        XCTAssert((url == "http://\(baseURL)"), "Should remove /wp-admin from the path.")

        url = SigninHelpers.baseSiteURL(string: "\(baseURL)/wp-admin/")
        XCTAssert((url == "http://\(baseURL)"), "Should remove /wp-admin/ from the path.")

        url = SigninHelpers.baseSiteURL(string: "\(baseURL)/")
        XCTAssert((url == "http://\(baseURL)"), "Should remove a trailing slash from the url.")

        // Check non-latin characters and puny code
        baseURL = "http://例.例"
        let punycode = "http://xn--fsq.xn--fsq"
        url = SigninHelpers.baseSiteURL(string: baseURL)
        XCTAssert(url == baseURL)
        url = SigninHelpers.baseSiteURL(string: punycode)
        XCTAssert(url == baseURL)
    }


    func testValidateFieldsPopulatedForSignin() {
        let loginFields = LoginFields()
        loginFields.userIsDotCom = true

        XCTAssert(!SigninHelpers.validateFieldsPopulatedForSignin(loginFields), "Empty fields should not validate.")

        loginFields.username = "user"
        XCTAssert(!SigninHelpers.validateFieldsPopulatedForSignin(loginFields), "Should not validate with just a username")

        loginFields.password = "password"
        XCTAssert(SigninHelpers.validateFieldsPopulatedForSignin(loginFields), "should validate wpcom with username and password.")

        loginFields.userIsDotCom = false
        XCTAssert(!SigninHelpers.validateFieldsPopulatedForSignin(loginFields), "should not validate self-hosted with just username and password.")

        loginFields.siteUrl = "example.com"
        XCTAssert(SigninHelpers.validateFieldsPopulatedForSignin(loginFields), "should validate self-hosted with username, password, and site.")
    }

    func testExtractUsernameFrom() {
        let plainUsername = "auser"
        XCTAssertEqual(plainUsername, SigninHelpers.extractUsername(from: plainUsername))

        let nonWPComSite = "asite.mycompany.com"
        XCTAssertEqual(nonWPComSite, SigninHelpers.extractUsername(from: nonWPComSite))

        let wpComSite = "testuser.wordpress.com"
        XCTAssertEqual("testuser", SigninHelpers.extractUsername(from:wpComSite))

        let wpComSiteSlash = "testuser.wordpress.com/"
        XCTAssertEqual("testuser", SigninHelpers.extractUsername(from:wpComSiteSlash))

        let wpComSiteHttp = "http://testuser.wordpress.com/"
        XCTAssertEqual("testuser", SigninHelpers.extractUsername(from:wpComSiteHttp))

        let nonWPComSiteFtp = "ftp://asite.mycompany.co/"
        XCTAssertEqual("asite.mycompany.co", SigninHelpers.extractUsername(from: nonWPComSiteFtp))
    }

    func testIsWPComDomain() {
        let plainUsername = "auser"
        XCTAssertFalse(SigninHelpers.isWPComDomain(plainUsername))

        let nonWPComSite = "asite.mycompany.com"
        XCTAssertFalse(SigninHelpers.isWPComDomain(nonWPComSite))

        let wpComSite = "testuser.wordpress.com"
        XCTAssert(SigninHelpers.isWPComDomain(wpComSite))
    }


    func testValidateSiteForSignin() {
        let loginFields = LoginFields()

        loginFields.siteUrl = ""
        XCTAssert(!SigninHelpers.validateSiteForSignin(loginFields), "Empty site should not validate.")

        loginFields.siteUrl = "hostname"
        XCTAssert(SigninHelpers.validateSiteForSignin(loginFields), "Just a host name should validate.")

        loginFields.siteUrl = "host name.com"
        XCTAssert(!SigninHelpers.validateSiteForSignin(loginFields), "Hostname with spaces should not validate.")
    }


    func testEmailAddressTokenHandling() {
        let email = "example@email.com"

        SigninHelpers.saveEmailAddressForTokenAuth(email)
        var retrievedEmail = SigninHelpers.getEmailAddressForTokenAuth()
        XCTAssert(email == retrievedEmail, "The email retrived should match the email that was saved.")

        SigninHelpers.deleteEmailAddressForTokenAuth()
        retrievedEmail = SigninHelpers.getEmailAddressForTokenAuth()
        XCTAssert(retrievedEmail == nil, "Saved email should be deleted after calling deleteEmailAddressForTokenAuth.")
    }

}
