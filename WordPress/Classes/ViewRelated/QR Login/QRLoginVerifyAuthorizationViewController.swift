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

        coordinator?.start()

        applyStyles()
    }

    @IBAction func didTapConfirm(_ sender: Any) {
        coordinator?.confirm()
    }

    @IBAction func didTapCancel(_ sender: Any) {
        coordinator?.cancel()
    }
}

// MARK: - QRLoginVerifyView
extension QRLoginVerifyAuthorizationViewController: QRLoginVerifyView {
    func render(response: QRLoginValidationResponse) {
        imageView.image = UIImage(named: Strings.imageName)
        titleLabel.text = Strings.title
        subTitleLabel.text = Strings.subtitle
        confirmButton.setTitle(Strings.confirmButton, for: .normal)
        cancelButton.setTitle(Strings.cancelButton, for: .normal)

        stackView.isHidden = false

        loadingIndicator.isHidden = true
        loadingIndicator.stopAnimating()
    }

    func renderCompletion() {
        imageView.image = UIImage(named: Strings.completed.imageName)
        titleLabel.text = Strings.completed.title
        subTitleLabel.text = Strings.completed.subtitle
        subTitleLabel.textColor = .secondaryLabel
        confirmButton.setTitle(Strings.completed.confirmButton, for: .normal)
        cancelButton.isHidden = true

        stackView.layer.opacity = 1
        loadingIndicator.isHidden = true
        loadingIndicator.stopAnimating()

        UINotificationFeedbackGenerator().notificationOccurred(.success)

        ConfettiView.cleanupAndAnimate(on: view, frame: navigationController?.view.frame ?? view.frame) { confettiView in
            // removing this instance when the animation completes, will prevent
            // the animation to suddenly stop if users navigate away early
            confettiView.removeFromSuperview()
        }
    }

    func showLoading() {
        stackView.isHidden = true
        loadingIndicator.startAnimating()
        loadingIndicator.isHidden = false
    }

    func showAuthenticating() {
        stackView.layer.opacity = 0.5

        loadingIndicator.startAnimating()
        loadingIndicator.isHidden = false
    }

    func showNoConnectionError() {
        // TODO: Add error handling
        print("no connection error")
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

    private struct Strings {
        static let imageName = "wp-illustration-mobile-save-for-later"
        static let title = NSLocalizedString("Are you trying to login on your web browser?", comment: "TODO")
        static let subtitle = NSLocalizedString("Only scan QR codes taken directly from your web browser. Never scan a code sent to you by anyone else.", comment: "TODO")
        static let confirmButton = NSLocalizedString("Yes, log me in", comment: "TODO")
        static let cancelButton = NSLocalizedString("Cancel", comment: "TODO")

        struct completed {
            static let imageName = "domains-success"
            static let title = NSLocalizedString("You're logged in!", comment: "TODO")
            static let subtitle = NSLocalizedString("Tap dismiss and head back to your web browser to continue.", comment: "TODO")
            static let confirmButton = NSLocalizedString("Dismiss", comment: "TODO")
        }
    }
}
