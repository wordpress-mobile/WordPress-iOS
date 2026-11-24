import Foundation
import OHHTTPStubs
import OHHTTPStubsSwift
import os
import Testing
import WordPressAPI

@testable import WordPress

/// Serialized because every test stubs the same introspect URL.
@Suite("Self-hosted sign-in application password verification", .serialized)
@MainActor
struct SelfHostedSiteAuthenticatorVerificationTests {
    // A host no other suite stubs, so stubs from suites running in parallel cannot answer these requests.
    private static let host = "verify-application-password.example"
    private static let introspectPath = "/wp-json/wp/v2/users/me/application-passwords/introspect"

    private static let notLoggedInJSON =
        #"{"code":"rest_not_logged_in","message":"You are not currently logged in.","data":{"status":401}}"#

    private static let introspectJSON = """
        {"uuid":"0b0c1a5e-8c6f-4d4b-9f3e-2f1d7c5b8a90","app_id":"","name":"App",
         "created":"2026-09-30T01:00:00","last_used":null,"last_ip":null}
        """

    @Test("WordPress reporting no credentials on the same origin stops sign-in")
    func blockedHeaderStopsSignIn() async throws {
        let result = try await verify(
            siteUrl: "https://\(Self.host)",
            statusCode: 401,
            body: Self.notLoggedInJSON,
            contentType: "application/json"
        )

        #expect(result.requestCount == 1)
        let error = try #require(result.error)
        guard case .authorizationHeaderBlocked = error else {
            Issue.record("Unexpected error: \(error)")
            return
        }
    }

    @Test("WordPress reporting no credentials across origins lets sign-in continue")
    func crossOriginNotLoggedInContinues() async throws {
        let result = try await verify(
            siteUrl: "https://www.\(Self.host)",
            statusCode: 401,
            body: Self.notLoggedInJSON,
            contentType: "application/json"
        )

        #expect(result.requestCount == 1)
        #expect(result.error == nil)
    }

    @Test("A 401 that does not come from WordPress lets sign-in continue")
    func nonWordPress401Continues() async throws {
        let result = try await verify(
            siteUrl: "https://\(Self.host)",
            statusCode: 401,
            body: "<html><body>Unauthorized</body></html>",
            contentType: "text/html"
        )

        #expect(result.requestCount == 1)
        #expect(result.error == nil)
    }

    @Test("A 200 introspect response lets sign-in continue")
    func okResponseContinues() async throws {
        let result = try await verify(
            siteUrl: "https://\(Self.host)",
            statusCode: 200,
            body: Self.introspectJSON,
            contentType: "application/json"
        )

        #expect(result.requestCount == 1)
        #expect(result.error == nil)
    }

    /// Runs the check against a stubbed introspect response. `requestCount` shows that the
    /// response came from the stub, so a passing test cannot come from an unrelated network failure.
    private func verify(
        siteUrl: String,
        statusCode: Int32,
        body: String,
        contentType: String
    ) async throws -> (error: SelfHostedSiteAuthenticator.SignInError?, requestCount: Int) {
        let requestCount = OSAllocatedUnfairLock(initialState: 0)
        let introspectStub = stub(condition: isHost(Self.host) && isPath(Self.introspectPath)) { _ in
            requestCount.withLock { $0 += 1 }
            return HTTPStubsResponse(
                data: Data(body.utf8),
                statusCode: statusCode,
                headers: ["Content-Type": contentType]
            )
        }
        defer {
            HTTPStubs.removeStub(introspectStub)
        }

        let credentials = WpApiApplicationPasswordDetails(
            siteUrl: siteUrl,
            userLogin: "demo",
            password: "abcd efgh ijkl mnop qrst uvwx"
        )
        let apiRootUrl = try ParsedUrl.parse(input: "https://\(Self.host)/wp-json/")

        do {
            try await SelfHostedSiteAuthenticator().verifyIssuedApplicationPassword(credentials, apiRootUrl: apiRootUrl)
            return (nil, requestCount.withLock { $0 })
        } catch {
            return (error, requestCount.withLock { $0 })
        }
    }
}
