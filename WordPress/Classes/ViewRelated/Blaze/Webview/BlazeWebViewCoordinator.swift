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

@objcMembers class BlazeWebViewCoordinator: NSObject {

    /// Used to display the blaze web flow. Blazing a specific post
    /// and displaying a list of posts to choose from are both supported by this function.
    /// - Parameters:
    ///   - viewController: The view controller where the web view should be presented in.
    ///   - source: The source that triggers the display of the blaze web view.
    ///   - blog: `Blog` object representing the site that is being blazed
    ///   - postID: `NSNumber` representing the ID of the post being blazed. If `nil` is passed,
    ///    the blaze site flow is triggered. If a valid value is passed, the blaze post flow is triggered.
    @objc(presentBlazeFlowInViewController:source:blog:postID:)
    static func presentBlazeFlow(in viewController: UIViewController,
                                 source: BlazeSource,
                                 blog: Blog,
                                 postID: NSNumber? = nil) {
        let blazeViewController = BlazeWebViewController(source: source, blog: blog, postID: postID)
        let navigationViewController = UINavigationController(rootViewController: blazeViewController)
        navigationViewController.overrideUserInterfaceStyle = .light
        navigationViewController.modalPresentationStyle = .formSheet
        viewController.present(navigationViewController, animated: true)
    }
}
