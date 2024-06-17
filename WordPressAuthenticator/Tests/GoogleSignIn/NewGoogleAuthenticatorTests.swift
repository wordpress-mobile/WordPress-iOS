@testable import WordPressAuthenticator
import XCTest

class NewGoogleAuthenticatorTests: XCTestCase {

    let fakeClientId = GoogleClientId(string: "a.b.c")!

    func testRequestingOAuthTokenThrowsIfCodeCannotBeExtractedFromURL() async throws {
        // Notice the use of a stub that returns a successful value.
        // This way, if we get an error, we can be more confident it's legit.
        let authenticator = NewGoogleAuthenticator(
            clientId: fakeClientId,
            scheme: "scheme",
            audience: "audience",
            oautTokenGetter: GoogleOAuthTokenGettingStub(response: .fixture())
        )
        let url = URL(string: "https://test.com?without=code")!

        do {
            _ = try await authenticator.requestOAuthToken(
                url: url,
                clientId: GoogleClientId(string: "a.b.c")!,
                audience: "audience",
                pkce: ProofKeyForCodeExchange()
            )
            XCTFail("Expected an error to be thrown")
        } catch {
            let error = try XCTUnwrap(error as? OAuthError)
            guard case .urlDidNotContainCodeParameter(let urlFromError) = error else {
                return XCTFail("Received unexpected error \(error)")
            }
            XCTAssertEqual(urlFromError, url)
        }
    }

    func testRequestingOAuthTokenRethrowsTheErrorItRecives() async throws {
        let authenticator = NewGoogleAuthenticator(
            clientId: fakeClientId,
            scheme: "scheme",
            audience: "audience",
            oautTokenGetter: GoogleOAuthTokenGettingStub(error: TestError(id: 1))
        )
        let url = URL(string: "https://test.com?code=a_code")!

        do {
            _ = try await authenticator.requestOAuthToken(
                url: url,
                clientId: GoogleClientId(string: "a.b.c")!,
                audience: "audience",
                pkce: ProofKeyForCodeExchange()
            )
            XCTFail("Expected an error to be thrown")
        } catch {
            let error = try XCTUnwrap(error as? TestError)
            XCTAssertEqual(error.id, 1)
        }
    }

    func testRequestingOAuthTokenThrowsIfIdTokenMissingFromResponse() async throws {
        let authenticator = NewGoogleAuthenticator(
            clientId: fakeClientId,
            scheme: "scheme",
            audience: "audience",
            oautTokenGetter: GoogleOAuthTokenGettingStub(response: .fixture(rawIDToken: .none))
        )
        let url = URL(string: "https://test.com?code=a_code")!

        do {
            _ = try await authenticator.requestOAuthToken(
                url: url,
                clientId: GoogleClientId(string: "a.b.c")!,
                audience: "audience",
                pkce: ProofKeyForCodeExchange()
            )
            XCTFail("Expected an error to be thrown")
        } catch {
            let error = try XCTUnwrap(error as? OAuthError)
            guard case .tokenResponseDidNotIncludeIdToken = error else {
                return XCTFail("Received unexpected error \(error)")
            }
        }
    }

    func testRequestingOAuthTokenReturnsTokenIfSuccessful() async throws {
        let authenticator = NewGoogleAuthenticator(
            clientId: fakeClientId,
            scheme: "scheme",
            audience: "audience",
            oautTokenGetter: GoogleOAuthTokenGettingStub(response: .fixture(rawIDToken: JSONWebToken.validJWTStringWithNameAndEmail))
        )
        let url = URL(string: "https://test.com?code=a_code")!

        do {
            let response = try await authenticator.requestOAuthToken(
                url: url,
                clientId: GoogleClientId(string: "a.b.c")!,
                audience: "audience",
                pkce: ProofKeyForCodeExchange()
            )
            XCTAssertEqual(response.email, JSONWebToken.emailFromValidJWTStringWithEmail)
        } catch {
            XCTFail("Expected value, got error '\(error)'")
        }
    }
}
