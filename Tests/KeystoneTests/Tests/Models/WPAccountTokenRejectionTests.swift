import CoreData
import Foundation
import OHHTTPStubs
import OHHTTPStubsSwift
import Testing
import WordPressKit
@testable import WordPress
@testable import WordPressData

/// Rejections of a WordPress.com token, including ones that arrive through the REST API of another context.
///
/// The accounts use the simulator keychain, as in the app: an instance that another context fetches reads the same
/// keychain. Serialized: the tests stub every WordPress.com request.
@Suite(.serialized)
@MainActor
struct WPAccountTokenRejectionTests {
    private let contextManager = ContextManager.forTesting()

    // MARK: - Contexts

    @Test func rejectionThroughAnotherContextClearsTheTokenCachedInThisContext() async throws {
        let account = try makeAccount(token: "rejected-token")
        defer { account.authToken = nil }
        // Caches the token in the main-context instance.
        #expect(account.authToken == "rejected-token")
        defer { HTTPStubs.removeAllStubs() }
        stubRejectingEveryRequest()

        let api = try #require(restApi(for: account, in: contextManager.newDerivedContext()))
        _ = await api.perform(.get, URLString: "rest/v1.1/me")
        await waitUntil { account.authToken == nil }

        #expect(account.authToken == nil)
        #expect(account.wordPressComRestApi == nil)
    }

    @Test func rejectionDoesNotBlockTheMainThreadWhileItsContextIsBusy() async throws {
        let account = try makeAccount(token: "rejected-token")
        defer { account.authToken = nil }
        defer { HTTPStubs.removeAllStubs() }
        stub(condition: isHost("public-api.wordpress.com")) { _ in
            HTTPStubsResponse(
                jsonObject: ["error": "invalid_token", "message": "The OAuth2 token is invalid."],
                statusCode: 400,
                headers: nil
            )
            .requestTime(0.3, responseTime: 0)
        }
        let context = contextManager.newDerivedContext()
        let api = try #require(restApi(for: account, in: context))
        Task.detached {
            _ = await api.perform(.get, URLString: "rest/v1.1/me")
        }

        let mainThreadWasBlocked = await withCheckedContinuation { continuation in
            context.perform {
                // The rejection arrives after 0.3 s, and its handler runs on the main thread while this block runs.
                Thread.sleep(forTimeInterval: 1)
                let semaphore = DispatchSemaphore(value: 0)
                DispatchQueue.main.async {
                    semaphore.signal()
                }
                continuation.resume(returning: semaphore.wait(timeout: .now() + 3) == .timedOut)
            }
        }

        #expect(!mainThreadWasBlocked)
        await waitUntil { account.authToken == nil }
        #expect(account.authToken == nil)
    }

    // MARK: - Helpers

    private func makeAccount(token: String) throws -> WPAccount {
        let account = WPAccount(context: contextManager.mainContext)
        account.uuid = UUID().uuidString
        account.userID = 1
        // Unique, because the token is stored under the username.
        account.username = "user-\(UUID().uuidString)"
        account.authToken = token
        try contextManager.mainContext.save()
        return account
    }

    /// The REST API of the account's instance in `context`, as `MediaRepository` and `ApplicationPasswordRepository`
    /// build it.
    private func restApi(for account: WPAccount, in context: NSManagedObjectContext) -> WordPressComRestApi? {
        let accountID = account.objectID
        return context.performAndWait {
            (try? context.existingObject(with: accountID) as? WPAccount)?.wordPressComRestApi
        }
    }

    private func stubRejectingEveryRequest() {
        stub(condition: isHost("public-api.wordpress.com")) { _ in
            HTTPStubsResponse(
                jsonObject: ["error": "invalid_token", "message": "The OAuth2 token is invalid."],
                statusCode: 400,
                headers: nil
            )
        }
    }

    private func waitUntil(timeout: Duration = .seconds(3), _ condition: () -> Bool) async {
        let deadline = ContinuousClock.now + timeout
        while !condition(), ContinuousClock.now < deadline {
            try? await Task.sleep(for: .milliseconds(50))
        }
    }
}
