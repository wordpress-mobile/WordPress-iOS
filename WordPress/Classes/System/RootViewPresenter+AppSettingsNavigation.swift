import UIKit

extension RootViewPresenter {

    /// Navigates to "Me > App Settings > Privacy Settings"
    func navigateToPrivacySettings() {
        navigateToMeScene()
            .then(navigateToAppSettings())
            .then(navigateToPrivacySettings())
            .start(on: rootViewController, animated: true)
    }

    // MARK: - Navigators

    /// Creates a navigation action to navigate to the "Me" scene.
    ///
    /// The "Me" scene's navigation controller is popped to the root in case the "Me" scene was already presented.
    private func navigateToMeScene() -> ViewControllerNavigationAction {
        return .init { [weak self] context, completion in
            guard let self else {
                return
            }
            self.showMeScene(animated: context.animated) { meViewController in
                self.popMeTabToRoot()
                completion(meViewController)
            }
        }
    }

    /// Creates a navigation action to navigate to the "App Settings" from the "Me" scene.
    private func navigateToAppSettings() -> ViewControllerNavigationAction {
        return .init { context, completion in
            let me: MeViewController = try context.presentingViewController()
            CATransaction.perform {
                me.navigateToAppSettings()
            } completion: {
                completion(me.navigationController?.topViewController)
            }
        }
    }

    /// Creates a navigation action to navigate to the "Privacy Settings" from the "App Settings" scene.
    private func navigateToPrivacySettings() -> ViewControllerNavigationAction {
        return .init { context, completion in
            let appSettings: AppSettingsViewController = try context.presentingViewController()
            appSettings.navigateToPrivacySettings(animated: context.animated) { privacySettings in
                completion(privacySettings)
            }
        }
    }
}
