import UIKit

struct QRLoginCoordinator {
    var navigationController: UINavigationController

    init(navigationController: UINavigationController = UINavigationController()) {
        self.navigationController = navigationController
        configureNavigationController()
    }

    static func didHandle(url: URL) -> Bool {
        guard
            let token = QRLoginURLParser(urlString: url.absoluteString).parse(),
            let source = UIApplication.shared.leafViewController
        else {
            return false
        }

        self.init().showVerifyAuthorization(token: token, from: source)
        return true
    }

    func showCameraScanningView(from source: UIViewController? = nil) {
        pushOrPresent(scanningViewController(), from: source)
    }

    func showVerifyAuthorization(token: QRLoginToken, from source: UIViewController? = nil) {
        let controller = QRLoginVerifyAuthorizationViewController()
        controller.coordinator = QRLoginVerifyCoordinator(token: token,
                                                          view: controller,
                                                          parentCoordinator: self)

        pushOrPresent(controller, from: source)
    }
}

// MARK: - Child Coordinator Interactions
extension QRLoginCoordinator {
    func dismiss() {
        navigationController.dismiss(animated: true)
    }

    func didScanToken(_ token: QRLoginToken) {
        showVerifyAuthorization(token: token)
    }

    func scanAgain() {
        QRLoginScanningCoordinator.checkCameraPermissions(from: navigationController) {
            self.navigationController.setViewControllers([self.scanningViewController()], animated: true)
        }
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

    private func scanningViewController() -> QRLoginScanningViewController {
        let controller = QRLoginScanningViewController()
        controller.coordinator = QRLoginScanningCoordinator(view: controller, parentCoordinator: self)

        return controller
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
    static func present(token: QRLoginToken, from source: UIViewController) {
        QRLoginCoordinator().showVerifyAuthorization(token: token, from: source)
    }
}
