import XCTest

@testable import WordPress
@testable import WordPressData

/// Covers how `dismissFullscreenSignIn` waits for `prepareAppUIAfterSignIn` before showing the app UI.
final class WindowManagerTests: XCTestCase {
    private var contextManager: ContextManager!
    private var window: UIWindow!
    private var sut: WindowManagerSpy!

    override func setUp() {
        super.setUp()
        contextManager = ContextManager.forTesting()
        contextManager.useAsSharedInstance(untilTestFinished: self)
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        sut = WindowManagerSpy(window: window)
        sut.showSignInUI()
    }

    override func tearDown() {
        UserSettings.defaultDotComUUID = nil
        sut = nil
        window = nil
        contextManager = nil
        super.tearDown()
    }

    func testDismissWaitsAndBlocksInputUntilTheAppUIIsReady() throws {
        // Given
        signIn()

        // When
        sut.dismissFullscreenSignIn()

        // Then the sign-in screen is covered while the wait runs
        let progressView = try XCTUnwrap(sut.signInProgressView)
        XCTAssertIdentical(progressView.superview, window)
        XCTAssertIdentical(window.subviews.last, progressView)
        XCTAssertEqual(sut.appUIShownCount, 0)

        // When the wait ends
        sut.finishPreparing()

        // Then
        XCTAssertNil(sut.signInProgressView)
        XCTAssertNil(progressView.superview)
        XCTAssertEqual(sut.appUIShownCount, 1)
        XCTAssertFalse(sut.isShowingFullscreenSignIn)
    }

    func testSecondDismissDuringTheWaitIsIgnored() {
        // Given
        signIn()
        sut.dismissFullscreenSignIn()

        // When
        sut.dismissFullscreenSignIn()

        // Then only one wait and one progress view
        XCTAssertEqual(sut.prepareCount, 1)
        XCTAssertEqual(window.subviews.filter(\.accessibilityViewIsModal).count, 1)

        // When the wait ends, the app UI is shown once and the progress view is gone
        sut.finishPreparing()
        XCTAssertEqual(sut.appUIShownCount, 1)
        XCTAssertFalse(window.subviews.contains { $0.accessibilityViewIsModal })
    }

    func testSignOutDuringTheWaitKeepsTheSignInUI() {
        // Given
        signIn()
        sut.dismissFullscreenSignIn()

        // When
        UserSettings.defaultDotComUUID = nil
        sut.finishPreparing()

        // Then
        XCTAssertEqual(sut.appUIShownCount, 0)
        XCTAssertNil(sut.signInProgressView)
        XCTAssertTrue(sut.isShowingFullscreenSignIn)
    }

    func testDismissWithoutAWaitShowsTheAppUIRightAway() {
        // Given a preparation that completes at once, as in other apps or self-hosted sign-ins
        signIn()
        sut.completesPreparationImmediately = true

        // When
        sut.dismissFullscreenSignIn()

        // Then no progress view ever appears
        XCTAssertEqual(sut.appUIShownCount, 1)
        XCTAssertNil(sut.signInProgressView)
        XCTAssertFalse(window.subviews.contains { $0.accessibilityViewIsModal })
    }

    // MARK: - Helpers

    private func signIn() {
        let account = AccountBuilder(contextManager.mainContext).with(username: "WindowManagerTests").build()
        UserSettings.defaultDotComUUID = account.uuid
    }
}

private final class WindowManagerSpy: WindowManager {
    var completesPreparationImmediately = false
    private(set) var prepareCount = 0
    private(set) var appUIShownCount = 0
    private var pendingPreparation: Completion?

    override func prepareAppUIAfterSignIn(completion: @escaping Completion) {
        prepareCount += 1
        if completesPreparationImmediately {
            completion()
        } else {
            pendingPreparation = completion
        }
    }

    func finishPreparing() {
        let completion = pendingPreparation
        pendingPreparation = nil
        completion?()
    }

    override func presentAppUI(for blog: Blog?, animated: Bool, completion: Completion?) {
        appUIShownCount += 1
    }

    override func presentSignInUI(completion: Completion?) {
        // The real implementation replaces the app's own window content.
    }
}
