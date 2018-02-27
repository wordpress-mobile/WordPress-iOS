import XCTest
@testable import WordPress


// MARK: - WordPressAuthenticator Unit Tests
//
class WordPressAuthenticatorTests: XCTestCase {

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
