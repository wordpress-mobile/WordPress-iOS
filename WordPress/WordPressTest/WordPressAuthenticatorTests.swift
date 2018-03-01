import XCTest

@testable import WordPress

class WordPressAuthenticatorTests: XCTestCase {

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
        var url = WordPressAuthenticator.baseSiteURL(string: "http://\(baseURL)")
        XCTAssert(url == "https://\(baseURL)", "Should force https for a wpcom site having http.")

        url = WordPressAuthenticator.baseSiteURL(string: baseURL)
        XCTAssert(url == "https://\(baseURL)", "Should force https for a wpcom site without a scheme.")

        baseURL = "www.selfhostedsite.com"
        url = WordPressAuthenticator.baseSiteURL(string: baseURL)
        XCTAssert((url == "http://\(baseURL)"), "Should add http:\\ for a non wpcom site missing a scheme.")

        url = WordPressAuthenticator.baseSiteURL(string: "\(baseURL)/wp-login.php")
        XCTAssert((url == "http://\(baseURL)"), "Should remove wp-login.php from the path.")

        url = WordPressAuthenticator.baseSiteURL(string: "\(baseURL)/wp-admin")
        XCTAssert((url == "http://\(baseURL)"), "Should remove /wp-admin from the path.")

        url = WordPressAuthenticator.baseSiteURL(string: "\(baseURL)/wp-admin/")
        XCTAssert((url == "http://\(baseURL)"), "Should remove /wp-admin/ from the path.")

        url = WordPressAuthenticator.baseSiteURL(string: "\(baseURL)/")
        XCTAssert((url == "http://\(baseURL)"), "Should remove a trailing slash from the url.")

        // Check non-latin characters and puny code
        baseURL = "http://例.例"
        let punycode = "http://xn--fsq.xn--fsq"
        url = WordPressAuthenticator.baseSiteURL(string: baseURL)
        XCTAssert(url == baseURL)
        url = WordPressAuthenticator.baseSiteURL(string: punycode)
        XCTAssert(url == baseURL)
    }


    func testValidateFieldsPopulatedForSignin() {
        let loginFields = LoginFields()
        loginFields.meta.userIsDotCom = true

        XCTAssert(!WordPressAuthenticator.validateFieldsPopulatedForSignin(loginFields), "Empty fields should not validate.")

        loginFields.username = "user"
        XCTAssert(!WordPressAuthenticator.validateFieldsPopulatedForSignin(loginFields), "Should not validate with just a username")

        loginFields.password = "password"
        XCTAssert(WordPressAuthenticator.validateFieldsPopulatedForSignin(loginFields), "should validate wpcom with username and password.")

        loginFields.meta.userIsDotCom = false
        XCTAssert(!WordPressAuthenticator.validateFieldsPopulatedForSignin(loginFields), "should not validate self-hosted with just username and password.")

        loginFields.siteAddress = "example.com"
        XCTAssert(WordPressAuthenticator.validateFieldsPopulatedForSignin(loginFields), "should validate self-hosted with username, password, and site.")
    }

    func testExtractUsernameFrom() {
        let plainUsername = "auser"
        XCTAssertEqual(plainUsername, WordPressAuthenticator.extractUsername(from: plainUsername))

        let nonWPComSite = "asite.mycompany.com"
        XCTAssertEqual(nonWPComSite, WordPressAuthenticator.extractUsername(from: nonWPComSite))

        let wpComSite = "testuser.wordpress.com"
        XCTAssertEqual("testuser", WordPressAuthenticator.extractUsername(from: wpComSite))

        let wpComSiteSlash = "testuser.wordpress.com/"
        XCTAssertEqual("testuser", WordPressAuthenticator.extractUsername(from: wpComSiteSlash))

        let wpComSiteHttp = "http://testuser.wordpress.com/"
        XCTAssertEqual("testuser", WordPressAuthenticator.extractUsername(from: wpComSiteHttp))

        let nonWPComSiteFtp = "ftp://asite.mycompany.co/"
        XCTAssertEqual("asite.mycompany.co", WordPressAuthenticator.extractUsername(from: nonWPComSiteFtp))
    }

    func testIsWPComDomain() {
        let plainUsername = "auser"
        XCTAssertFalse(WordPressAuthenticator.isWPComDomain(plainUsername))

        let nonWPComSite = "asite.mycompany.com"
        XCTAssertFalse(WordPressAuthenticator.isWPComDomain(nonWPComSite))

        let wpComSite = "testuser.wordpress.com"
        XCTAssert(WordPressAuthenticator.isWPComDomain(wpComSite))
    }


    func testValidateSiteForSignin() {
        let loginFields = LoginFields()

        loginFields.siteAddress = ""
        XCTAssert(!WordPressAuthenticator.validateSiteForSignin(loginFields), "Empty site should not validate.")

        loginFields.siteAddress = "hostname"
        XCTAssert(WordPressAuthenticator.validateSiteForSignin(loginFields), "Just a host name should validate.")

        loginFields.siteAddress = "host name.com"
        XCTAssert(!WordPressAuthenticator.validateSiteForSignin(loginFields), "Hostname with spaces should not validate.")
    }


    func testEmailAddressTokenHandling() {
        let email = "example@email.com"
        let loginFields = LoginFields()
        loginFields.username = email
        WordPressAuthenticator.storeLoginInfoForTokenAuth(loginFields)

        var retrievedLoginFields = WordPressAuthenticator.retrieveLoginInfoForTokenAuth()
        let retrievedEmail = loginFields.username
        XCTAssert(email == retrievedEmail, "The email retrived should match the email that was saved.")

        WordPressAuthenticator.deleteLoginInfoForTokenAuth()
        retrievedLoginFields = WordPressAuthenticator.retrieveLoginInfoForTokenAuth()

        XCTAssert(retrievedLoginFields == nil, "Saved loginFields should be deleted after calling deleteLoginInfoForTokenAuth.")
    }

}
