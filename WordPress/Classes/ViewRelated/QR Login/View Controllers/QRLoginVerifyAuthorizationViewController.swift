import UIKit

class QRLoginVerifyAuthorizationViewController: UIViewController {
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!

    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!

    var coordinator: QRLoginVerifyCoordinator?
}

// MARK: - View Methods
extension QRLoginVerifyAuthorizationViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.delegate = self

        coordinator?.start()

        applyStyles()
    }

    @IBAction func didTapConfirm(_ sender: Any) {
        coordinator?.confirm()
    }

    @IBAction func didTapCancel(_ sender: Any) {
        coordinator?.cancel()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
       return [.portrait, .portraitUpsideDown]
    }
}

// MARK: - UINavigation Controller Delegate
extension QRLoginVerifyAuthorizationViewController: UINavigationControllerDelegate {
    func navigationControllerSupportedInterfaceOrientations(_ navigationController: UINavigationController) -> UIInterfaceOrientationMask {
        return supportedInterfaceOrientations
    }

    func navigationControllerPreferredInterfaceOrientationForPresentation(_ navigationController: UINavigationController) -> UIInterfaceOrientation {
        return .portrait
    }
}

// MARK: - QRLoginVerifyView
extension QRLoginVerifyAuthorizationViewController: QRLoginVerifyView {
    func render(response: QRLoginValidationResponse) {
        let title: String
        if let browser = response.browser {
            title = String(format: Strings.title, browser, response.location)
        } else {
            title = String(format: Strings.defaultTitle, response.location)
        }

        update(imageName: Strings.imageName,
               title: title,
               subTitle: Strings.subtitle,
               confirmButton: Strings.confirmButton,
               cancelButton: Strings.cancelButton)

        stackView.isHidden = false
        hideLoading()
    }

    func renderCompletion() {
        update(imageName: Strings.completed.imageName,
               title: Strings.completed.title,
               subTitle: Strings.completed.subtitle,
               confirmButton: Strings.completed.confirmButton,
               cancelButton: nil)

        cancelButton.isHidden = true
        subTitleLabel.textColor = .secondaryLabel

        hideLoading()

        UINotificationFeedbackGenerator().notificationOccurred(.success)

        ConfettiView.cleanupAndAnimate(on: view, frame: navigationController?.view.frame ?? view.frame) { confettiView in
            // removing this instance when the animation completes, will prevent
            // the animation to suddenly stop if users navigate away early
            confettiView.removeFromSuperview()
        }
    }

    func showLoading() {
        stackView.isHidden = true
        startLoading()
    }

    func showAuthenticating() {
        stackView.layer.opacity = 0.5

        startLoading()
    }

    func showNoConnectionError() {
        update(imageName: Strings.noConnection.imageName,
               title: Strings.noConnection.title,
               subTitle: Strings.noConnection.subtitle,
               confirmButton: Strings.noConnection.confirmButton,
               cancelButton: Strings.noConnection.cancelButton)

        hideLoading()

        subTitleLabel.textColor = .secondaryLabel
    }

    func showQRLoginError(error: QRLoginError?) {
        switch error ?? .invalidData {
            case .invalidData:
                update(imageName: Strings.validationError.imageName,
                       title: Strings.validationError.invalidData.title,
                       subTitle: Strings.validationError.invalidData.subtitle,
                       confirmButton: Strings.validationError.confirmButton,
                       cancelButton: Strings.validationError.cancelButton)

            case .expired:
                update(imageName: Strings.validationError.imageName,
                       title: Strings.validationError.expired.title,
                       subTitle: Strings.validationError.expired.subtitle,
                       confirmButton: Strings.validationError.confirmButton,
                       cancelButton: Strings.validationError.cancelButton)
        }

        hideLoading()

        subTitleLabel.textColor = .secondaryLabel
    }

    func showAuthenticationFailedError() {
        update(imageName: Strings.validationError.imageName,
               title: Strings.validationError.authenticationFailed.title,
               subTitle: Strings.validationError.authenticationFailed.subtitle,
               confirmButton: Strings.validationError.confirmButton,
               cancelButton: Strings.validationError.cancelButton)

        hideLoading()

        subTitleLabel.textColor = .secondaryLabel
    }
}

// MARK: - Private: View Helpers
extension QRLoginVerifyAuthorizationViewController {
    private func applyStyles() {
        titleLabel.font = WPStyleGuide.serifFontForTextStyle(.title1, fontWeight: .semibold)
        titleLabel.textColor = .text

        subTitleLabel.font = .preferredFont(forTextStyle: .headline)
        subTitleLabel.textColor = .systemRed
    }

    private func hideLoading() {
        stackView.isHidden = false
        stackView.layer.opacity = 1

        loadingIndicator.isHidden = true
        loadingIndicator.stopAnimating()
    }

    private func startLoading() {
        loadingIndicator.startAnimating()
        loadingIndicator.isHidden = false
    }

    private func update(imageName: String, title: String, subTitle: String, confirmButton: String, cancelButton: String?) {
        imageView.image = UIImage(named: imageName)
        titleLabel.text = title
        subTitleLabel.text = subTitle
        self.confirmButton.setTitle(confirmButton, for: .normal)

        guard let cancelButton = cancelButton else {
            self.cancelButton.isHidden = true
            return
        }

        self.cancelButton.setTitle(cancelButton, for: .normal)
    }

    private enum Strings {
        static let imageName = "wp-illustration-mobile-save-for-later"
        static let title = NSLocalizedString("Are you trying to log in to %1$@ near %2$@?", comment: "Title that asks the user if they are the trying to login.  %1$@ is a placeholder for the browser name (Chrome/Firefox), %2$@ is a placeholder for the users location")
        static let defaultTitle = NSLocalizedString("Are you trying to log in to your web browser near %1$@?", comment: "Title that asks the user if they are the trying to log in.  %1$@ is a placeholder for the users location")
        static let subtitle = NSLocalizedString("Only scan QR codes taken directly from your web browser. Never scan a code sent to you by anyone else.", comment: "Warning label that informs the user to only scan login codes that they generated.")
        static let confirmButton = NSLocalizedString("Yes, log me in", comment: "Button label that confirms the user wants to log in and will authenticate them via the browser")
        static let cancelButton = NSLocalizedString("Cancel", comment: "Button label that dismisses the qr log in flow and returns the user back to the previous screen")

        enum completed {
            static let imageName = "domains-success"
            static let title = NSLocalizedString(
                "qrLoginVerifyAuthorization.completedInstructions.title",
                value: "You're logged in!",
                comment: "Title for the success view when the user has successfully logged in"
            )
            private static let subtitleFormat = NSLocalizedString(
                "qrLoginVerifyAuthorization.completedInstructions.subtitle",
                value: "Tap '%@' and head back to your web browser to continue.",
                comment: "Subtitle instructing the user to tap the dismiss button to leave the log in flow. %@ is a placeholder for the dismiss button name."
            )
            static let confirmButton = NSLocalizedString(
                "qrLoginVerifyAuthorization.completedInstructions.dismiss",
                value: "Dismiss",
                comment: "Button label that dismisses the qr log in flow and returns the user back to the previous screen"
            )
            static let subtitle = String(format: subtitleFormat, Self.confirmButton)
        }

        enum noConnection {
            static let imageName = "wp-illustration-empty-results"
            static let title = NSLocalizedString("No connection", comment: "Title for the error view when there's no connection")
            static let subtitle = NSLocalizedString("An active internet connection is required to scan log in codes", comment: "Error message shown when trying to scan a log in code without an active internet connection.")
            static let confirmButton = NSLocalizedString("Scan Again", comment: "Button label that prompts the user to scan the log in code again")
            static let cancelButton = NSLocalizedString("Cancel", comment: "Button label that dismisses the qr log in flow and returns the user back to the previous screen")
        }

        enum validationError {
            static let imageName = "wp-illustration-empty-results"
            static let confirmButton = NSLocalizedString("Scan Again", comment: "Button label that prompts the user to scan the log in code again")
            static let cancelButton = NSLocalizedString("Cancel", comment: "Button label that dismisses the qr log in flow and returns the user back to the previous screen")

            enum invalidData {
                static let title = NSLocalizedString("Could not validate the log in code", comment: "Title for the error view when the user scanned an invalid log in code")
                static let subtitle = NSLocalizedString("The log in code that was scanned could not be validated. Please tap the Scan Again button to rescan the code.", comment: "Error message shown when trying to scan an invalid log in code.")
            }

            enum expired {
                static let title = NSLocalizedString("Expired log in code", comment: "Title for the error view when the user scanned an expired log in code")
                static let subtitle = NSLocalizedString("This log in code has expired. Please tap the Scan Again button to rescan the code.", comment: "Error message shown when the user scanned an expired log in code.")
            }

            enum authenticationFailed {
                static let title = NSLocalizedString("Authentication Failed", comment: "Title for the error view when the authentication failed for any reason")
                static let subtitle = NSLocalizedString("Could not log you in using this log in code. Please tap the Scan Again button to rescan the code.", comment: "Error message shown when the user scanned an expired log in code.")
            }
        }
    }
}
