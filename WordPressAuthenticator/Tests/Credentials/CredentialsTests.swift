import XCTest
@testable import WordPressAuthenticator

class CredentialsTests: XCTestCase {

    let token = "arstdhneio123456789qwfpgjluy"
    let siteURL = "https://example.com"
    let username = "user123"
    let password = "arstdhneio"
    let xmlrpc = "https://example.com/xmlrpc.php"

    func testWordpressComCredentialsInit() {
        let wpcomCredentials = WordPressComCredentials(authToken: token,
                                                       isJetpackLogin: false,
                                                       multifactor: false,
                                                       siteURL: siteURL)

        XCTAssertEqual(wpcomCredentials.authToken, token)
        XCTAssertEqual(wpcomCredentials.isJetpackLogin, false)
        XCTAssertEqual(wpcomCredentials.multifactor, false)
        XCTAssertEqual(wpcomCredentials.siteURL, siteURL)
    }

    func testWordPressComCredentialsSiteURLReturnsDefaultValue() {
        let wpcomCredentials = WordPressComCredentials(authToken: token,
                                                       isJetpackLogin: false,
                                                       multifactor: false,
                                                       siteURL: "")

        let expected = "https://wordpress.com"

        XCTAssertEqual(wpcomCredentials.siteURL, expected)
    }

    func testWordPressComCredentialsEquatableReturnsCorrectValue() {
        let credential = WordPressComCredentials(authToken: token,
                                                 isJetpackLogin: false,
                                                 multifactor: false,
                                                 siteURL: siteURL)
        let match = WordPressComCredentials(authToken: token,
                                                 isJetpackLogin: false,
                                                 multifactor: false,
                                                 siteURL: siteURL)
        let differentJetpack = WordPressComCredentials(authToken: token,
                                                 isJetpackLogin: true,
                                                 multifactor: false,
                                                 siteURL: siteURL)
        let differentMultifactor = WordPressComCredentials(authToken: token,
                                                 isJetpackLogin: false,
                                                 multifactor: true,
                                                 siteURL: siteURL)
        let differentSiteURL = WordPressComCredentials(authToken: token,
                                                       isJetpackLogin: false,
                                                       multifactor: false,
                                                       siteURL: "")
        let differentAuthToken = WordPressComCredentials(authToken: "ARSTDBVCXZ(*&^%$",
                                                         isJetpackLogin: false,
                                                         multifactor: false,
                                                         siteURL: siteURL)

        XCTAssertEqual(credential, match)
        XCTAssertEqual(credential, differentJetpack)
        XCTAssertEqual(credential, differentMultifactor)
        XCTAssertNotEqual(credential, differentSiteURL)
        XCTAssertNotEqual(credential, differentAuthToken)
    }

    func testWordpressOrgCredentialsInit() {
        let wporgcredentials = WordPressOrgCredentials(username: username,
                                                  password: password,
                                                  xmlrpc: xmlrpc,
                                                  options: [:])

        XCTAssertEqual(wporgcredentials.username, username)
        XCTAssertEqual(wporgcredentials.password, password)
        XCTAssertEqual(wporgcredentials.xmlrpc, xmlrpc)
    }

    func testWordPressOrgCredentialsEquatable() {
        let lhs = WordPressOrgCredentials(username: username,
                                          password: password,
                                          xmlrpc: xmlrpc,
                                          options: [:])

        let rhs = WordPressOrgCredentials(username: username,
                                          password: password,
                                          xmlrpc: xmlrpc,
                                          options: [:])

        XCTAssertTrue(lhs == rhs)
    }

    func testWordPressOrgCredentialsNotEquatable() {
        let lhs = WordPressOrgCredentials(username: username,
                                          password: password,
                                          xmlrpc: xmlrpc,
                                          options: [:])

        let rhs = WordPressOrgCredentials(username: "username5678",
                                          password: password,
                                          xmlrpc: xmlrpc,
                                          options: [:])

        XCTAssertFalse(lhs == rhs)
    }

    func testAuthenticatorCredentialsInit() {
        let wporgCredentials = WordPressOrgCredentials(username: username,
                                                       password: password,
                                                       xmlrpc: xmlrpc,
                                                       options: [:])
        let wpcomCredentials = WordPressComCredentials(authToken: token,
                                                       isJetpackLogin: false,
                                                       multifactor: false,
                                                       siteURL: siteURL)
        let authenticatorCredentials = AuthenticatorCredentials(wpcom: wpcomCredentials,
                                                                wporg: wporgCredentials)

        XCTAssertEqual(authenticatorCredentials.wpcom?.authToken, token)
        XCTAssertEqual(authenticatorCredentials.wpcom?.isJetpackLogin, false)
        XCTAssertEqual(authenticatorCredentials.wpcom?.multifactor, false)
        XCTAssertEqual(authenticatorCredentials.wpcom?.siteURL, siteURL)
        XCTAssertEqual(authenticatorCredentials.wporg?.username, username)
        XCTAssertEqual(authenticatorCredentials.wporg?.password, password)
        XCTAssertEqual(authenticatorCredentials.wporg?.xmlrpc, xmlrpc)
    }

}
