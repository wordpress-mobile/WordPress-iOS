import Foundation

class QRLoginScanningCoordinator: NSObject {
    let parentCoordinator: QRLoginParentCoordinator
    let view: QRLoginScanningView
    var cameraSession: QRCodeScanningSession

    init(view: QRLoginScanningView, parentCoordinator: QRLoginParentCoordinator, cameraSession: QRCodeScanningSession = QRLoginCameraSession()) {
        self.view = view
        self.parentCoordinator = parentCoordinator
        self.cameraSession = cameraSession
    }

    func start() {
        cameraSession.scanningDelegate = self
        parentCoordinator.track(.qrLoginScannerDisplayed)
        cameraSession.configure()

        // Check if the camera is not accessible, and display an error if needed
        guard cameraSession.hasCamera else {
            showNoCameraError()
            return
        }

        configureCameraPreview()
    }

    // MARK: - Strings
    private enum Strings {
        static let noCameraError = NSLocalizedString("This app needs permission to access the Camera to capture new media, please change the privacy settings if you wish to allow this.", comment: "An error message display if the users device does not have a camera input available")
    }
}

// MARK: - View Interactions
extension QRLoginScanningCoordinator {
    func viewDidAppear() {
        cameraSession.start()
    }

    func viewWillDisappear() {
        cameraSession.stop()
    }

    func didTapDismiss() {
        parentCoordinator.track(.qrLoginScannerDismissed)
        parentCoordinator.dismiss()
    }

    func didScanToken(_ token: QRLoginToken) {
        parentCoordinator.track(.qrLoginScannerScannedCode)

        // Give the user a tap to let them know they've successfully scanned the code
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        // Stop the camera immediately to prevent further scanning
        cameraSession.stop()

        // Show the next step in the flow
        parentCoordinator.didScanToken(token)
    }
}

// MARK: - Private: Camera Related Code
private extension QRLoginScanningCoordinator {
    func showNoCameraError() {
        QRLoginCameraPermissionsHandler().showNeedAccessAlert(from: nil)

        view.showError(Strings.noCameraError)
    }

    func configureCameraPreview() {
        guard let session = cameraSession.session else {
            showNoCameraError()
            return
        }


        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill

        view.showCameraLayer(previewLayer)
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate
extension QRLoginScanningCoordinator: QRCodeScanningDelegate {
    func validLink(_ stringValue: String) -> Bool {
        guard let url = URL(string: stringValue), QRLoginURLParser.isValidHost(url: url) else {
            return false
        }

        return true
    }

    func didScanURLString(_ urlString: String) {
        guard let token = QRLoginURLParser(urlString: urlString).parse() else {
            return
        }

        didScanToken(token)
    }
}
