import Foundation

struct QRLoginCameraPermissionsHandler: QRCameraPermissionsHandler {
    func needsCameraAccess() -> Bool {
        return AVCaptureDevice.authorizationStatus(for: .video) != .authorized
    }

    func requestCameraAccess(_ completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video, completionHandler: completion)
    }

    func showNeedAccessAlert(from source: UIViewController?) {
        let alert = UIAlertController(title: Strings.title,
                                      message: Strings.message,
                                      preferredStyle: .alert)

        alert.addActionWithTitle(Strings.dismiss, style: .cancel)
        alert.addDefaultActionWithTitle(Strings.openSettings) { action in
            UIApplication.shared.openSettings()
        }

        guard let source = source else {
            alert.presentFromRootViewController()
            return
        }

        source.present(alert, animated: true)
    }

    func checkCameraPermissions(from source: UIViewController, origin: QRLoginCoordinator.QRLoginOrigin, completion: @escaping () -> Void) {
        guard needsCameraAccess() else {
            completion()
            return
        }

        WPAnalytics.track(.qrLoginCameraPermissionDisplayed, properties: ["origin": origin.rawValue])

        requestCameraAccess { granted in
            DispatchQueue.main.async {
                guard granted else {
                    WPAnalytics.track(.qrLoginCameraPermissionDenied, properties: ["origin": origin.rawValue])
                    self.showNeedAccessAlert(from: source)
                    return
                }

                WPAnalytics.track(.qrLoginCameraPermissionApproved, properties: ["origin": origin.rawValue])
                completion()
            }
        }
    }

    private enum Strings {
        static let title = NSLocalizedString("Camera access needed to scan login codes", comment: "Title of an alert informing the user the camera permission for the app is disabled and its needed to proceed")
        static let message = NSLocalizedString("This app needs permission to access the Camera to scan login codes, tap on the Open Settings button to enable it.", comment: "A description informing the user in order to proceed with this feature we will need camera permissions, and how to enable it.")
        static let openSettings = NSLocalizedString("Open Settings", comment: "Title of a button that opens the apps settings in the system Settings.app")
        static let dismiss = NSLocalizedString("Cancel", comment: "Title of a button that dismisses the permissions alert")
    }
}
