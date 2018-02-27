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
