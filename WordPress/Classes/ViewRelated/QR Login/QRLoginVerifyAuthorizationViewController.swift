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
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
