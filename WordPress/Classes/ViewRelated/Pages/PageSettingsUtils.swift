import Foundation

class PageSettingsUtils: NSObject {

    /// Prompts a warning for removig the homepage from the published list. Returns `true` on continue and `false` on `Cancel`
    @objc static func promptHomepageWarning(_ completion: @escaping (Bool)->()) {
        let title = NSLocalizedString("Careful!", comment: "Title for the prompt warning that they are about to remove their homepage.")
        let message = NSLocalizedString("Proceeding could result in errors when loading your site.", comment: "Prompts the user that the selected action could break their site.")
        let alertContinue = NSLocalizedString("Continue", comment: "Title of a Continue button. Pressing the button acknowledges the warning and preforms the action.")
        let alertCancel = NSLocalizedString("Cancel", comment: "Title of a Cancel button. Pressing the button prevents the originally selected action.")

        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addActionWithTitle(alertContinue, style: .default) { (_) in
            completion(true)
        }
        alertController.addCancelActionWithTitle(alertCancel) { (_) in
            completion(false)
        }
        alertController.presentFromRootViewController()
    }
}
