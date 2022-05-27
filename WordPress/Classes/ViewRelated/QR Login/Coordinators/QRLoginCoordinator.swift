import UIKit

struct QRLoginCoordinator {
    enum QRLoginOrigin: String {
        case menu
        case deepLink = "deep_link"
    }

    let navigationController: UINavigationController
    let origin: QRLoginOrigin

    init(navigationController: UINavigationController = UINavigationController(), origin: QRLoginOrigin) {
        self.navigationController = navigationController
        self.origin = origin

        configureNavigationController()
    }

    static func didHandle(url: URL) -> Bool {
        guard
            let token = QRLoginURLParser(urlString: url.absoluteString).parse(),
            let source = UIApplication.shared.leafViewController
        else {
            return false
        }

        self.init(origin: .deepLink).showVerifyAuthorization(token: token, from: source)
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
        QRLoginScanningCoordinator.checkCameraPermissions(from: navigationController, origin: origin) {
            self.navigationController.setViewControllers([self.scanningViewController()], animated: true)
        }
    }

    func track(_ event: WPAnalyticsEvent, properties: [AnyHashable: Any]? = nil) {
        var props: [AnyHashable: Any] = ["origin": origin.rawValue]

        guard let properties = properties else {
            WPAnalytics.track(event, properties: props)
            return
        }
        
        props.merge(properties) { (_, new) in new }
        WPAnalytics.track(event, properties: props)
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
    static func present(from source: UIViewController, origin: QRLoginOrigin) {
        QRLoginScanningCoordinator.checkCameraPermissions(from: source, origin: origin) {
            QRLoginCoordinator(origin: origin).showCameraScanningView(from: source)
        }
    }

    /// Display QR validation flow with a specific code, skipping the scanning step
    /// and going to the validation flow
    static func present(token: QRLoginToken, from source: UIViewController, origin: QRLoginOrigin) {
        QRLoginCoordinator(origin: origin).showVerifyAuthorization(token: token, from: source)
    }
}
