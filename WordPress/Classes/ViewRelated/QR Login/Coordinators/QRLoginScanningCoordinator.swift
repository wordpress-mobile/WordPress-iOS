import Foundation

protocol QRLoginScanningView {
    func showError(_ message: String)
    func showCameraLayer(_ layer: AVCaptureVideoPreviewLayer)
}

class QRLoginScanningCoordinator: NSObject {
    let parentCoordinator: QRLoginCoordinator
    let view: QRLoginScanningView

    init(view: QRLoginScanningView, parentCoordinator: QRLoginCoordinator) {
        self.view = view
        self.parentCoordinator = parentCoordinator
    }
    // MARK: - Strings
    private struct Strings {
        struct accessAlert {
            static let title = NSLocalizedString("Camera access needed to scan login codes", comment: "Title of an alert informing the user the camera permission for the app is disabled and its needed to proceed")
            static let message = NSLocalizedString("This app needs permission to access the Camera to scan login codes, tap on the Open Settings button to enable it.", comment: "A description informing the user in order to proceed with this feature we will need camera permissions, and how to enable it.")
            static let openSettings = NSLocalizedString("Open Settings", comment: "Title of a button that opens the apps settings in the system Settings.app")
            static let dismiss = NSLocalizedString("Cancel", comment: "Title of a button that dismisses the permissions alert")
        }
    }
}
// MARK: - Camera Access Check
extension QRLoginScanningCoordinator {
    static func checkCameraPermissions(from source: UIViewController, completion: @escaping () -> Void) {
        Self.requestCameraAccessIfNeeded { granted in
            DispatchQueue.main.async {
                guard granted else {
                    Self.showNeedAccessAlert(from: source)
                    return
                }

                completion()
            }
        }
    }

    static private func needsCameraAccess() -> Bool {
        return AVCaptureDevice.authorizationStatus(for: .video) != .authorized
    }

    static private func requestCameraAccessIfNeeded(_ completion: @escaping (Bool) -> Void ) {
        guard needsCameraAccess() else {
            completion(true)
            return
        }

        AVCaptureDevice.requestAccess(for: .video, completionHandler: completion)
    }

    static private func showNeedAccessAlert(from source: UIViewController) {
        let alert = UIAlertController(title: Strings.accessAlert.title,
                                      message: Strings.accessAlert.message,
                                      preferredStyle: .alert)

        alert.addActionWithTitle(Strings.accessAlert.dismiss, style: .cancel)
        alert.addDefaultActionWithTitle(Strings.accessAlert.openSettings) { action in
            UIApplication.shared.openSettings()
        }

        source.present(alert, animated: true)
    }
}
