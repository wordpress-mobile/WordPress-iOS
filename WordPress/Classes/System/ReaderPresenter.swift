import Foundation
import UIKit

/// Manages top-level Reader navigation.
final class ReaderPresenter: SplitViewDisplayable {
    let sidebar: ReaderSidebarViewController
    let supplementary: UINavigationController
    var secondary: UINavigationController

    init() {
        secondary = UINavigationController()
        let viewModel = ReaderSidebarViewModel()
        sidebar = ReaderSidebarViewController(viewModel: viewModel)
        sidebar.navigationItem.largeTitleDisplayMode = .automatic
        supplementary = UINavigationController(rootViewController: sidebar)
        supplementary.navigationBar.prefersLargeTitles = true
    }

    // MARK: - SplitViewDisplayable

    func displayed(in splitVC: UISplitViewController) {
        if secondary.viewControllers.isEmpty {
            sidebar.showInitialSelection()
        }
    }

    // MARK: - Deep Links

    func navigate(to path: ReaderNavigationPath) {
        sidebar.navigate(to: path)
    }
}
