import Foundation
import XCTest
import OHHTTPStubs
import OHHTTPStubsSwift

@testable import WordPress

class WordPressDotComAuthenticatorTests: CoreDataTestCase {

    override func tearDown() {
        super.tearDown()

        HTTPStubs.removeAllStubs()
    }

    func testAuthenticateSuccess() async {
        stubTokenExchange()

        let authenticator = WordPressDotComAuthenticator(authenticator: fakeAuthenticator(callback: ["code": "random"]))
        do {
            let _ = try await authenticator.authenticate(from: UIViewController(), prefersEphemeralWebBrowserSession: false)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testAuthenticateWithInvalidCallbackURL() async {
        let authenticator = WordPressDotComAuthenticator(authenticator: fakeAuthenticator(callback: ["empty": "yes"]))
        do {
            let _ = try await authenticator.authenticate(from: .init(), prefersEphemeralWebBrowserSession: false)
            XCTFail("Unexpected successful result")
        } catch .invalidCallbackURL {
            // Do nothing
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testAuthenticateWithAccessDenied() async {
        let authenticator = WordPressDotComAuthenticator(authenticator: fakeAuthenticator(callback: ["error": "access_denied"]))
        do {
            let _ = try await authenticator.authenticate(from: .init(), prefersEphemeralWebBrowserSession: false)
            XCTFail("Unexpected successful result")
        } catch .loginDenied {
            // Do nothing
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    @MainActor
    func testSignInSuccess() async throws {
        stubTokenExchange()
        stubGetAccountDetails()
        stubGetSites()

        // Given the app is not signed in with a WP.com account
        try XCTAssertNil(WPAccount.lookupDefaultWordPressComAccount(in: mainContext))

        // When signing in with a WP.com account
        let authenticator = WordPressDotComAuthenticator(coreDataStack: contextManager, authenticator: fakeAuthenticator(callback: ["code": "random"]))
        let accountID = await authenticator.signIn(from: UIViewController(), context: .default)
        XCTAssertNotNil(accountID)

        // The new WP.com acount should be set as the default account.
        let isDefaultAccount = try mainContext.existingObject(with: XCTUnwrap(accountID)).isDefaultWordPressComAccount
        XCTAssertTrue(isDefaultAccount)
    }

    @MainActor
    func testSignInAnotherAccount() async throws {
        stubTokenExchange()
        stubGetAccountDetails()
        stubGetSites()

        // Given the app is already signed in with a WP.com account.
        let account = AccountBuilder(mainContext).with(email: "test@example.com").with(username: "default_account").with(authToken: "token").build()
        try mainContext.save()
        AccountService(coreDataStack: contextManager).setDefaultWordPressComAccount(account)

        // When signing in with another WP.com account.
        let authenticator = WordPressDotComAuthenticator(coreDataStack: contextManager, authenticator: fakeAuthenticator(callback: ["code": "random"]))
        do {
            let _ = try await authenticator.attemptSignIn(from: UIViewController(), context: .jetpackSite(accountEmail: nil))
            XCTFail("Unexpected successful result")
        } catch .alreadySignedIn {
            // Do nothing
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSignInWithLoadingSitesError() async throws {
        stubTokenExchange()
        stubGetAccountDetails()
        stubGetSitesError()

        let authenticator = WordPressDotComAuthenticator(coreDataStack: contextManager, authenticator: fakeAuthenticator(callback: ["code": "random"]))
        do {
            let _ = try await authenticator.attemptSignIn(from: UIViewController(), context: .default)
            XCTFail("Unexpected successful result")
        } catch .loadingSites {
            // Do nothing
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

private extension WordPressDotComAuthenticatorTests {
    func fakeAuthenticator(callback: [String: String]) -> (URL) throws(WordPressDotComAuthenticator.AuthenticationError) -> URL {
        var url = URL(string: "x-wordpress-app://oauth2-callback")!
        url.append(queryItems: callback.map { URLQueryItem(name: $0, value: $1) })

        return fakeAuthenticator(callback: url)
    }

    func fakeAuthenticator(callback: URL) -> (URL) throws(WordPressDotComAuthenticator.AuthenticationError) -> URL {
        { _ in callback }
    }

    func stubTokenExchange() {
        stub(condition: isPath("/oauth2/token")) { _ in
            HTTPStubsResponse(data: #"{"access_token": "token"}"#.data(using: .utf8)!, statusCode: 200, headers: ["Content-Type": "application/json"])
        }
    }

    func stubGetAccountDetails() {
        stub(condition: isPath("/rest/v1.1/me")) { _ in
            let json = #"""
                {
                    "ID": 55511,
                    "display_name": "Jim Tester",
                    "username": "jimthetester",
                    "email": "jim@wptestaccounts.com",
                    "primary_blog": 55555551,
                    "primary_blog_url": "https:\/\/test1.wordpress.com",
                    "language": "en",
                    "locale_variant": "",
                    "token_site_id": false,
                    "token_scope": [
                                    "global"
                                    ],
                    "avatar_URL": "https:\/\/2.gravatar.com\/avatar\/5c11d333444b9c98765ed8ff0e574259?s=96&d=identicon",
                    "profile_URL": "http:\/\/en.gravatar.com\/jimthetester",
                    "verified": true,
                    "email_verified": true,
                    "date": "2009-10-12T21:00:06+00:00",
                    "site_count": 2,
                    "visible_site_count": 1,
                    "has_unseen_notes": false,
                    "phone_account": false,
                    "meta": {
                        "links": {
                            "self": "https:\/\/public-api.wordpress.com\/rest\/v1.1\/me",
                            "help": "https:\/\/public-api.wordpress.com\/rest\/v1.1\/me\/help",
                            "site": "https:\/\/public-api.wordpress.com\/rest\/v1.1\/sites\/55555551",
                            "flags": "https:\/\/public-api.wordpress.com\/rest\/v1.1\/me\/flags"
                        }
                    },
                    "is_valid_google_apps_country": true,
                    "logout_URL": "https:\/\/wordpress.com\/wp-login.php?action=logout&_wpnonce=1111ab2ff9&redirect_to=https%3A%2F%2Fwordpress.com%2F",
                    "is_new_reader": false
                }
                """#
            return HTTPStubsResponse(data: json.data(using: .utf8)!, statusCode: 200, headers: ["Content-Type": "application/json"])
        }
    }

    func stubGetSites() {
        stub(condition: isPath("/rest/v1.2/me/sites")) { _ in
            let json = #"{"sites":[]}"#
            return HTTPStubsResponse(data: json.data(using: .utf8)!, statusCode: 200, headers: ["Content-Type": "application/json"])
        }
    }

    func stubGetSitesError() {
        stub(condition: isPath("/rest/v1.2/me/sites")) { _ in
            let json = #"{"error_code":"internal_server_error"}"#
            return HTTPStubsResponse(data: json.data(using: .utf8)!, statusCode: 500, headers: ["Content-Type": "application/json"])
        }
    }
}
