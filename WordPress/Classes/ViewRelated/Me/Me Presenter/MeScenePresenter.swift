
import UIKit


/// Concrete implementation of ScenePresenter that presents the Me scene
/// in a UISplitViewController/UINavigationController view hierarchy
@objc
class MeScenePresenter: NSObject, ScenePresenter {

    private var splitViewController: WPSplitViewController?

    func makeDoneButton() -> UIBarButtonItem {
        return UIBarButtonItem(title: NSLocalizedString("Done", comment: "Title of the Done button on the me page"),
                               style: .done,
                               target: self,
                               action: #selector(dismissHandler))
    }

    @objc
    private func dismissHandler() {
        self.splitViewController?.dismiss(animated: true)
        self.splitViewController = nil
    }

    private func makeMeViewController() -> MeViewController {
        return MeViewController()
    }

    private func makeNavigationController() -> UINavigationController {
        let meController = makeMeViewController()
        let navigationController = UINavigationController(rootViewController: meController)
        meController.navigationItem.rightBarButtonItem = makeDoneButton()
        return navigationController
    }

    private func makeSplitViewController() -> WPSplitViewController {
        let splitViewController = WPSplitViewController()
        splitViewController.setInitialPrimaryViewController(makeNavigationController())
        splitViewController.wpPrimaryColumnWidth = .narrow
        return splitViewController
    }

    func present(on viewController: UIViewController) {
        let splitViewController = makeSplitViewController()
        self.splitViewController = splitViewController
        viewController.present(splitViewController, animated: true)
    }
}

