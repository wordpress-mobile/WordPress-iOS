import Foundation

class BlazeWebViewCoordinator {

    enum Source: String {
        case dashboardCard = "dashboard_card"
        case menuItem = "menu_item"
        case postsList = "posts_list"
    }


    /// Used to display the blaze web flow. Blazing a specific post
    /// and displaying a list of posts to choose from are both supported by this function.
    /// - Parameters:
    ///   - viewController: The view controller where the web view should be presented in.
    ///   - source: The source that triggers the display of the blaze web view.
    ///   - blog: `Blog` object representing the site that is being blazed
    ///   - postID: `NSNumber` representing the ID of the post being blazed. If `nil` is passed,
    ///    the blaze site flow is triggered. If a valid value is passed, the blaze post flow is triggered.
    static func presentBlazeFlow(in viewController: UIViewController,
                                 source: Source,
                                 blog: Blog,
                                 postID: NSNumber?) {
        let blazeViewController = BlazeWebViewController(source: source, blog: blog, postID: postID)
        let navigationViewController = UINavigationController(rootViewController: blazeViewController)
        navigationViewController.overrideUserInterfaceStyle = .light
        navigationViewController.modalPresentationStyle = .formSheet
        viewController.present(navigationViewController, animated: true)
    }
}
