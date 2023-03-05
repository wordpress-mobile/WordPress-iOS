import Foundation
import UIKit

@objc enum BlazeSource: Int {
    case dashboardCard
    case menuItem
    case postsList
    case pagesList

    var description: String {
        switch self {
        case .dashboardCard:
            return "dashboard_card"
        case .menuItem:
            return "menu_item"
        case .postsList:
            return "posts_list"
        case .pagesList:
            return "pages_list"
        }
    }
}

@objcMembers class BlazeFlowCoordinator: NSObject {

    /// Used to present the blaze flow. If the blaze overlay was never presented for the provided source,
    /// the overlay is shown. Otherwise, the blaze web view flow is presented.
    /// Blazing a specific post and displaying a list of posts to choose from are both supported by this function.
    /// - Parameters:
    ///   - viewController: The view controller where the web view or overlay should be presented in.
    ///   - source: The source that triggers the display of the blaze flow.
    ///   - blog: `Blog` object representing the site that is being blazed
    ///   - post: `AbstractPost` object representing the specific post to blaze. If `nil` is passed,
    ///    a general blaze overlay or web flow is displayed. If a valid value is passed, a blaze overlay with a post preview
    ///    or detailed web flow is displayed.
    @objc(presentBlazeInViewController:source:blog:postID:)
    static func presentBlaze(in viewController: UIViewController,
                             source: BlazeSource,
                             blog: Blog,
                             post: AbstractPost? = nil) {
        let shouldShowOverlay = true
        if shouldShowOverlay {
            presentBlazeOverlay(in: viewController, source: source, blog: blog, post: post)
        } else {
            presentBlazeWebFlow(in: viewController, source: source, blog: blog, postID: post?.postID)
        }
    }

    /// Used to display the blaze web flow without displaying an overlay. Blazing a specific post
    /// and displaying a list of posts to choose from are both supported by this function.
    /// - Parameters:
    ///   - viewController: The view controller where the web view should be presented in.
    ///   - source: The source that triggers the display of the blaze web view.
    ///   - blog: `Blog` object representing the site that is being blazed
    ///   - postID: `NSNumber` representing the ID of the post being blazed. If `nil` is passed,
    ///    the blaze site flow is triggered. If a valid value is passed, the blaze post flow is triggered.
    ///   - delegate: The delegate gets notified of changes happening in the web view. Default value is `nil`
    @objc(presentBlazeWebFlowInViewController:source:blog:postID:delegate:)
    static func presentBlazeWebFlow(in viewController: UIViewController,
                                 source: BlazeSource,
                                 blog: Blog,
                                 postID: NSNumber? = nil,
                                 delegate: BlazeWebViewControllerDelegate? = nil) {
        let blazeViewController = BlazeWebViewController(source: source, blog: blog, postID: postID, delegate: delegate)
        let navigationViewController = UINavigationController(rootViewController: blazeViewController)
        navigationViewController.overrideUserInterfaceStyle = .light
        navigationViewController.modalPresentationStyle = .formSheet
        viewController.present(navigationViewController, animated: true)
    }

    /// Used to display the blaze overlay.
    /// - Parameters:
    ///   - viewController: The view controller where the overlay should be presented in.
    ///   - source: The source that triggers the display of the blaze overlay.
    ///   - blog: `Blog` object representing the site to blaze.
    ///   - post: `AbstractPost` object representing the specific post to blaze. If `nil` is passed,
    ///    a general blaze overlay is displayed. If a valid value is passed, a blaze overlay with a post preview
    ///    is displayed.
    private static func presentBlazeOverlay(in viewController: UIViewController,
                                            source: BlazeSource,
                                            blog: Blog,
                                            post: AbstractPost? = nil) {
        let overlayViewController = BlazeOverlayViewController(source: source, blog: blog, post: post)
        let navigationController = UINavigationController(rootViewController: overlayViewController)
        navigationController.modalPresentationStyle = .formSheet
        viewController.present(navigationController, animated: true)
    }
}
