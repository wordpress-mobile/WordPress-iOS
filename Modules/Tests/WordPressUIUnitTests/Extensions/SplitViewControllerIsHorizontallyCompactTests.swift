import Testing
import UIKit

@testable import WordPressUI

@MainActor
struct SplitViewControllerIsHorizontallyCompactTests {

    @Test("Without a split view, a regular width is still the compact layout")
    func noSplitViewRegularWidth() {
        let viewController = UIViewController()
        viewController.traitOverrides.horizontalSizeClass = .regular

        #expect(viewController.traitCollection.horizontalSizeClass == .regular)
        #expect(viewController.splitViewControllerIsHorizontallyCompact)
    }

    @Test("Without a split view, a compact width is the compact layout")
    func noSplitViewCompactWidth() {
        let viewController = UIViewController()
        viewController.traitOverrides.horizontalSizeClass = .compact

        #expect(viewController.splitViewControllerIsHorizontallyCompact)
    }

    @Test("In an expanded split view, the layout isn't compact")
    func expandedSplitView() {
        let viewController = UIViewController()
        let splitViewController = makeSplitViewController(horizontalSizeClass: .regular)
        splitViewController.setViewController(viewController, for: .secondary)
        let window = show(splitViewController)
        defer { window.isHidden = true }

        #expect(!splitViewController.isCollapsed)
        #expect(viewController.splitViewController === splitViewController)
        #expect(!viewController.splitViewControllerIsHorizontallyCompact)
    }

    /// The app puts its tab bar in the compact column, as `SplitViewRootPresenter` does.
    @Test("In a collapsed split view, the layout is compact")
    func collapsedSplitView() {
        let viewController = UIViewController()
        let splitViewController = makeSplitViewController(horizontalSizeClass: .compact)
        splitViewController.setViewController(viewController, for: .compact)
        let window = show(splitViewController)
        defer { window.isHidden = true }

        #expect(splitViewController.isCollapsed)
        #expect(viewController.splitViewController === splitViewController)
        #expect(viewController.splitViewControllerIsHorizontallyCompact)
    }

    private func makeSplitViewController(
        horizontalSizeClass: UIUserInterfaceSizeClass
    ) -> UISplitViewController {
        let splitViewController = UISplitViewController(style: .doubleColumn)
        splitViewController.setViewController(UIViewController(), for: .primary)
        splitViewController.setViewController(UIViewController(), for: .secondary)
        splitViewController.traitOverrides.horizontalSizeClass = horizontalSizeClass
        return splitViewController
    }

    private func show(_ viewController: UIViewController) -> UIWindow {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1024, height: 768))
        window.rootViewController = viewController
        window.isHidden = false
        window.layoutIfNeeded()
        return window
    }
}
