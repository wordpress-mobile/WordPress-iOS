import Foundation
import QuartzCore

/// Encapsulates the interactions between the child and parent coordinators
protocol QRLoginParentCoordinator {
    func track(_ event: WPAnalyticsEvent)
    func track(_ event: WPAnalyticsEvent, properties: [AnyHashable: Any]?)

    func scanAgain()
    func didScanToken(_ token: QRLoginToken)
    func dismiss()
}

/// A simplified representation of a way to check whether the internet connection is available
protocol QRLoginConnectionChecker {
    var connectionAvailable: Bool { get }
}

/// Login camera scanning view
protocol QRLoginScanningView {
    func showError(_ message: String)
    func showCameraLayer(_ layer: CALayer)
}

/// Login verify view and all its states
protocol QRLoginVerifyView {
    /* Completion States */
    func render(response: QRLoginValidationResponse)
    func renderCompletion()

    /* Loading States */
    func showLoading()
    func showAuthenticating()

    /* Error States */
    func showNoConnectionError()
    func showQRLoginError(error: QRLoginError?)
    func showAuthenticationFailedError()
}

/// Generic camera permissions handler
protocol CameraPermissionsHandler {
    func needsCameraAccess() -> Bool
    func requestCameraAccess(_ completion: @escaping (Bool) -> Void)
    func showNeedAccessAlert(from source: UIViewController?)
}

/// QR Login Specific Permissions handler
protocol QRCameraPermissionsHandler: CameraPermissionsHandler {
    func checkCameraPermissions(from source: UIViewController, origin: QRLoginCoordinator.QRLoginOrigin, completion: @escaping () -> Void)
}

/// A delegate that handles when a code was scanned and whether its valid or not
protocol QRCodeScanningDelegate {
    func validLink(_ stringValue: String) -> Bool
    func didScanURLString(_ urlString: String)
}

/// Manages the camera scanning session
protocol QRCodeScanningSession {
    var hasCamera: Bool { get }
    var session: AVCaptureSession? { get }
    var previewLayer: CALayer? { get }

    var scanningDelegate: QRCodeScanningDelegate? { get set }

    func configure()

    func start()
    func stop()
}
