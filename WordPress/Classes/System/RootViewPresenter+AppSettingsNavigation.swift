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

    private func navigateToPrivacySettings() -> ViewControllerNavigationAction {
        return .init { context, completion in
            let appSettings: AppSettingsViewController = try context.presentingViewController()
            appSettings.navigateToPrivacySettings(animated: context.animated) { privacySettings in
                completion(privacySettings)
            }
        }
    }
}
