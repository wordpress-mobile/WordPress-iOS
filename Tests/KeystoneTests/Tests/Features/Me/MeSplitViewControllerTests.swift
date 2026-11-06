import UIKit
import XCTest

@testable import WordPress
@testable import WordPressData

/// XCTest rather than Swift Testing: `useAsSharedInstance(untilTestFinished:)` needs an `XCTestCase`.
@MainActor
final class MeSplitViewControllerTests: XCTestCase {
    private var contextManager: ContextManager!
    private var window: UIWindow!

    override func setUp() {
        super.setUp()
        contextManager = ContextManager.forTesting()
        contextManager.useAsSharedInstance(untilTestFinished: self)
    }

    override func tearDown() {
        window?.isHidden = true
        window = nil
        contextManager = nil
        super.tearDown()
    }

    func testTabBarShowsTheMeListInTheSplitView() {
        let tabBarController = WPTabBarController(staticScreens: false)

        let meTab = tabBarController.meSplitViewController
        XCTAssertTrue(tabBarController.viewControllers?.contains(meTab) ?? false)
        XCTAssertIdentical(meTab.viewController(for: .primary), tabBarController.meNavigationController)
        XCTAssertIdentical(
            tabBarController.meNavigationController.viewControllers.first,
            tabBarController.meViewController
        )
    }

    func testRegularWidthShowsADefaultScreenBesideTheList() {
        let splitViewController = makeSplitViewController(horizontalSizeClass: .regular)

        XCTAssertFalse(splitViewController.isCollapsed)
        // Signed out, so the default is App Settings.
        XCTAssertTrue(detailRoot(of: splitViewController) is AppSettingsViewController)
    }

    func testCompactWidthShowsOnlyTheList() {
        let splitViewController = makeSplitViewController(horizontalSizeClass: .compact)

        XCTAssertTrue(splitViewController.isCollapsed)
        XCTAssertEqual(splitViewController.primaryNavigationController.viewControllers.count, 1)
    }

    func testCollapsingWithTheDefaultScreenShowsTheList() {
        let splitViewController = makeSplitViewController(horizontalSizeClass: .regular)

        setHorizontalSizeClass(.compact)

        XCTAssertTrue(splitViewController.isCollapsed)
        XCTAssertEqual(
            splitViewController.primaryNavigationController.viewControllers,
            [splitViewController.meViewController]
        )
    }

    func testAScreenOpenedInCompactWidthMovesToTheDetailColumnWhenExpanding() {
        let splitViewController = makeSplitViewController(horizontalSizeClass: .compact)
        let opened = UIViewController()
        splitViewController.showDetail(opened)
        layout()

        XCTAssertIdentical(visibleCollapsedScreen(of: splitViewController), opened)

        setHorizontalSizeClass(.regular)

        XCTAssertFalse(splitViewController.isCollapsed)
        XCTAssertEqual(
            splitViewController.primaryNavigationController.viewControllers,
            [splitViewController.meViewController]
        )
        XCTAssertIdentical(detailRoot(of: splitViewController), opened)
    }

    /// Screens must stay in the same navigation controller through a rotation. Moving them by hand
    /// crashed (a navigation controller inside a navigation controller) or left them with the bar
    /// insets of the previous navigation controller.
    func testAScreenPickedInTheDetailColumnSurvivesCollapsingAndExpanding() {
        let splitViewController = makeSplitViewController(horizontalSizeClass: .regular)
        let picked = UIViewController()
        let pushedFromPicked = UIViewController()
        splitViewController.showDetail(picked)
        let detailNavigationController = splitViewController.viewController(for: .secondary) as? UINavigationController
        detailNavigationController?.pushViewController(pushedFromPicked, animated: false)
        layout()

        setHorizontalSizeClass(.compact)

        XCTAssertTrue(splitViewController.isCollapsed)
        XCTAssertIdentical(visibleCollapsedScreen(of: splitViewController), pushedFromPicked)
        XCTAssertIdentical(pushedFromPicked.navigationController, detailNavigationController)

        setHorizontalSizeClass(.regular)

        XCTAssertFalse(splitViewController.isCollapsed)
        XCTAssertEqual(
            splitViewController.primaryNavigationController.viewControllers,
            [splitViewController.meViewController]
        )
        XCTAssertIdentical(splitViewController.viewController(for: .secondary), detailNavigationController)
        XCTAssertEqual(detailNavigationController?.viewControllers, [picked, pushedFromPicked])
    }

    // MARK: - Helpers

    private func makeSplitViewController(horizontalSizeClass: UIUserInterfaceSizeClass) -> MeSplitViewController {
        let splitViewController = MeSplitViewController(meViewController: MeViewController())
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 669, height: 951))
        // Keep the test window out of the host app's scene.
        window.windowScene = nil
        window.traitOverrides.horizontalSizeClass = horizontalSizeClass
        window.rootViewController = splitViewController
        window.isHidden = false
        layout()
        return splitViewController
    }

    private func setHorizontalSizeClass(_ sizeClass: UIUserInterfaceSizeClass) {
        window.traitOverrides.horizontalSizeClass = sizeClass
        layout()
    }

    private func layout() {
        window.updateTraitsIfNeeded()
        window.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        window.layoutIfNeeded()
    }

    /// The screen on top of the collapsed stack, looking inside the detail navigation controller
    /// that UIKit nests in it.
    private func visibleCollapsedScreen(of splitViewController: MeSplitViewController) -> UIViewController? {
        let top = splitViewController.primaryNavigationController.topViewController
        return (top as? UINavigationController)?.topViewController ?? top
    }

    private func detailRoot(of splitViewController: UISplitViewController) -> UIViewController? {
        let detail = splitViewController.viewController(for: .secondary)
        return (detail as? UINavigationController)?.viewControllers.first ?? detail
    }
}
