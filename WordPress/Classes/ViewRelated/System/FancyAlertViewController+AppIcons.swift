import UIKit

extension FancyAlertViewController {
    private struct Strings {
        static let titleText = NSLocalizedString("New Custom App Icons", comment: "Title of alert informing users about the Reader Save for Later feature.")
        static let bodyText = NSLocalizedString("We’ve updated our custom app icons with a fresh new look. There are 10 new styles to choose from, or you can simply keep your existing icon if you prefer.", comment: "Body text of alert informing users about the Reader Save for Later feature.")
        static let newIconButtonTitle = NSLocalizedString("Choose a new app icon", comment: "OK Button title shown in alert informing users about the Reader Save for Later feature.")
        static let dismissTitle = "Keep my current app icon"
    }

    static func presentCustomAppIconUpgradeAlertIfNecessary(from origin: UIViewController & UIViewControllerTransitioningDelegate) {
        guard AppConfiguration.allowsCustomAppIcons,
              AppIcon.isUsingCustomIcon,
              origin.presentedViewController == nil,
              UserDefaults.standard.hasShownCustomAppIconUpgradeAlert == false else {
            return
        }

        UserDefaults.standard.hasShownCustomAppIconUpgradeAlert = true

        let controller = FancyAlertViewController.makeCustomAppIconUpgradeAlertController(with: origin)
        controller.modalPresentationStyle = .custom
        controller.transitioningDelegate = origin

        origin.present(controller, animated: true)
    }

    static func makeCustomAppIconUpgradeAlertController(with presenter: UIViewController) -> FancyAlertViewController {
        let newIconButton = ButtonConfig(Strings.newIconButtonTitle) { controller, _ in
            controller.dismiss(animated: true)

            let appIconController = AppIconViewController()
            let navigationController = UINavigationController(rootViewController: appIconController)
            navigationController.modalPresentationStyle = .formSheet
            presenter.present(navigationController, animated: true, completion: nil)
        }

        let dismissButton = ButtonConfig(Strings.dismissTitle) { controller, _ in
            controller.dismiss(animated: true)
        }

        let image = UIImage(named: "custom-icons-alert")

        let config = FancyAlertViewController.Config(titleText: Strings.titleText,
                                                     bodyText: Strings.bodyText,
                                                     headerImage: image,
                                                     headerBackgroundColor: .basicBackground,
                                                     dividerPosition: .topWithPadding,
                                                     defaultButton: newIconButton,
                                                     cancelButton: dismissButton,
                                                     dismissAction: {})

        let controller = FancyAlertViewController.controllerWithConfiguration(configuration: config)
        return controller
    }
}

// MARK: - User Defaults

extension UserDefaults {
    private enum Keys: String {
        case hasShownCustomAppIconUpgradeAlert = "custom-app-icon-upgrade-alert-shown"
    }

    var hasShownCustomAppIconUpgradeAlert: Bool {
        get {
            return bool(forKey: Keys.hasShownCustomAppIconUpgradeAlert.rawValue)
        }
        set {
            set(newValue, forKey: Keys.hasShownCustomAppIconUpgradeAlert.rawValue)
        }
    }
}
