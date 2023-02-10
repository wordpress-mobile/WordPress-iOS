import Foundation

class BlazeWebViewCoordinator {

    enum Source: String {
        case dashboardCard = "dashboard_card"
        case menuItem = "menu_item"
        case postsList = "posts_list"
    }

    static func presentBlazeFlow(in viewController: UIViewController,
                                 source: Source,
                                 blog: Blog,
                                 postID: NSNumber?) {
        let blazeViewController = BlazeWebViewController(source: source, blog: blog, postID: postID)
        let navigationViewController = UINavigationController(rootViewController: blazeViewController)
        navigationViewController.modalPresentationStyle = .formSheet
        viewController.present(navigationViewController, animated: true)
    }
}
