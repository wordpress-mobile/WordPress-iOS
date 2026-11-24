import Testing
import UIKit
import WordPressUI

@MainActor
struct AdaptiveTabBarControllerTests {
    private let viewController = UIViewController()
    private let doneButton = UIBarButtonItem(systemItem: .done)
    private let controller = AdaptiveTabBarController<Tab>()

    init() {
        viewController.navigationItem.leftBarButtonItem = doneButton
    }

    @Test func regularWidthKeepsTheBackButtonAndExistingItems() {
        viewController.traitOverrides.horizontalSizeClass = .regular
        controller.configure(Tab.allCases, in: viewController) { _ in }

        let items = viewController.navigationItem.leftBarButtonItems ?? []
        #expect(items.count == 2)
        #expect(items.first === doneButton)
        #expect(items.last?.customView === controller.segmentedControl)
        #expect(viewController.navigationItem.leftItemsSupplementBackButton)
    }

    @Test func compactWidthLeavesTheNavigationItemAlone() {
        viewController.traitOverrides.horizontalSizeClass = .compact
        controller.configure(Tab.allCases, in: viewController) { _ in }

        #expect(viewController.navigationItem.leftBarButtonItems == [doneButton])
        #expect(!viewController.navigationItem.leftItemsSupplementBackButton)
    }

    @Test func changingToCompactWidthRemovesOnlyTheSegmentedControl() {
        viewController.traitOverrides.horizontalSizeClass = .regular
        controller.configure(Tab.allCases, in: viewController) { _ in }

        viewController.traitOverrides.horizontalSizeClass = .compact
        viewController.updateTraitsIfNeeded()

        #expect(viewController.navigationItem.leftBarButtonItems == [doneButton])
    }

    @Test func changingBackToRegularWidthAddsTheSegmentedControlOnce() {
        viewController.traitOverrides.horizontalSizeClass = .regular
        controller.configure(Tab.allCases, in: viewController) { _ in }

        viewController.traitOverrides.horizontalSizeClass = .compact
        viewController.updateTraitsIfNeeded()
        viewController.traitOverrides.horizontalSizeClass = .regular
        viewController.updateTraitsIfNeeded()

        let items = viewController.navigationItem.leftBarButtonItems ?? []
        #expect(items.count == 2)
        #expect(items.first === doneButton)
        #expect(items.last?.customView === controller.segmentedControl)
    }
}

private enum Tab: String, CaseIterable, AdaptiveTabBarItem {
    case traffic
    case insights

    var id: String { rawValue }
    var localizedTitle: String { rawValue }
}
