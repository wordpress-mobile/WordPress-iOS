
import UIKit


/// Concrete implementation of ScenePresenter that presents the Me scene
/// in a UISplitViewController/UINavigationController view hierarchy
@objc
class MeScenePresenter: NSObject, ScenePresenter {
    /// weak reference to the presented scene (no reference retained after it's dismissed)
    private(set) weak var presentedViewController: UIViewController?

    /// Done button action
    @objc
    private func dismissHandler() {
        self.presentedViewController?.dismiss(animated: true)
    }

    func present(on viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        // prevent presenting if the scene is already presented
        guard presentedViewController == nil else {
            return
        }
        let presentedViewController = makePresentedViewController()
        self.presentedViewController = presentedViewController
        viewController.present(presentedViewController, animated: animated, completion: completion)
    }
}


/// Presented UIViewController factory methods
private extension MeScenePresenter {

    func makeDoneButton() -> UIBarButtonItem {
        return UIBarButtonItem(title: NSLocalizedString("Done", comment: "Title of the Done button on the me page"),
                               style: .done,
                               target: self,
                               action: #selector(dismissHandler))
    }

    func makeMeViewController() -> MeViewController {
        return MeViewController()
    }

    func makeNavigationController() -> UINavigationController {
        let meController = makeMeViewController()
        let navigationController = UINavigationController(rootViewController: meController)
        meController.navigationItem.leftBarButtonItem = makeDoneButton()
        return navigationController
    }

    func makePresentedViewController() -> WPSplitViewController {
        let splitViewController = WPSplitViewController()
        splitViewController.setInitialPrimaryViewController(makeNavigationController())
        return splitViewController
    }
}
