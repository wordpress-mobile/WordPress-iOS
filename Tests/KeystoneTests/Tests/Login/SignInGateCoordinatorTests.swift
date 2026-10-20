import UIKit
import XCTest
@testable import WordPress
@testable import WordPressData

@MainActor
final class SignInGateCoordinatorTests: CoreDataTestCase {
    private var host: RecordingSignInGateHost!
    private var notificationCenter: NotificationCenter!
    private var signInContexts: [WordPressDotComAuthenticator.SignInContext] = []
    /// What the fake sign-in does to the account before it returns.
    private var signInEffect: (() -> Void)!
    /// Keeps the account instance, and with it its test keychain, alive. The context does not retain saved objects,
    /// and a fetch after the instance is released returns a new instance that reads the simulator keychain.
    private var defaultAccount: WPAccount?

    override func setUp() {
        super.setUp()
        host = RecordingSignInGateHost()
        notificationCenter = NotificationCenter()
        signInContexts = []
        signInEffect = {}
    }

    override func tearDown() {
        UserSettings.defaultDotComUUID = nil
        defaultAccount = nil
        super.tearDown()
    }

    // MARK: - Showing

    func testTokenlessDefaultAccountShowsGateWhenAppUIIsShown() throws {
        try makeDefaultAccount(authToken: nil)
        let coordinator = makeCoordinator()

        coordinator.evaluate(source: .launch)

        XCTAssertEqual(host.shownViewControllers.count, 1)
    }

    func testDefaultAccountWithTokenDoesNotShowGate() throws {
        try makeDefaultAccount(authToken: "token")
        let coordinator = makeCoordinator()

        coordinator.evaluate(source: .launch)

        XCTAssertTrue(host.shownViewControllers.isEmpty)
    }

    func testNoDefaultAccountNeverShowsGate() {
        let coordinator = makeCoordinator()

        coordinator.evaluate(source: .launch)
        notificationCenter.post(name: .wpAccountRequiresShowingSigninForWPComFixingAuthToken, object: nil)

        XCTAssertTrue(host.shownViewControllers.isEmpty)
    }

    func testSignInRequestShowsGate() throws {
        try makeDefaultAccount(authToken: nil)
        let coordinator = makeCoordinator()

        notificationCenter.post(name: .wpAccountRequiresShowingSigninForWPComFixingAuthToken, object: nil)

        XCTAssertEqual(host.shownViewControllers.count, 1)
        _ = coordinator
    }

    func testTriggerWhileGateIsShownDoesNotShowItAgain() throws {
        try makeDefaultAccount(authToken: nil)
        let coordinator = makeCoordinator()

        coordinator.evaluate(source: .launch)
        notificationCenter.post(name: .wpAccountRequiresShowingSigninForWPComFixingAuthToken, object: nil)
        coordinator.evaluate(source: .foreground)

        XCTAssertEqual(host.shownViewControllers.count, 1)
    }

    func testTriggerShowsGateAgainWhenItIsNoLongerVisible() throws {
        try makeDefaultAccount(authToken: nil)
        let coordinator = makeCoordinator()
        coordinator.evaluate(source: .launch)

        // For example, the gate's window lost its scene.
        host.isSignInGateVisible = false
        coordinator.evaluate(source: .foreground)

        XCTAssertEqual(host.shownViewControllers.count, 2)
    }

    // MARK: - Signing in

    func testSignInUsesTheAccountUserIDAndEmail() async throws {
        try makeDefaultAccount(authToken: nil, userID: 42, email: "user@example.com")
        let coordinator = makeCoordinator()
        coordinator.evaluate(source: .launch)

        await tapSignIn()

        guard case let .reauthentication(userID, emailHint) = try XCTUnwrap(signInContexts.first) else {
            return XCTFail("Unexpected sign-in context: \(signInContexts)")
        }
        XCTAssertEqual(userID, 42)
        XCTAssertEqual(emailHint, "user@example.com")
    }

    func testSignInThatLeavesTheAccountTokenlessKeepsGate() async throws {
        // The user cancelled, or a late rejection of the previous token cleared the new one while the sign-in
        // finished.
        try makeDefaultAccount(authToken: nil)
        let coordinator = makeCoordinator()
        coordinator.evaluate(source: .launch)

        await tapSignIn()

        XCTAssertEqual(signInContexts.count, 1)
        XCTAssertEqual(host.dismissCount, 0)
    }

    func testSignInThatStoresATokenDismissesGate() async throws {
        // Whether or not the sign-in then fails, for example to load the account's sites.
        let account = try makeDefaultAccount(authToken: nil)
        let coordinator = makeCoordinator()
        coordinator.evaluate(source: .launch)
        signInEffect = { account.authToken = "new-token" }

        await tapSignIn()

        XCTAssertEqual(host.dismissCount, 1)
    }

    func testNewTokenForDefaultAccountDismissesGate() throws {
        let account = try makeDefaultAccount(authToken: nil)
        let coordinator = makeCoordinator()
        coordinator.evaluate(source: .launch)

        account.authToken = "new-token"
        notificationCenter.post(name: .wpAccountDefaultWordPressComAccountChanged, object: account)

        XCTAssertEqual(host.dismissCount, 1)
    }

    // MARK: - Logging out

    func testLoggingOutDismissesGate() throws {
        try makeDefaultAccount(authToken: nil)
        let coordinator = makeCoordinator(logOut: { [notificationCenter] in
            UserSettings.defaultDotComUUID = nil
            notificationCenter?.post(name: .wpAccountDefaultWordPressComAccountChanged, object: nil)
        })
        coordinator.evaluate(source: .launch)

        try XCTUnwrap(host.shownViewControllers.last as? SignInGateViewController).viewModel.logOutTapped()

        XCTAssertEqual(host.dismissCount, 1)
    }

    func testLoggingOutWhileSigningInDoesNothing() async throws {
        try makeDefaultAccount(authToken: nil)
        var logOutCount = 0
        let coordinator = makeCoordinator(logOut: { logOutCount += 1 })
        coordinator.evaluate(source: .launch)
        let viewModel = try XCTUnwrap(host.shownViewControllers.last as? SignInGateViewController).viewModel

        let signIn = viewModel.signInTapped()
        viewModel.logOutTapped()
        await signIn?.value

        XCTAssertEqual(logOutCount, 0)
        XCTAssertEqual(host.dismissCount, 0)
    }

    func testAccountChangeWithAccountObjectKeepsGate() throws {
        let account = try makeDefaultAccount(authToken: nil)
        let coordinator = makeCoordinator()
        coordinator.evaluate(source: .launch)

        notificationCenter.post(name: .wpAccountDefaultWordPressComAccountChanged, object: account)

        XCTAssertEqual(host.dismissCount, 0)
    }

    // MARK: - Helpers

    private func makeCoordinator(logOut: @escaping @MainActor () -> Void = {}) -> SignInGateCoordinator {
        let coordinator = SignInGateCoordinator(
            host: host,
            coreDataStack: contextManager,
            signIn: { [weak self] _, context in
                self?.signInContexts.append(context)
                self?.signInEffect()
            },
            logOut: logOut
        )
        coordinator.startObserving(notificationCenter: notificationCenter)
        return coordinator
    }

    @discardableResult
    private func makeDefaultAccount(
        authToken: String?,
        userID: Int = 1,
        email: String = "user@example.com"
    ) throws -> WPAccount {
        let account = WPAccount.fixture(context: mainContext, userID: userID)
        account.authToken = authToken
        account.email = email
        try mainContext.save()
        UserSettings.defaultDotComUUID = account.uuid
        defaultAccount = account
        return account
    }

    private func tapSignIn() async {
        guard let gate = host.shownViewControllers.last as? SignInGateViewController else {
            return XCTFail("The gate is not shown")
        }
        await gate.viewModel.signInTapped()?.value
    }
}

private final class RecordingSignInGateHost: SignInGateHost {
    var isSignInGateVisible = false
    private(set) var shownViewControllers: [UIViewController] = []
    private(set) var dismissCount = 0

    func showSignInGate(_ viewController: UIViewController) {
        shownViewControllers.append(viewController)
        isSignInGateVisible = true
    }

    func dismissSignInGate() {
        dismissCount += 1
        isSignInGateVisible = false
    }
}
