import JetpackSocial
import OHHTTPStubs
import OHHTTPStubsSwift
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
