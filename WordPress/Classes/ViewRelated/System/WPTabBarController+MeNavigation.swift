
import UIKit

/// Methods to access the Me Scene and sub levels
extension WPTabBarController {
    // will be removed when the new IA implementation completes
    /// removes all but the primary viewControllers from the stack
    @objc func popMeTabToRoot() {
        self.meNavigationController.popToRootViewController(animated: false)
    }
    /// presents the Me scene. If the feature flag is disabled, replaces the previously defined `showMeTab`
    @objc func showMeScene(animated: Bool = true, completion: (() -> Void)? = nil) {
        if FeatureFlag.meMove.enabled {
            scenePresenter.present(on: self, animated: animated, completion: completion)
        } else {
            showTab(for: Int(WPTabType.me.rawValue))
        }
    }
    /// access to sub levels
    @objc func navigateToAccountSettings() {
        if FeatureFlag.meMove.enabled {
            showMeScene(animated: false) {
                guard let meController = self.getMeViewController() else {
                    return
                }
                meController.navigateToAccountSettings()
            }
        } else {
            showMeScene()
            popMeTabToRoot()
            DispatchQueue.main.async {
                self.meViewController.navigateToAccountSettings()
            }
        }
    }

    @objc func navigateToAppSettings() {
        if FeatureFlag.meMove.enabled {
            showMeScene() {
                self.getMeViewController()?.navigateToAppSettings()
            }
        } else {
            showMeScene()
            popMeTabToRoot()
            DispatchQueue.main.async {
                self.meViewController.navigateToAppSettings()
            }
        }
    }

    @objc func navigateToSupport() {
        if FeatureFlag.meMove.enabled {
            showMeScene() {
                self.getMeViewController()?.navigateToHelpAndSupport()
            }
        } else {
            showMeScene()
            popMeTabToRoot()
            DispatchQueue.main.async {
                self.meViewController.navigateToHelpAndSupport()
            }
        }
    }

    /// obtains a reference to the presented MeViewController
    private func getMeViewController() -> MeViewController? {
        guard let splitController = scenePresenter.presentedViewController as? WPSplitViewController,
            let navigationController = splitController.viewControllers.first as? UINavigationController,
            let meController = navigationController.viewControllers.first as? MeViewController else {
            return nil
        }
        return meController
    }
}
