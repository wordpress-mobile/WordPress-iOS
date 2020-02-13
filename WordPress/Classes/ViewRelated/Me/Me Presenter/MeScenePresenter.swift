
import UIKit


/// Concrete implementation of ScenePresenter that presents the Me scene
/// in a UISplitViewController/UINavigationController view hierarchy
@objc
class MeScenePresenter: NSObject, ScenePresenter {
    // weak reference to the presented scene (no reference retained after dismissal)
    private weak var presentedViewController: UIViewController?

    /// Done button action
    @objc
    private func dismissHandler() {
        self.presentedViewController?.dismiss(animated: true)
    }

    /// ScenePresenter conformance
    func present(on viewController: UIViewController) {
        let presentedViewController = makePresentedViewController()
        self.presentedViewController = presentedViewController
        viewController.present(presentedViewController, animated: true)
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
        meController.navigationItem.rightBarButtonItem = makeDoneButton()
        return navigationController
    }

    func makePresentedViewController() -> WPSplitViewController {
        let splitViewController = WPSplitViewController()
        splitViewController.setInitialPrimaryViewController(makeNavigationController())
        return splitViewController
    }
}
