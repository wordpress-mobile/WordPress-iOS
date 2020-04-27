import UIKit


/// Generic type that presents a scene from anywhere
/// keeps compatibility with Objective C (for now)
@objc
protocol ScenePresenter {
    /// The presented UIViewController
    var presentedViewController: UIViewController? { get }
    /// Presents the scene on the given UIViewController
    @objc func present(on viewController: UIViewController, animated: Bool, completion: (() -> Void)?)
}

@objc
protocol ScenePresenterDelegate {
    @objc func didDismiss(presenter: ScenePresenter)
}
