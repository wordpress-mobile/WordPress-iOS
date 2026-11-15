import Testing
import UIKit
@testable import WordPress

@MainActor
@Suite("FilterTabBar side safe area")
struct FilterTabBarSafeAreaTests {
    private let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 200))
    private let tabBar = FilterTabBar()

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

        tabBar.items = (1...8).map { TestItem(title: "Filter tab number \($0)") }
        window.layoutIfNeeded()
    }

    @Test("The selection indicator is clipped at the side safe area when its tab scrolls under it")
    func selectionIndicatorIsClippedAtSafeArea() throws {
        let scrollView = try #require(Mirror(reflecting: tabBar).descendant("scrollView") as? UIScrollView)
        let indicator = try #require(Mirror(reflecting: tabBar).descendant("selectionIndicator") as? UIView)
        let safeLeft = tabBar.safeAreaInsets.left
        try #require(safeLeft >= 80)
        try #require(scrollView.contentSize.width > scrollView.bounds.width)

        // The first tab is selected and fully visible.
        #expect(visibleFrame(of: indicator).width > 0)

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

private struct TestItem: FilterTabBarItem {
    let title: String
    var accessibilityIdentifier: String { title }
}
