import Foundation
import UIKit

class ReaderSplitViewContent: SplitViewDisplayable {
    let sidebar: ReaderSidebarViewController
    let sidebarNavigationController: UINavigationController
    var content: UINavigationController

    var selection: SidebarSelection {
        .reader
    }

    var supplimentary: UINavigationController {
        sidebarNavigationController
    }

    var secondary: UINavigationController? {
        get { content }
        set {
            if let newValue {
                content = newValue
            }
        }
    }

    init() {
        content = UINavigationController()
        let viewModel = ReaderSidebarViewModel()
        sidebar = ReaderSidebarViewController(viewModel: viewModel)
        sidebar.navigationItem.largeTitleDisplayMode = .automatic
        sidebarNavigationController = UINavigationController(rootViewController: sidebar)
        sidebarNavigationController.navigationBar.prefersLargeTitles = true
    }

    func displayed(in splitVC: UISplitViewController) {
        if content.viewControllers.isEmpty {
            sidebar.showInitialSelection()
        }
    }
}
