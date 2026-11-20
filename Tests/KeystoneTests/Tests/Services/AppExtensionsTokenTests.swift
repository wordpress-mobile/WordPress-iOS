import BuildSettingsKit
import CoreData
import Foundation
import ShareExtensionCore
import Testing
import WordPressShared
@testable import WordPress
@testable import WordPressData

/// The WordPress.com token that the share and notification extensions keep in the shared keychain.
///
/// Serialized: the tests use the real shared keychain items of the extensions.
@Suite(.serialized)
@MainActor
struct AppExtensionsTokenTests {
    private let contextManager = ContextManager.forTesting()

    init() {
        Self.clearExtensionTokens()
    }

    /// What a rejected token leaves behind, also after a relaunch: the account has no token, and the extensions
    /// still have the rejected one.
    @Test func setupClearsTheExtensionTokensOfAnAccountWithoutToken() async throws {
        defer { Self.clearExtensionTokens() }
        let account = try makeAccountWithDefaultBlog()
        account.authToken = nil
        ShareExtensionService().storeToken("rejected-token")
        NotificationSupportService().storeToken("rejected-token")

        AccountService(coreDataStack: contextManager).setupAppExtensions(defaultAccount: account)
        await waitUntil { ShareExtensionService().retrieveShareExtensionToken() == nil }

        #expect(ShareExtensionService().retrieveShareExtensionToken() == nil)
        #expect(Self.notificationExtensionToken() == nil)
        #expect(ShareExtensionService().retrieveShareExtensionDefaultSite()?.siteID == 4242)
    }

    @Test func setupStoresTheTokenOfAnAccountWithToken() async throws {
        defer { Self.clearExtensionTokens() }
        let account = try makeAccountWithDefaultBlog()
        account.authToken = "a-token"

        AccountService(coreDataStack: contextManager).setupAppExtensions(defaultAccount: account)
        await waitUntil { ShareExtensionService().retrieveShareExtensionToken() != nil }

        #expect(ShareExtensionService().retrieveShareExtensionToken() == "a-token")
        #expect(Self.notificationExtensionToken() == "a-token")
    }

    // MARK: - Helpers

    private func makeAccountWithDefaultBlog() throws -> WPAccount {
        let context = contextManager.mainContext
        let account = WPAccount.fixture(context: context, username: "user-\(UUID().uuidString)")
        let blog = BlogBuilder(context).with(dotComID: 4242).with(siteName: "Site").build()
        blog.account = account
        account.defaultBlog = blog
        try context.save()
        return account
    }

    private static func notificationExtensionToken() -> String? {
        let configuration = BuildSettings.current.notificationServiceExtensionConfiguration
        return try? AppKeychain()
            .getPassword(
                for: configuration.keychainTokenKey,
                serviceName: configuration.keychainServiceName
            )
    }

    private static func clearExtensionTokens() {
        ShareExtensionService().removeShareExtensionConfiguration()
        NotificationSupportService().deleteServiceExtensionToken()
    }

    /// `setupAppExtensions(defaultAccount:)` writes on the next main-queue turn.
    private func waitUntil(timeout: Duration = .seconds(2), _ condition: () -> Bool) async {
        let deadline = ContinuousClock.now + timeout
        while !condition(), ContinuousClock.now < deadline {
            try? await Task.sleep(for: .milliseconds(50))
        }
    }
}
