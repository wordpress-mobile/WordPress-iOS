import Foundation

protocol GutenbergFlagsUserDefaultsProtocol {
    func set(_ value: Bool, forKey defaultName: String)
    func bool(forKey defaultName: String) -> Bool
}

extension UserDefaults: GutenbergFlagsUserDefaultsProtocol {

}

/// This extension handles Alert operations.
extension GutenbergViewController {

    enum InfoDialog {
        static let key = "Gutenberg.InformativeDialog"
        static let message = NSLocalizedString(
            "This post was originally created in the block editor, so we've also enabled it on this Post. Switch back to the classic editor at any time by tapping ••• in the top bar.",
            comment: "Popup content about why this post is being opened in block editor"
        )
        static let title = NSLocalizedString("Block Editor Enabled", comment: "Popup title about why this post is being opened in block editor")
        static let okButtonTitle   = NSLocalizedString("OK", comment: "OK button to close the informative dialog on Gutenberg editor")
    }

    func showInformativeDialogIfNecessary() {
        GutenbergViewController.showInformativeDialogIfNecessary(showing: post, on: self)
    }

    static func showInformativeDialogIfNecessary(
        using userDefaults: GutenbergFlagsUserDefaultsProtocol = UserDefaults.standard,
        showing post: AbstractPost,
        on viewController: UIViewControllerTransitioningDelegate & UIViewController,
        animated: Bool = true
    ) {
        guard !userDefaults.bool(forKey: InfoDialog.key),
            post.containsGutenbergBlocks() else {
            // Don't show if this was shown before or the post does not contain blocks
            return
        }
        let okButton: (title: String, handler: FancyAlertViewController.FancyAlertButtonHandler?) =
        (
            title: InfoDialog.okButtonTitle,
            handler: { (alert, button) in
                alert.dismiss(animated: animated, completion: nil)
            }
        )

        let config = FancyAlertViewController.Config(
            titleText: InfoDialog.title,
            bodyText: InfoDialog.message,
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
        userDefaults.set(true, forKey: InfoDialog.key)
    }
}
