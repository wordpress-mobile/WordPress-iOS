import CoreData
import OHHTTPStubs
import OHHTTPStubsSwift
import XCTest // Wanted to use Testing, but don't yet have CoreData utils there
@testable import WordPress
@testable import WordPressData

class WPAccountRestApiTests: CoreDataTestCase {

    override func tearDown() {
        HTTPStubs.removeAllStubs()
        UserSettings.defaultDotComUUID = nil
        super.tearDown()
    }

    func testAccessingAPIWithNoTokenPostsNotification() async {
        let account = WPAccount.fixture(context: mainContext, authToken: "")

        let notificationExpectation = XCTNSNotificationExpectation(
            name: .wpAccountRequiresShowingSigninForWPComFixingAuthToken,
            object: account,
            notificationCenter: .default
        )

        _ = account.wordPressComRestApi

        await fulfillment(of: [notificationExpectation])
    }

    func testAccessingAPIWithTokenDoesNotPostsNotification() async {
        let account = WPAccount.fixture(context: mainContext, authToken: "a-token")

        let notificationExpectation = XCTNSNotificationExpectation(
            name: .wpAccountRequiresShowingSigninForWPComFixingAuthToken,
            object: account,
            notificationCenter: .default
        )
        notificationExpectation.isInverted = true

        _ = account.wordPressComRestApi

        await fulfillment(of: [notificationExpectation], timeout: 0.1)
    }

    // MARK: - Invalid token

    func testRejectedTokenIsClearedAndSignInIsRequested() async throws {
        let account = try makeDefaultAccount(authToken: "a-token")

        let signInExpectation = XCTNSNotificationExpectation(
            name: .wpAccountRequiresShowingSigninForWPComFixingAuthToken,
            object: account,
            notificationCenter: .default
        )

        WPAccount.handleInvalidToken(
            accountID: TaggedManagedObjectID(account),
            rejectedToken: "a-token",
            context: mainContext
        )

        await fulfillment(of: [signInExpectation], timeout: 1)
        XCTAssertNil(account.authToken)
    }

    func testRejectedTokenDoesNotPostAccountChangedNotification() async throws {
        let account = try makeDefaultAccount(authToken: "a-token")

        // Observers treat this notification without an object as a logout.
        let accountChangedExpectation = XCTNSNotificationExpectation(
            name: .wpAccountDefaultWordPressComAccountChanged,
            object: nil,
            notificationCenter: .default
        )
        accountChangedExpectation.isInverted = true

        WPAccount.handleInvalidToken(
            accountID: TaggedManagedObjectID(account),
            rejectedToken: "a-token",
            context: mainContext
        )

        await fulfillment(of: [accountChangedExpectation], timeout: 0.5)
    }

    func testRejectionOfTokenThatIsNoLongerCurrentChangesNothing() async throws {
        let account = try makeDefaultAccount(authToken: "new-token")

        let signInExpectation = XCTNSNotificationExpectation(
            name: .wpAccountRequiresShowingSigninForWPComFixingAuthToken,
            object: nil,
            notificationCenter: .default
        )
        signInExpectation.isInverted = true

        WPAccount.handleInvalidToken(
            accountID: TaggedManagedObjectID(account),
            rejectedToken: "old-token",
            context: mainContext
        )

        await fulfillment(of: [signInExpectation], timeout: 0.5)
        XCTAssertEqual(account.authToken, "new-token")
    }

    func testLateRejectionDoesNotEraseTokenStoredThroughAnotherContext() async throws {
        let keychain = TestKeychain()
        let account = try makeDefaultAccount(authToken: "token-a")
        account.mockKeychain(keychain)
        account.authToken = "token-a"
        // Fill this instance's token and REST API caches with token A.
        XCTAssertEqual(account.authToken, "token-a")
        XCTAssertNotNil(account.wordPressComRestApi)

        let accountID = TaggedManagedObjectID(account)
        try await contextManager.performAndSave { context in
            let otherInstance = try context.existingObject(with: accountID)
            otherInstance.mockKeychain(keychain)
            otherInstance.authToken = "token-b"
        }

        let signInExpectation = XCTNSNotificationExpectation(
            name: .wpAccountRequiresShowingSigninForWPComFixingAuthToken,
            object: nil,
            notificationCenter: .default
        )
        signInExpectation.isInverted = true

        WPAccount.handleInvalidToken(accountID: accountID, rejectedToken: "token-a", context: mainContext)

        await fulfillment(of: [signInExpectation], timeout: 0.5)
        XCTAssertEqual(try keychain.getPassword(for: account.username, serviceName: "test-service"), "token-b")
        XCTAssertEqual(account.authToken, "token-b")

        // Later requests through this instance use token B.
        var authorization: String?
        stub(condition: isHost("public-api.wordpress.com")) { request in
            authorization = request.value(forHTTPHeaderField: "Authorization")
            return HTTPStubsResponse(jsonObject: [String: String](), statusCode: 200, headers: nil)
        }
        let api = try XCTUnwrap(account.wordPressComRestApi)
        _ = await api.perform(.get, URLString: "rest/v1.1/me")
        XCTAssertEqual(authorization, "Bearer token-b")
    }

    func testInvalidTokenResponseClearsTheTokenOfTheRequest() async throws {
        let account = try makeDefaultAccount(authToken: "a-token")
        stub(condition: isHost("public-api.wordpress.com")) { _ in
            HTTPStubsResponse(
                jsonObject: ["error": "invalid_token", "message": "The OAuth2 token is invalid."],
                statusCode: 400,
                headers: nil
            )
        }

        let signInExpectation = XCTNSNotificationExpectation(
            name: .wpAccountRequiresShowingSigninForWPComFixingAuthToken,
            object: account,
            notificationCenter: .default
        )

        let api = try XCTUnwrap(account.wordPressComRestApi)
        _ = await api.perform(.get, URLString: "rest/v1.1/me")

        await fulfillment(of: [signInExpectation], timeout: 1)
        XCTAssertNil(account.authToken)
    }

    private func makeDefaultAccount(authToken: String) throws -> WPAccount {
        let account = WPAccount.fixture(context: mainContext, authToken: authToken)
        try mainContext.save()
        UserSettings.defaultDotComUUID = account.uuid
        return account
    }
}
