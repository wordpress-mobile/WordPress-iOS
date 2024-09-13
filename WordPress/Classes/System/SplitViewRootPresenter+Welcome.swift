import Foundation
import UIKit
import SwiftUI

class WelcomeSplitViewContent: SplitViewDisplayable {
    var selection: SidebarSelection { .welcome }

    let supplimentary: UINavigationController
    var secondary: UINavigationController?

    init(addSite: @escaping (AddSiteMenuViewModel.Selection) -> Void) {
        supplimentary = UINavigationController(rootViewController: UnifiedPrologueViewController())

        let addSiteViewModel = AddSiteMenuViewModel(context: .shared, onSelection: addSite)
        let noSitesViewModel = NoSitesViewModel(appUIType: JetpackFeaturesRemovalCoordinator.currentAppUIType, account: nil)
        let noSiteView = NoSitesView(addSiteViewModel: addSiteViewModel, viewModel: noSitesViewModel)
        let noSitesVC = UIHostingController(rootView: noSiteView)
        noSitesVC.view.backgroundColor = .systemBackground
        secondary = UINavigationController(rootViewController: noSitesVC)

        supplimentary.isNavigationBarHidden = true
    }

    func displayed(in splitVC: UISplitViewController) {
        // Do nothing
    }
}
