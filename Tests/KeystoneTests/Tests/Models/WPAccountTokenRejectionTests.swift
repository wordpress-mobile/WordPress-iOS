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
/// keychain. Serialized: the tests set the default account.
@Suite(.serialized)
@MainActor
struct WPAccountTokenRejectionTests {
    private let contextManager = ContextManager.forTesting()

    // MARK: - Contexts

    @Test func rejectionThroughAnotherContextClearsTheTokenCachedInThisContext() async throws {
        let token = "rejected-\(UUID().uuidString)"
        let account = try makeAccount(token: token)
        defer { account.authToken = nil }
        // Caches the token in the main-context instance.
        #expect(account.authToken == token)
        let rejection = stubRejecting(token)
        defer { HTTPStubs.removeStub(rejection) }

        let api = try #require(restApi(for: account, in: contextManager.newDerivedContext()))
        _ = await api.perform(.get, URLString: "rest/v1.1/me")
        await waitUntil { account.authToken == nil }

        #expect(account.authToken == nil)
        #expect(account.wordPressComRestApi == nil)
    }

    @Test func rejectionDoesNotBlockTheMainThreadWhileItsContextIsBusy() async throws {
        let token = "rejected-\(UUID().uuidString)"
        let account = try makeAccount(token: token)
        defer { account.authToken = nil }
        let rejection = stubRejecting(token, after: 0.3)
        defer { HTTPStubs.removeStub(rejection) }
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

    // MARK: - Announcing the rejection

    // A rejection handled on the main thread posts its notifications before `handleInvalidToken` returns. These
    // tests don't suspend: other `@MainActor` suites could run during a suspension and post account notifications
    // to the default center, which these tests count.

    @Test func rejectionOfTheDefaultAccountTokenIsAnnounced() throws {
        let account = try makeAccount(token: "rejected-token")
        defer { account.authToken = nil }
        UserSettings.defaultDotComUUID = account.uuid
        defer { UserSettings.defaultDotComUUID = nil }
        let announcements = NotificationCounter(name: .wpAccountDefaultWordPressComAccountTokenRejected)

        WPAccount.handleInvalidToken(
            accountID: TaggedManagedObjectID(account),
            rejectedToken: "rejected-token",
            context: contextManager.mainContext
        )

        #expect(announcements.postCount == 1)
        #expect(account.authToken == nil)
    }

    @Test func rejectionOfAnotherAccountTokenIsNotAnnounced() throws {
        let account = try makeAccount(token: "rejected-token")
        defer { account.authToken = nil }
        UserSettings.defaultDotComUUID = UUID().uuidString
        defer { UserSettings.defaultDotComUUID = nil }
        let announcements = NotificationCounter(name: .wpAccountDefaultWordPressComAccountTokenRejected)

        WPAccount.handleInvalidToken(
            accountID: TaggedManagedObjectID(account),
            rejectedToken: "rejected-token",
            context: contextManager.mainContext
        )

        #expect(announcements.postCount == 0)
        #expect(account.authToken == nil)
    }

    @Test func rejectionOfATokenThatIsNoLongerCurrentIsNotAnnounced() throws {
        let account = try makeAccount(token: "new-token")
        defer { account.authToken = nil }
        UserSettings.defaultDotComUUID = account.uuid
        defer { UserSettings.defaultDotComUUID = nil }
        let announcements = NotificationCounter(name: .wpAccountDefaultWordPressComAccountTokenRejected)

        WPAccount.handleInvalidToken(
            accountID: TaggedManagedObjectID(account),
            rejectedToken: "old-token",
            context: contextManager.mainContext
        )

        #expect(announcements.postCount == 0)
        #expect(account.authToken == "new-token")
    }

    // MARK: - What a rejection leaves alone

    /// A rejection keeps the account, so it must not look like a logout: the account-changed notification without
    /// an account makes the app delegate show the full-screen sign-in and clear the Reader's data, and makes
    /// `WPTabBarController` rebuild the Reader tab.
    @Test func rejectionKeepsTheReaderTab() throws {
        let account = try makeAccount(token: "rejected-token")
        defer { account.authToken = nil }
        UserSettings.defaultDotComUUID = account.uuid
        defer { UserSettings.defaultDotComUUID = nil }
        let tabBar = WPTabBarController(staticReader: false, staticNotifications: false)
        defer { NotificationCenter.default.removeObserver(tabBar) }
        let readerNavigationController = tabBar.readerNavigationController
        let readerPresenter = tabBar.readerPresenter
        let accountChanges = NotificationCounter(name: .wpAccountDefaultWordPressComAccountChanged)

        WPAccount.handleInvalidToken(
            accountID: TaggedManagedObjectID(account),
            rejectedToken: "rejected-token",
            context: contextManager.mainContext
        )

        #expect(accountChanges.postCount == 0)
        #expect(tabBar.readerNavigationController === readerNavigationController)
        #expect(tabBar.readerPresenter === readerPresenter)
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

    /// Rejects only requests that carry `token`, so that suites running at the same time keep their responses.
    private func stubRejecting(_ token: String, after delay: TimeInterval = 0) -> HTTPStubsDescriptor {
        let carriesToken = hasHeaderNamed("Authorization", value: "Bearer \(token)")
        return stub(condition: isHost("public-api.wordpress.com") && carriesToken) { _ in
            HTTPStubsResponse(
                jsonObject: ["error": "invalid_token", "message": "The OAuth2 token is invalid."],
                statusCode: 400,
                headers: nil
            )
            .requestTime(delay, responseTime: 0)
        }
    }

    private func waitUntil(timeout: Duration = .seconds(3), _ condition: () -> Bool) async {
        let deadline = ContinuousClock.now + timeout
        while !condition(), ContinuousClock.now < deadline {
            try? await Task.sleep(for: .milliseconds(50))
        }
    }
}

/// Counts the posts of a notification on the default center while it is alive.
private final class NotificationCounter {
    private(set) var postCount = 0
    private var observer: NSObjectProtocol?

    init(name: Foundation.Notification.Name) {
        observer = NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil) { [weak self] _ in
            self?.postCount += 1
        }
    }

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
