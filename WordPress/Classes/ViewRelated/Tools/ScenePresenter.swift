import UIKit


/// Generic type that presents a scene from anywhere
/// keeps compatibility with Objective C (for now)
@objc
protocol ScenePresenter: class {
    /// Presents the scene on the given UIViewController
    @objc func present(on viewController: UIViewController)
}
