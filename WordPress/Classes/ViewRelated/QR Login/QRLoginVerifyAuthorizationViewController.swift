import UIKit

class QRLoginVerifyAuthorizationViewController: UIViewController {

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
