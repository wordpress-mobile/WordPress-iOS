
import UIKit

/// Methods to access the Me Scene and sub levels
extension WPTabBarController {
    /// removes all but the primary viewControllers from the stack
    @objc func popMeTabToRoot() {
        getNavigationController()?.popToRootViewController(animated: false)
    }
    /// presents the Me scene. If the feature flag is disabled, replaces the previously defined `showMeTab`
    @objc func showMeScene(animated: Bool = true, completion: (() -> Void)? = nil) {
        meScenePresenter.present(on: self, animated: animated, completion: completion)
    }
    /// access to sub levels
    @objc func navigateToAccountSettings() {
        showMeScene(animated: false) {
            self.popMeTabToRoot()
            self.getMeViewController()?.navigateToAccountSettings()
        }
    }

    @objc func navigateToAppSettings() {
        showMeScene() {
            self.popMeTabToRoot()
            self.getMeViewController()?.navigateToAppSettings()
        }
    }

    @objc func navigateToSupport() {
        showMeScene() {
            self.popMeTabToRoot()
            self.getMeViewController()?.navigateToHelpAndSupport()
        }
    }

    /// obtains a reference to the navigation controller of the presented MeViewController
    private func getNavigationController() -> UINavigationController? {
        guard let splitController = meScenePresenter.presentedViewController as? WPSplitViewController,
            let navigationController = splitController.viewControllers.first as? UINavigationController else {
                return nil
        }
        return navigationController
    }

    /// obtains a reference to the presented MeViewController
    private func getMeViewController() -> MeViewController? {
        guard let navigationController = getNavigationController(),
            let meController = navigationController.viewControllers.first as? MeViewController else {
            return nil
        }
        return meController
    }
}
