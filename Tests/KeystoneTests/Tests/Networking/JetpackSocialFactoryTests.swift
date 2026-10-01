import JetpackSocial
import OHHTTPStubs
import OHHTTPStubsSwift
import os
import Testing
import UIKit
import XCTest

@testable import WordPress
@testable import WordPressData

final class JetpackSocialFactoryTests: CoreDataTestCase {
    private var previousDefaultDotComUUID: String?

    override func setUp() {
        super.setUp()
        previousDefaultDotComUUID = UserSettings.defaultDotComUUID
        UserSettings.defaultDotComUUID = nil
        contextManager.useAsSharedInstance(untilTestFinished: self)
        HTTPStubs.removeAllStubs()
    }

    override func tearDown() {
        HTTPStubs.removeAllStubs()
        UserSettings.defaultDotComUUID = previousDefaultDotComUUID
        super.tearDown()
    }

    @MainActor
    func testSelfHostedJetpackConnectedBlogUsesSiteAccountTokenInsteadOfDefaultAccountToken() async throws {
        let defaultAccount = makeAccount(username: "default-user", token: "default-token")
        UserSettings.defaultDotComUUID = defaultAccount.uuid
        let siteAccount = makeAccount(username: "site-user", token: "site-token")
        let blog = makeSelfHostedBlog(dotComID: 123)
        blog.account = siteAccount

        let service = try XCTUnwrap(JetpackSocialFactory().connectionsService(for: blog))
        let header = try await authorizationHeader(fromLoadingConnectionsWith: service)

        XCTAssertEqual(header, "Bearer site-token")
    }

    @MainActor
    func testSelfHostedBlogWithoutWPComAccountReturnsNil() {
        let blog = makeSelfHostedBlog(dotComID: 123)

        XCTAssertNil(JetpackSocialFactory().connectionsService(for: blog))
    }

    @MainActor
    func testBlogWithoutDotComIDReturnsNil() {
        let blog = BlogBuilder(mainContext, dotComID: nil)
            .withAnAccount(username: "site-user", authToken: "site-token")
            .build()

        XCTAssertNil(JetpackSocialFactory().connectionsService(for: blog))
    }

    @MainActor
    func testDotComBlogUsesSiteAccountToken() async throws {
        let account = makeAccount(username: "site-user", token: "site-token")
        let blog = BlogBuilder(mainContext, dotComID: 123)
            .with(url: "https://example.wordpress.com")
            .isHostedAtWPcom()
            .build()
        blog.account = account

        let service = try XCTUnwrap(JetpackSocialFactory().connectionsService(for: blog))
        let header = try await authorizationHeader(fromLoadingConnectionsWith: service)

        XCTAssertEqual(header, "Bearer site-token")
    }

    @MainActor
    func testCachedServicesDoNotCrossWPComAccountBoundaries() throws {
        let firstAccount = makeAccount(username: "first-user", token: "first-token")
        let secondAccount = makeAccount(username: "second-user", token: "second-token")
        let blog = makeSelfHostedBlog(dotComID: 123)
        let factory = JetpackSocialFactory()

        blog.account = firstAccount
        let firstService = try XCTUnwrap(factory.connectionsService(for: blog))

        blog.account = secondAccount
        let secondService = try XCTUnwrap(factory.connectionsService(for: blog))

        XCTAssertFalse(firstService === secondService)
    }

    private func makeAccount(username: String, token: String) -> WPAccount {
        AccountBuilder(mainContext)
            .with(username: username)
            .with(authToken: token)
            .build()
    }

    private func makeSelfHostedBlog(dotComID: Int) -> Blog {
        BlogBuilder(mainContext, dotComID: NSNumber(value: dotComID))
            .with(url: "https://self-hosted.example")
            .with(username: "site-login")
            .with(restApiRootURL: "https://self-hosted.example/wp-json")
            .withApplicationPassword("app-password")
            .build()
    }

    @MainActor
    private func authorizationHeader(
        fromLoadingConnectionsWith service: SiteSocialConnectionsService
    ) async throws -> String? {
        let requestExpectation = expectation(description: "Publicize request made")
        let lock = NSLock()
        var authorizationHeader: String?

        stub(condition: isHost("public-api.wordpress.com")) { request in
            lock.lock()
            authorizationHeader = request.value(forHTTPHeaderField: "Authorization")
            lock.unlock()
            requestExpectation.fulfill()
            return HTTPStubsResponse(
                jsonObject: [],
                statusCode: 200,
                headers: ["Content-Type": "application/json"]
            )
        }

        _ = try? await service.loadConnections(force: true)
        await fulfillment(of: [requestExpectation], timeout: 5)

        lock.lock()
        defer { lock.unlock() }
        return authorizationHeader
    }
}

/// Coverage for the production sharing-destination builder. Uses an isolated
/// `ContextManager` and real model builders. Observers are scoped to the fixture
/// account and removed before the test returns; `JetpackSocialFactory.shared`
/// is cleared so cached services cannot leak into another test.
@Suite(.serialized)
@MainActor
struct SharingDestinationBuilderTests {
    @Test
    func publicizeCapableHostedBlogReturnsSocialControllerWithoutAuthRecovery() throws {
        let stack = openStack()
        defer { JetpackSocialFactory.shared.reset() }

        let blog = makeHostedPublicizeBlog(in: stack.mainContext)
        let account = try #require(blog.account)
        #expect(blog.supports(.publicize))

        let (destination, notifications) = destination(for: blog, observing: account)

        #expect(destination is ManageConnectionsHostingController)
        #expect(notifications == 0)
    }

    @Test(arguments: [nil, ""] as [String?])
    func clearingWarmedTokenRequestsAuthRecoveryAndRestoringTokenSucceeds(clearedToken: String?) throws {
        let stack = openStack()
        defer { JetpackSocialFactory.shared.reset() }

        let blog = makeHostedPublicizeBlog(in: stack.mainContext, token: "site-token")
        let account = try #require(blog.account)
        let otherAccount = makeUnrelatedAccount(in: stack.mainContext)
        // Warm the REST client, then clear the token so a stale cached API cannot
        // keep `isAccessibleThroughWPCom` true.
        #expect(account.wordPressComRestApi != nil)

        let observer = AuthRecoveryObserver(account: account)
        let otherObserver = AuthRecoveryObserver(account: otherAccount)
        defer {
            observer.stop()
            otherObserver.stop()
        }

        #expect(ManageConnectionsHostingController.make(for: blog) is ManageConnectionsHostingController)
        #expect(observer.notificationCount == 0)

        account.authToken = clearedToken
        // `make(for:)` rejects the token without posting auth recovery.
        #expect(ManageConnectionsHostingController.make(for: blog) == nil)
        #expect(observer.notificationCount == 0)

        let first = ManageConnectionsHostingController.sharingDestination(for: blog)
        let repeated = ManageConnectionsHostingController.sharingDestination(for: blog)
        #expect(first == nil)
        #expect(repeated == nil)
        #expect(observer.notificationCount == 2)
        #expect(otherObserver.notificationCount == 0)

        account.authToken = "site-token"
        let restored = ManageConnectionsHostingController.sharingDestination(for: blog)
        #expect(restored is ManageConnectionsHostingController)
        #expect(observer.notificationCount == 2)
        #expect(otherObserver.notificationCount == 0)
    }

    @Test(arguments: [nil, 0, -1] as [Int?])
    func invalidSiteIDFallsBackToSharingButtonsWithoutAuthRecovery(siteID: Int?) throws {
        let stack = openStack()
        defer { JetpackSocialFactory.shared.reset() }

        let blog = makeHostedPublicizeBlog(in: stack.mainContext, dotComID: siteID, token: "site-token")
        let account = try #require(blog.account)
        #expect(blog.supports(.publicize))

        let (destination, notifications) = destination(for: blog, observing: account)

        #expect(destination is SharingButtonsViewController)
        #expect(notifications == 0)
    }

    @Test(arguments: [nil, 0, -1] as [Int?])
    func invalidSiteIDWithMissingTokenRequestsAuthRecovery(siteID: Int?) throws {
        let stack = openStack()
        defer { JetpackSocialFactory.shared.reset() }

        let blog = makeHostedPublicizeBlog(in: stack.mainContext, dotComID: siteID, token: "site-token")
        let account = try #require(blog.account)
        #expect(blog.supports(.publicize))
        #expect(account.wordPressComRestApi != nil)
        account.authToken = nil

        let (destination, notifications) = destination(for: blog, observing: account)

        #expect(destination == nil)
        #expect(notifications == 1)
    }

    @Test
    func nonPublicizeBlogUsesSharingButtonsWithoutAuthRecovery() throws {
        let stack = openStack()
        defer { JetpackSocialFactory.shared.reset() }

        let blog = BlogBuilder(stack.mainContext, dotComID: 42)
            .with(url: "https://example.wordpress.com")
            .isHostedAtWPcom()
            .withAnAccount(username: "site-user", authToken: "site-token")
            .with(capabilities: [.publishPosts])
            .set(blogOption: "publicize_permanently_disabled", value: true)
            .build()
        let account = try #require(blog.account)
        #expect(!blog.supports(.publicize))

        let (destination, notifications) = destination(for: blog, observing: account)

        #expect(destination is SharingButtonsViewController)
        #expect(notifications == 0)
    }

    @Test
    func nonPublicizeBlogWithMissingTokenDoesNotRequestAuthRecovery() throws {
        let stack = openStack()
        defer { JetpackSocialFactory.shared.reset() }

        let blog = BlogBuilder(stack.mainContext, dotComID: 42)
            .with(url: "https://example.wordpress.com")
            .isHostedAtWPcom()
            .withAnAccount(username: "site-user", authToken: "site-token")
            .with(capabilities: [.publishPosts])
            .set(blogOption: "publicize_permanently_disabled", value: true)
            .build()
        let account = try #require(blog.account)
        #expect(account.wordPressComRestApi != nil)
        account.authToken = nil
        #expect(!blog.supports(.publicize))

        let (destination, notifications) = destination(for: blog, observing: account)

        #expect(destination is SharingButtonsViewController)
        #expect(notifications == 0)
    }

    @Test
    func selfHostedBlogWithoutPublicizeModuleUsesSharingButtons() throws {
        let stack = openStack()
        defer { JetpackSocialFactory.shared.reset() }

        let blog = BlogBuilder(stack.mainContext, dotComID: 123)
            .with(url: "https://self-hosted.example")
            .isNotHostedAtWPcom()
            .withAnAccount(username: "site-user", authToken: "site-token")
            .with(capabilities: [.publishPosts])
            .with(modules: ["stats"])
            .build()
        let account = try #require(blog.account)
        #expect(!blog.supports(.publicize))

        let (destination, notifications) = destination(for: blog, observing: account)

        #expect(destination is SharingButtonsViewController)
        #expect(notifications == 0)
    }

    @Test
    func appPasswordOnlySelfHostedBlogUsesSharingButtonsWithoutAuthRecovery() throws {
        let stack = openStack()
        defer { JetpackSocialFactory.shared.reset() }

        let blog = BlogBuilder(stack.mainContext, dotComID: 123)
            .with(url: "https://self-hosted.example")
            .with(username: "site-login")
            .with(restApiRootURL: "https://self-hosted.example/wp-json")
            .with(capabilities: [.publishPosts])
            .with(modules: ["publicize"])
            .build()
        try blog.setApplicationToken("app-password", using: TestKeychain())
        #expect(blog.account == nil)
        #expect(!blog.supports(.publicize))

        let destination = ManageConnectionsHostingController.sharingDestination(for: blog)

        #expect(destination is SharingButtonsViewController)
    }

    @Test
    func connectedSelfHostedBlogUsesSocialController() throws {
        let stack = openStack()
        defer { JetpackSocialFactory.shared.reset() }

        let blog = BlogBuilder(stack.mainContext, dotComID: 123)
            .with(url: "https://self-hosted.example")
            .isNotHostedAtWPcom()
            .withAnAccount(username: "site-user", authToken: "site-token")
            .with(capabilities: [.publishPosts])
            .with(modules: ["publicize"])
            .build()
        let account = try #require(blog.account)
        #expect(blog.supports(.publicize))

        let (destination, notifications) = destination(for: blog, observing: account)

        #expect(destination is ManageConnectionsHostingController)
        #expect(notifications == 0)
    }

    @Test
    func blogWithoutAccountFallsBackToSharingButtons() {
        let stack = openStack()
        defer { JetpackSocialFactory.shared.reset() }

        let blog = BlogBuilder(stack.mainContext, dotComID: 77)
            .with(url: "https://example.wordpress.com")
            .isHostedAtWPcom()
            .with(capabilities: [.publishPosts])
            .build()
        #expect(blog.account == nil)
        #expect(!blog.supports(.publicize))

        let destination = ManageConnectionsHostingController.sharingDestination(for: blog)

        #expect(destination is SharingButtonsViewController)
    }

    private func openStack() -> ContextManager {
        JetpackSocialFactory.shared.reset()
        return ContextManager.forTesting()
    }

    private func makeHostedPublicizeBlog(
        in context: NSManagedObjectContext,
        dotComID: Int? = 42,
        token: String = "site-token"
    ) -> Blog {
        BlogBuilder(context, dotComID: dotComID.map { NSNumber(value: $0) })
            .with(url: "https://example.wordpress.com")
            .isHostedAtWPcom()
            .withAnAccount(username: "site-user", authToken: token)
            .with(capabilities: [.publishPosts])
            .build()
    }

    private func makeUnrelatedAccount(in context: NSManagedObjectContext) -> WPAccount {
        let account = WPAccount(context: context)
        account.mockKeychain()
        account.username = "other-user"
        account.authToken = "other-token"
        return account
    }

    private func destination(
        for blog: Blog,
        observing account: WPAccount
    ) -> (UIViewController?, Int) {
        let observer = AuthRecoveryObserver(account: account)
        defer { observer.stop() }
        let controller = ManageConnectionsHostingController.sharingDestination(for: blog)
        return (controller, observer.notificationCount)
    }
}

/// Counts `.wpAccountRequiresShowingSigninForWPComFixingAuthToken` posts for one account.
private final class AuthRecoveryObserver: @unchecked Sendable {
    private let notifications = OSAllocatedUnfairLock(initialState: 0)
    private var observer: NSObjectProtocol?

    init(account: WPAccount) {
        observer = NotificationCenter.default.addObserver(
            forName: .wpAccountRequiresShowingSigninForWPComFixingAuthToken,
            object: account,
            queue: nil
        ) { [notifications] _ in
            notifications.withLock { $0 += 1 }
        }
    }

    var notificationCount: Int {
        notifications.withLock { $0 }
    }

    func stop() {
        guard let observer else {
            return
        }
        NotificationCenter.default.removeObserver(observer)
        self.observer = nil
    }
}
