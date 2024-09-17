import Foundation
import UIKit

class ReaderSplitViewContent: SplitViewDisplayable {
    let sidebar: ReaderSidebarViewController
    let supplementary: UINavigationController
    var secondary: UINavigationController

    private let viewModel = ReaderSidebarViewModel()

    init() {
        secondary = UINavigationController()
        sidebar = ReaderSidebarViewController(viewModel: viewModel)
        sidebar.navigationItem.largeTitleDisplayMode = .automatic
        supplementary = UINavigationController(rootViewController: sidebar)
        supplementary .navigationBar.prefersLargeTitles = true
    }

    func displayed(in splitVC: UISplitViewController) {
        if secondary.viewControllers.isEmpty {
            sidebar.showInitialSelection()
        }
    }

    func navigate(to path: ReaderNavigationPath) {
        switch path {
        case .discover:
            viewModel.selection = .main(.discover)
        case .likes:
            viewModel.selection = .main(.likes)
        case .search:
            viewModel.selection = .main(.search)
        }
    }
}
