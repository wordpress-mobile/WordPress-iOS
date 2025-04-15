import XCTest
@testable import WordPress

class QRLoginCoordinatorTests: XCTestCase {
    func testDeepLinkHandlerDidHandle() {
        let url = URL(string: "https://apps.wordpress.com?#qr-code-login?token=hello&data=world")!
        let didHandle = QRLoginCoordinator.didHandle(url: url)

        XCTAssertTrue(didHandle)
    }

    // MARK: - Show Camera Scanning View
    func testShowCameraScanningViewIsPresented() {
        let navController = QRLoginNavigationControllerMock()
        let source = QRLoginPresentationControllerMock()
        let coordinator = QRLoginCoordinator(navigationController: navController, origin: .deepLink)

        coordinator.showCameraScanningView(from: source)

        XCTAssertEqual(source.mockPresentedViewController, navController)
        XCTAssertEqual(navController.mockedViewControllers.count, 1)
        XCTAssertNotNil(navController.mockedViewControllers.first! as? QRLoginScanningViewController)
    }

    func testShowCameraScanningViewIsPushed() {
        let navController = QRLoginNavigationControllerMock(rootViewController: UIViewController())
        let coordinator = QRLoginCoordinator(navigationController: navController, origin: .deepLink)

        coordinator.showCameraScanningView()

        XCTAssertNotNil(navController.mockPushedViewController as? QRLoginScanningViewController)
    }

    // MARK: - Verify Auth View
    func testVerifyAuthViewIsPushed() {
        let navController = QRLoginNavigationControllerMock(rootViewController: UIViewController())
        let coordinator = QRLoginCoordinator(navigationController: navController, origin: .deepLink)
        let token = QRLoginToken(token: "", data: "")

        coordinator.showVerifyAuthorization(token: token)
        XCTAssertNotNil(navController.mockPushedViewController as? QRLoginVerifyAuthorizationViewController)
    }

    func testShowVerifyAuthorizationViewIsPresented() {
        let navController = QRLoginNavigationControllerMock()
        let source = QRLoginPresentationControllerMock()
        let coordinator = QRLoginCoordinator(navigationController: navController, origin: .deepLink)
        let token = QRLoginToken(token: "", data: "")

        coordinator.showVerifyAuthorization(token: token, from: source)

        XCTAssertEqual(navController.mockedViewControllers.count, 1)
        XCTAssertNotNil(navController.mockedViewControllers.first! as? QRLoginVerifyAuthorizationViewController)
        XCTAssertEqual(source.mockPresentedViewController, navController)
    }
}

class QRLoginPresentationControllerMock: UIViewController {
    var mockPresentedViewController: UIViewController?

    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        mockPresentedViewController = viewControllerToPresent
    }
}

class QRLoginNavigationControllerMock: UINavigationController {
    var mockPushedViewController: UIViewController?

    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        mockPushedViewController = viewController
    }

    var mockedViewControllers: [UIViewController] = []

    override func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        mockedViewControllers = viewControllers
    }
}
