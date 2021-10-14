import Foundation
import UIKit

public typealias JetpackModuleHelperViewController = JetpackModuleHelperDelegate & UIViewController

@objc public protocol JetpackModuleHelperDelegate: AnyObject {
    func jetpackModuleEnabled()
}

/// Shows a NoResultsViewController on a given VC and handle enabling
/// a Jetpack module
@objc class JetpackModuleHelper: NSObject {
    private weak var viewController: JetpackModuleHelperViewController?
    private let moduleName: String
    private var noResultsViewController: NoResultsViewController?
    private let blog: Blog
    private let service: BlogJetpackSettingsService

    @objc init(viewController: JetpackModuleHelperViewController, moduleName: String, blog: Blog) {
        self.viewController = viewController
        self.moduleName = moduleName
        self.blog = blog
        self.service = BlogJetpackSettingsService(managedObjectContext: blog.settings?.managedObjectContext ?? ContextManager.sharedInstance().mainContext)
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

        noResultsViewController?.delegate = self

        viewController?.addChild(noResultsViewController!)
        viewController?.view.addSubview(withFadeAnimation: noResultsViewController!.view)
        noResultsViewController?.didMove(toParent: viewController!)
        noResultsViewController?.view.frame = self.viewController?.view.bounds ?? .zero
    }
}

extension JetpackModuleHelper: NoResultsViewControllerDelegate {
    func actionButtonPressed() {
        service.updateJetpackModuleActiveSettingForBlog(blog,
                                                        module: moduleName,
                                                        active: true,
                                                        success: { [weak self] in
            self?.noResultsViewController?.removeFromView()
            self?.viewController?.jetpackModuleEnabled()
        },
                                                        failure: { [weak self] _ in
            self?.viewController?.displayNotice(title: Constants.error)
        })
    }
}

private extension JetpackModuleHelper {
    struct Constants {
        static let error = NSLocalizedString("The module couldn't be activated.", comment: "Error shown when a module can not be enabled")
    }
}
