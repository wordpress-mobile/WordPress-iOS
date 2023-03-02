import Foundation

@objcMembers class BlazeOverlayCoordinator: NSObject {

    /// Used to display the blaze overlay.
    /// - Parameters:
    ///   - viewController: The view controller where the overlah should be presented in.
    ///   - source: The source that triggers the display of the blaze overlay.
    ///   - blog: `Blog` object representing the site to blaze.
    ///   - post: `AbstractPost` object representing the specific post to blaze. If `nil` is passed,
    ///    a general blaze overlay is displayed. If a valid value is passed, a blaze overlay with a post preview
    ///    is displayed.
    @objc(presentBlazeOverlayInViewController:source:blog:post:)
    static func presentBlazeOverlay(in viewController: UIViewController,
                                    source: BlazeSource,
                                    blog: Blog,
                                    post: AbstractPost? = nil) {
        let overlayViewController = BlazeOverlayViewController(source: source, blog: blog, post: post)
        let navigationController = UINavigationController(rootViewController: overlayViewController)
        navigationController.modalPresentationStyle = .formSheet
        viewController.present(navigationController, animated: true)
    }
}
