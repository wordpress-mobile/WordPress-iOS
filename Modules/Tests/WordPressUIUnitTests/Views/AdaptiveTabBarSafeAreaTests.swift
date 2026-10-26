import Testing
import UIKit
@testable import WordPressUI

@MainActor
@Suite("AdaptiveTabBar side safe area")
struct AdaptiveTabBarSafeAreaTests {
    private let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 200))
    private let tabBar = AdaptiveTabBar()

    init() {
        let viewController = UIViewController()
        viewController.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 80, bottom: 0, right: 80)
        window.rootViewController = viewController
        window.isHidden = false

        tabBar.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.addSubview(tabBar)
        NSLayoutConstraint.activate([
            tabBar.topAnchor.constraint(equalTo: viewController.view.topAnchor),
            tabBar.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
            tabBar.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor)
        ])
        window.layoutIfNeeded()

        tabBar.items = (1...8).map { TestItem(id: "\($0)", localizedTitle: "Tab number \($0)") }
        window.layoutIfNeeded()
    }

    @Test("The selection indicator is clipped at the side safe area when its tab scrolls under it")
    func selectionIndicatorIsClippedAtSafeArea() throws {
        let scrollView = try #require(
            Mirror(reflecting: tabBar).descendant("$__lazy_storage_$_scrollView") as? UIScrollView
        )
        let indicator = try #require(
            Mirror(reflecting: tabBar).descendant("$__lazy_storage_$_selectionIndicator") as? UIView
        )
        let safeLeft = tabBar.safeAreaInsets.left
        try #require(safeLeft >= 80)
        try #require(scrollView.contentSize.width > scrollView.bounds.width)

        // The first tab is selected and fully visible, and its underline sits
        // at the bottom of the bar, under the tab.
        let firstTab = try #require(scrollView.subviews.compactMap { $0 as? UIStackView }.first?.arrangedSubviews.first)
        let initial = visibleFrame(of: indicator)
        #expect(initial.width > 0)
        #expect(abs(initial.maxY - tabBar.bounds.height) < 0.5)
        #expect(abs(initial.midX - firstTab.convert(firstTab.bounds, to: tabBar).midX) < 0.5)

        // Scroll the first tab partly out of view, past the leading safe area edge.
        scrollView.contentOffset = CGPoint(x: 50, y: 0)
        tabBar.layoutIfNeeded()

        let visible = visibleFrame(of: indicator)
        #expect(visible.width > 0)
        #expect(visible.minX >= safeLeft - 0.5)
    }

    /// The indicator's frame in the tab bar's coordinates, cut down by every
    /// ancestor that clips its subviews.
    private func visibleFrame(of view: UIView) -> CGRect {
        var rect = view.bounds
        var current = view
        while current !== tabBar, let superview = current.superview {
            rect = current.convert(rect, to: superview)
            if superview.clipsToBounds {
                rect = rect.intersection(superview.bounds)
            }
            current = superview
        }
        return rect.isNull ? .zero : rect
    }
}

private struct TestItem: AdaptiveTabBarItem {
    let id: String
    let localizedTitle: String
}
