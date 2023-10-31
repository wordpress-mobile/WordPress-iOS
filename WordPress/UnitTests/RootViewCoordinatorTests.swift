import Foundation
import XCTest

@testable import WordPress

final class RootViewCoordinatorTests: XCTestCase {
    private var sut: RootViewCoordinator!
    private var windowManager: WindowManagerMock!

    override func setUp() {
        super.setUp()
        windowManager = WindowManagerMock(window: .init())
        sut = RootViewCoordinator(
            featureFlagStore: RemoteFeatureFlagStoreMock(),
            windowManager: windowManager,
            wordPressAuthenticator: WordPressAuthenticatorMock.self
        )
    }

    override func tearDown() {
        super.tearDown()
        windowManager = nil
        sut = nil
    }

    func testAppUIDeallocatedAfterLogout() {
        sut.showAppUI()
        let mainRootViewController = windowManager.presentedViewController
        XCTAssertNotNil(mainRootViewController)

        sut.showSignInUI()

        addTeardownBlock { [weak mainRootViewController] in
            XCTAssertNil(mainRootViewController)
        }
    }
}

private class WindowManagerMock: WindowManager {
    var presentedViewController: UIViewController?

    override func show(_ viewController: UIViewController, animated: Bool = true, completion: WindowManager.Completion? = nil) {
        self.presentedViewController = viewController
        completion?()
    }
}

private class WordPressAuthenticatorMock: WordPressAuthenticatorProtocol {
    static func loginUI() -> UIViewController? {
        return UIViewController(nibName: nil, bundle: nil)
    }

    static func track(_ event: WPAnalyticsStat) {}
}
