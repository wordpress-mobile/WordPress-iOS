import Foundation
import UIKit

/// Shows a NoResultsViewController on a given VC and handle enabling
/// a Jetpack module
@objc class JetpackModuleHelper: NSObject {
    private weak var viewController: UIViewController?
    private let moduleName: String
    private var noResultsViewController: NoResultsViewController?

    @objc init(viewController: UIViewController, moduleName: String) {
        self.viewController = viewController
        self.moduleName = moduleName
    }

    @objc func show() {
        noResultsViewController = NoResultsViewController.controller()
        noResultsViewController?.configure(
            title: NSLocalizedString("Enable Publicize", comment: "Text shown when the site doesn't have the Publicize module enabled."),
            attributedTitle: nil,
            noConnectionTitle: nil,
            buttonTitle: NSLocalizedString("Enable", comment: "Title of button to enable publicize."),
            subtitle: NSLocalizedString("In order to share your published posts to your social media you need to enable the Publicize module.", comment: "Title of button to enable publicize."),
            noConnectionSubtitle: nil,
            attributedSubtitle: nil,
            attributedSubtitleConfiguration: nil,
            image: "mysites-nosites",
            subtitleImage: nil,
            accessoryView: nil
        )

        viewController?.addChild(noResultsViewController!)
        viewController?.view.addSubview(withFadeAnimation: noResultsViewController!.view)
        noResultsViewController?.view.frame = self.viewController?.view.bounds ?? .zero
        noResultsViewController?.didMove(toParent: viewController!)
    }
}
