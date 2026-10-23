import Testing
import UIKit

@testable import WordPressUI

@MainActor
@Suite("windowHorizontalSizeClass")
struct UIViewWindowSizeClassTests {
    /// A wide window whose content reports a compact size class, like a split view column on a
    /// full-screen iPad. Returns the window (kept alive by the caller) and the view inside the column.
    private func makeCompactColumnInWideWindow() -> (UIWindow, UIView) {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1024, height: 768))
        window.traitOverrides.horizontalSizeClass = .regular
        let column = UIView()
        column.traitOverrides.horizontalSizeClass = .compact
        let view = UIView()
        window.addSubview(column)
        column.addSubview(view)
        view.updateTraitsIfNeeded()
        return (window, view)
    }

    @Test("a view reports its window's size class, not its own")
    func viewInWindow() {
        let (window, view) = makeCompactColumnInWideWindow()

        #expect(view.traitCollection.horizontalSizeClass == .compact)
        #expect(view.windowHorizontalSizeClass == .regular)
        withExtendedLifetime(window) {}
    }

    @Test("a view outside a window reports its own size class")
    func viewWithoutWindow() {
        let view = UIView()
        view.traitOverrides.horizontalSizeClass = .regular
        view.updateTraitsIfNeeded()

        #expect(view.windowHorizontalSizeClass == .regular)
    }

    @Test("a view controller reports the size class of its view's window")
    func viewControllerInWindow() {
        let (window, view) = makeCompactColumnInWideWindow()
        let viewController = UIViewController()
        view.addSubview(viewController.view)
        viewController.view.updateTraitsIfNeeded()

        #expect(viewController.windowHorizontalSizeClass == .regular)
        withExtendedLifetime(window) {}
    }

    @Test("a view controller whose view isn't loaded doesn't load it")
    func viewControllerWithoutView() {
        let viewController = UIViewController()

        _ = viewController.windowHorizontalSizeClass

        #expect(!viewController.isViewLoaded)
    }
}
