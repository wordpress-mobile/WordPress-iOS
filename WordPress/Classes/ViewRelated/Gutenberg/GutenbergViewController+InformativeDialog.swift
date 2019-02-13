import Foundation

protocol GutenbergFlagsUserDefaultsProtocol {
    func set(_ value: Bool, forKey defaultName: String)
    func bool(forKey defaultName: String) -> Bool
}

extension UserDefaults: GutenbergFlagsUserDefaultsProtocol {

}

/// This extension handles Alert operations.
extension GutenbergViewController {

    enum Const {
        enum Key {
            static let informativeDialog = "Gutenberg.InformativeDialog"
        }
        enum Alert {
            static let message = "The post was originally created in the Block Editor, so we've also enabled it on this Post. Switch back to Classic at any time by tapping ••• in the top bar."
            static let title = "Block Editor Enabled"
            static let okButtonTitle   = NSLocalizedString("OK", comment: "OK button to close the informative dialog on Gutenberg editor")
        }
    }

    func showInformativeDialogIfNecessary() {
        GutenbergViewController.showInformativeDialogIfNecessary(on: self)
    }

    static func showInformativeDialogIfNecessary(
        using userDefaults: GutenbergFlagsUserDefaultsProtocol = UserDefaults.standard,
        on viewController: UIViewControllerTransitioningDelegate & UIViewController,
        animated: Bool = true
    ) {
        guard !userDefaults.bool(forKey: Const.Key.informativeDialog) else {
            // Don't show if it was shown before
            return
        }
        let okButton: (title: String, handler: FancyAlertViewController.FancyAlertButtonHandler?) =
        (
            title: Const.Alert.okButtonTitle,
            handler: { (alert, button) in
                alert.dismiss(animated: animated, completion: nil)
            }
        )

        let config = FancyAlertViewController.Config(
            titleText: Const.Alert.title,
            bodyText: Const.Alert.message,
            headerImage: nil,
            dividerPosition: .top,
            defaultButton: okButton,
            cancelButton: nil
        )

        let alert = FancyAlertViewController.controllerWithConfiguration(configuration: config)
        alert.modalPresentationStyle = .custom
        alert.transitioningDelegate = viewController
        viewController.present(alert, animated: animated)
        // Save that this alert is shown
        userDefaults.set(true, forKey: Const.Key.informativeDialog)
    }
}
