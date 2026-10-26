import Testing
import UIKit
@testable import WordPress

@MainActor
struct NoSitesHostingControllerTests {
    @Test(arguments: [UIUserInterfaceSizeClass.compact, .regular])
    func withoutSplitViewShowsAccountButton(sizeClass: UIUserInterfaceSizeClass) {
        let viewController = makeViewController()
        let window = makeWindow(rootViewController: viewController)
        defer { window.isHidden = true }

        viewController.traitOverrides.horizontalSizeClass = sizeClass
        window.layoutIfNeeded()

        #expect(viewController.traitCollection.horizontalSizeClass == sizeClass)
        #expect(!viewController.rootView.isInExpandedSplitView)
    }

    @Test func followsSplitViewSizeClass() {
        let viewController = makeViewController()
        let splitViewController = UISplitViewController(style: .doubleColumn)
        splitViewController.setViewController(viewController, for: .secondary)
        splitViewController.traitOverrides.horizontalSizeClass = .regular
        let window = makeWindow(rootViewController: splitViewController)
        defer { window.isHidden = true }

        #expect(viewController.rootView.isInExpandedSplitView)

        splitViewController.traitOverrides.horizontalSizeClass = .compact
        window.layoutIfNeeded()

        #expect(!viewController.rootView.isInExpandedSplitView)
    }

    private func makeViewController() -> NoSitesHostingController {
        let addSiteViewModel = AddSiteMenuViewModel(context: .shared, onSelection: { _ in })
        let viewModel = NoSitesViewModel(appUIType: .simplified, account: nil)
        return NoSitesHostingController(rootView: NoSitesView(addSiteViewModel: addSiteViewModel, viewModel: viewModel))
    }

    /// The split view only sets up its columns, and `viewIsAppearing` is only called, once it's in a window.
    private func makeWindow(rootViewController: UIViewController) -> UIWindow {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1024, height: 768))
        window.rootViewController = rootViewController
        window.isHidden = false
        window.layoutIfNeeded()
        return window
    }
}
