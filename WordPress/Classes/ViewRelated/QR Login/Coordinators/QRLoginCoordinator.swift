import UIKit

class QRLoginCoordinator {
    var navigationController: UINavigationController

    init(navigationController: UINavigationController = UINavigationController()) {
        self.navigationController = navigationController
        configureNavigationController()
    }

    func dismiss() {
        navigationController.dismiss(animated: true)
    }

    func didScanCode(_ code: String) {
        showVerifyAuthorization(loginCode: code)
    }

    func showCameraScanningView(from source: UIViewController? = nil) {
        let controller = QRLoginScanningViewController()
        controller.coordinator = QRLoginScanningCoordinator(view: controller, parentCoordinator: self)

        pushOrPresent(controller, from: source)
    }

    func showVerifyAuthorization(loginCode: String, from source: UIViewController? = nil) {
        let controller = QRLoginVerifyAuthorizationViewController()
        controller.coordinator = QRLoginVerifyCoordinator(loginCode: loginCode,
                                                          view: controller,
                                                          parentCoordinator: self)

        pushOrPresent(controller, from: source)
    }
}

// MARK: - Private
private extension QRLoginCoordinator {
    func configureNavigationController() {
        navigationController.isNavigationBarHidden = true
        navigationController.modalPresentationStyle = .fullScreen
    }

    func pushOrPresent(_ controller: UIViewController, from source: UIViewController?) {
        guard source != nil else {
            navigationController.pushViewController(controller, animated: true)
            return
        }

        navigationController.setViewControllers([controller], animated: false)
        source?.present(navigationController, animated: true)
    }
}

// MARK: - Presenting the QR Login Flow
extension QRLoginCoordinator {
    /// Present the QR login flow starting with the scanning step
    static func present(from source: UIViewController) {
        QRLoginScanningCoordinator.checkCameraPermissions(from: source) {
            QRLoginCoordinator().showCameraScanningView(from: source)
        }
    }

    /// Display QR validation flow with a specific code, skipping the scanning step
    /// and going to the validation flow
    static func present(code: String, from source: UIViewController) {
        QRLoginCoordinator().showVerifyAuthorization(loginCode: code, from: source)
    }
}
