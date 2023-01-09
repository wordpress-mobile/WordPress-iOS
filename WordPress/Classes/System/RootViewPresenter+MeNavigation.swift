import UIKit

/// Methods to access the Me Scene and sub levels
extension RootViewPresenter {
    /// removes all but the primary viewControllers from the stack
    func popMeTabToRoot() {
        getNavigationController()?.popToRootViewController(animated: false)
    }
    /// presents the Me scene. If the feature flag is disabled, replaces the previously defined `showMeTab`
    func showMeScene(animated: Bool = true, completion: (() -> Void)? = nil) {
        let meScenePresenter = getMeScenePresenter()
        meScenePresenter.present(on: rootViewController, animated: animated, completion: completion)
    }
    /// access to sub levels
    func navigateToAccountSettings() {
        showMeScene(animated: false) {
            self.popMeTabToRoot()
            self.getMeViewController()?.navigateToAccountSettings()
        }
    }

    func navigateToAppSettings() {
        showMeScene() {
            self.popMeTabToRoot()
            self.getMeViewController()?.navigateToAppSettings()
        }
    }

    func navigateToSupport() {
        showMeScene() {
            self.popMeTabToRoot()
            self.getMeViewController()?.navigateToHelpAndSupport()
        }
    }

    /// obtains a reference to the navigation controller of the presented MeViewController
    private func getNavigationController() -> UINavigationController? {
        let meScenePresenter = getMeScenePresenter()
        if let navigationController = meScenePresenter.presentedViewController as? UINavigationController {
            return navigationController
        }

        if let splitController = meScenePresenter.presentedViewController as? WPSplitViewController,
           let navigationController = splitController.viewControllers.first as? UINavigationController {
                return navigationController
        }
        return nil
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
