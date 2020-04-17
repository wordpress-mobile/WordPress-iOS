import UIKit
import Gridicons

/// Display an Alert Controller that prompts for a password
class PasswordAlertController {

    var passwordField: UITextField!

    var onSubmit: ((String?) -> Void)?

    var onCancel: (() -> Void)?

    init(onSubmit: @escaping (String?) -> Void, onCancel: @escaping () -> Void) {
        self.onSubmit = onSubmit
        self.onCancel = onCancel
    }

    /// Show the Alert Controller from a given view controller
    func show(from viewController: UIViewController) {
        let alertController = UIAlertController(
            title: AbstractPost.passwordProtectedLabel,
            message: Constants.passwordMessage,
            preferredStyle: .alert
        )

        let submitAction = UIAlertAction(title: Constants.alertSubmit, style: .default) { _ in
            self.onSubmit?(self.passwordField.text)
            self.onSubmit = nil
            self.onCancel = nil
            alertController.dismiss(animated: true)
        }

        let cancelAction = UIAlertAction(title: Constants.alertCancel, style: .cancel) { _ in
            self.onCancel?()
            self.onSubmit = nil
            self.onCancel = nil
            alertController.dismiss(animated: true)
        }

        alertController.addTextField { textField in
            self.passwordField = textField
            textField.placeholder = Constants.postPassword
            let button = UIButton()
            textField.rightView = button
            textField.rightViewMode = .always
            self.togglePassword(button)
            button.addTarget(self, action: #selector(self.togglePassword(_:)), for: .touchUpInside)
        }

        alertController.addAction(submitAction)
        alertController.addAction(cancelAction)

        viewController.present(alertController, animated: true, completion: nil)
    }

    /// Toggle the UITextField isSecureTextEntry on/off
    @objc func togglePassword(_ sender: UIButton) {
        let isSecureTextEntry = !passwordField.isSecureTextEntry
        passwordField.isSecureTextEntry = isSecureTextEntry
        sender.setImage(isSecureTextEntry ? .gridicon(.visible) : .gridicon(.notVisible), for: .normal)
    }

    private enum Constants {
        static let alertSubmit = NSLocalizedString("OK", comment: "Submit button on prompt for user information.")
        static let alertCancel = NSLocalizedString("Cancel", comment: "Cancel prompt for user information.")
        static let postPassword = NSLocalizedString("Enter password", comment: "Placeholder of a field to type a password to protect the post.")
        static let passwordMessage = NSLocalizedString("Enter a password to protect this post", comment: "Message explaining why the user might enter a password.")
    }

}
