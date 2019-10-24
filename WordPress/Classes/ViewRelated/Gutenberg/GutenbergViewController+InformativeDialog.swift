import Foundation

/// This extension handles Alert operations.
extension GutenbergViewController {

    enum InfoDialog {
        static let postMessage = NSLocalizedString(
            "You’re now using the block editor for new posts — great! If you’d like to change to the classic editor, go to ‘My Site’ > ‘Site Settings’.",
            comment: "Popup content about why this post is being opened in block editor"
        )
        static let pageMessage = NSLocalizedString(
            "You’re now using the block editor for new pages — great! If you’d like to change to the classic editor, go to ‘My Site’ > ‘Site Settings’.",
            comment: "Popup content about why this post is being opened in block editor"
        )
        static let title = NSLocalizedString(
            "Block editor enabled",
            comment: "Popup title about why this post is being opened in block editor"
        )
        static let okButtonTitle   = NSLocalizedString("OK", comment: "OK button to close the informative dialog on Gutenberg editor")
    }

    func showInformativeDialogIfNecessary() {
        if shouldPresentInformativeDialog {
            let message = post is Page ? InfoDialog.pageMessage : InfoDialog.postMessage
            GutenbergViewController.showInformativeDialog(on: self, message: message)
        }
    }

    static func showInformativeDialog(
        on viewController: UIViewControllerTransitioningDelegate & UIViewController,
        message: String,
        animated: Bool = true
    ) {
        let okButton: (title: String, handler: FancyAlertViewController.FancyAlertButtonHandler?) =
        (
            title: InfoDialog.okButtonTitle,
            handler: { (alert, button) in
                alert.dismiss(animated: animated, completion: nil)
            }
        )

        let config = FancyAlertViewController.Config(
            titleText: InfoDialog.title,
            bodyText: message,
            headerImage: nil,
            dividerPosition: .top,
            defaultButton: okButton,
            cancelButton: nil
        )

        let alert = FancyAlertViewController.controllerWithConfiguration(configuration: config)
        alert.modalPresentationStyle = .custom
        alert.transitioningDelegate = viewController
        viewController.present(alert, animated: animated)
    }
}
