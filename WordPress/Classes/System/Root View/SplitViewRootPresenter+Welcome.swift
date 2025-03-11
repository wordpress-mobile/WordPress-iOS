import Foundation
import UIKit
import SwiftUI
import WordPressData

class WelcomeSplitViewContent: SplitViewDisplayable {
    let supplementary: UINavigationController
    var secondary: UINavigationController

    init(addSite: @escaping (AddSiteMenuViewModel.Selection) -> Void) {
        supplementary = UINavigationController(rootViewController: UnifiedPrologueViewController())

        let addSiteViewModel = AddSiteMenuViewModel(context: ContextManager.shared, onSelection: addSite)
        let noSitesViewModel = NoSitesViewModel(appUIType: JetpackFeaturesRemovalCoordinator.currentAppUIType, account: nil)
        let noSiteView = NoSitesView(addSiteViewModel: addSiteViewModel, viewModel: noSitesViewModel)
        let noSitesVC = UIHostingController(rootView: noSiteView)
        noSitesVC.view.backgroundColor = .systemBackground
        secondary = UINavigationController(rootViewController: noSitesVC)
    }

    func displayed(in splitVC: UISplitViewController) {
        // Do nothing
    }
}
