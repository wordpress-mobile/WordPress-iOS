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
    private let blog: Blog
    private let service: BlogJetpackSettingsService
    private let blogService: BlogService

    private var noResultsViewController: NoResultsViewController?


    /// Creates a Jetpack Module Wall that gives the user the option to enable a module
    /// - Parameters:
    ///   - viewController: a UIViewController that conforms to JetpackModuleHelperDelegate
    ///   - moduleName: a `String` representing the name of the module
    ///   - blog: a `Blog`
    @objc init(viewController: JetpackModuleHelperViewController, moduleName: String, blog: Blog) {
        self.viewController = viewController
        self.moduleName = moduleName
        self.blog = blog
        self.service = BlogJetpackSettingsService(managedObjectContext: blog.settings?.managedObjectContext ?? ContextManager.sharedInstance().mainContext)
        self.blogService = BlogService(managedObjectContext: blog.settings?.managedObjectContext ?? ContextManager.sharedInstance().mainContext)
    }


    /// Show the No Results View Controller
    /// - Parameters:
    ///   - title: A `String` to display on the title of the NVC
    ///   - subtitle: A `String` to display as the subtitle of the NVC
    @objc func show(title: String, subtitle: String) {
        noResultsViewController = NoResultsViewController.controller()
        noResultsViewController?.configure(
            title: title,
            attributedTitle: nil,
            noConnectionTitle: nil,
            buttonTitle: NSLocalizedString("Enable", comment: "Title of button to enable publicize."),
            subtitle: subtitle,
            noConnectionSubtitle: nil,
            attributedSubtitle: nil,
            attributedSubtitleConfiguration: nil,
            image: "mysites-nosites",
            subtitleImage: nil,
            accessoryView: nil
        )

        if let noResultsViewController = noResultsViewController, let viewController = viewController {
            noResultsViewController.delegate = self

            viewController.addChild(noResultsViewController)
            viewController.view.addSubview(withFadeAnimation: noResultsViewController.view)
            noResultsViewController.didMove(toParent: viewController)
            noResultsViewController.view.frame = viewController.view.bounds
        }
    }
}

extension JetpackModuleHelper: NoResultsViewControllerDelegate {
    func actionButtonPressed() {
        service.updateJetpackModuleActiveSettingForBlog(blog,
                                                        module: moduleName,
                                                        active: true,
                                                        success: { [weak self] in
            guard let self = self else {
                return
            }

            self.blogService.syncBlogAndAllMetadata(self.blog) {
                self.noResultsViewController?.removeFromView()
                self.viewController?.jetpackModuleEnabled()
            }
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
