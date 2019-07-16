import Foundation

/// This extension handles Alert operations.
extension GutenbergViewController {

    enum InfoDialog {
        static let key = "Gutenberg.InformativeDialog"
        static let message = NSLocalizedString(
            "This post uses the block editor, which is the default editor for new posts. To enable the classic editor, go to Me > App Settings.",
            comment: "Popup content about why this post is being opened in block editor"
        )
        static let title = NSLocalizedString(
            "Block editor enabled", 
            comment: "Popup title about why this post is being opened in block editor"
        )
        static let okButtonTitle   = NSLocalizedString("OK", comment: "OK button to close the informative dialog on Gutenberg editor")
    }

    func showInformativeDialogIfNecessary() {
        GutenbergViewController.showInformativeDialogIfNecessary(showing: post, on: self)
    }

    static func showInformativeDialogIfNecessary(
        using userDefaults: KeyValueDatabase = UserDefaults.standard,
        showing post: AbstractPost,
        on viewController: UIViewControllerTransitioningDelegate & UIViewController,
        animated: Bool = true
    ) {
        let settings = GutenbergSettings(database: userDefaults)
        guard
            !userDefaults.bool(forKey: InfoDialog.key),
            post.containsGutenbergBlocks(),
            settings.isGutenbergEnabled() == false
        else {
            // Don't show if this was shown before or the post does not contain blocks or gutenberg is already enabled.
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

        // Toggle gutenberg default to true
        settings.toggleGutenberg()
    }
}
