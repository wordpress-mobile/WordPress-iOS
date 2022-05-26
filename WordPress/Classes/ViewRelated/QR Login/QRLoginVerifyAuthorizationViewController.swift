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
    func render() {
    }

    func renderCompletion() {
    }

    func showLoading() {
    }

    func showAuthenticating() {
    }

    func showNoConnectionError() {
    }
}
    }
}
