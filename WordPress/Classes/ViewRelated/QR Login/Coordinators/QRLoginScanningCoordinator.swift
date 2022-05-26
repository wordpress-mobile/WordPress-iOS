import Foundation
import AVFoundation

protocol QRLoginScanningView {
    func showError(_ message: String)
    func showCameraLayer(_ layer: AVCaptureVideoPreviewLayer)
}

class QRLoginScanningCoordinator: NSObject {
    let parentCoordinator: QRLoginCoordinator
    let view: QRLoginScanningView

    // Camera Handling
    var session: AVCaptureSession?
    var cameraDevice: AVCaptureDevice?

    init(view: QRLoginScanningView, parentCoordinator: QRLoginCoordinator) {
        self.view = view
        self.parentCoordinator = parentCoordinator
    }

    func start() {
        configureCamera()

        guard cameraDevice == nil else {
            configureCameraPreview()
            return
        }

        showNoCameraError()
    }

    // MARK: - Strings
    private struct Strings {
        static let noCameraError = NSLocalizedString("This app needs permission to access the Camera to capture new media, please change the privacy settings if you wish to allow this.", comment: "An error message display if the users device does not have a camera input available")

        struct accessAlert {
            static let title = NSLocalizedString("Camera access needed to scan login codes", comment: "Title of an alert informing the user the camera permission for the app is disabled and its needed to proceed")
            static let message = NSLocalizedString("This app needs permission to access the Camera to scan login codes, tap on the Open Settings button to enable it.", comment: "A description informing the user in order to proceed with this feature we will need camera permissions, and how to enable it.")
            static let openSettings = NSLocalizedString("Open Settings", comment: "Title of a button that opens the apps settings in the system Settings.app")
            static let dismiss = NSLocalizedString("Cancel", comment: "Title of a button that dismisses the permissions alert")
        }
    }
}

// MARK: - View Interactions
extension QRLoginScanningCoordinator {
    func viewDidAppear() {
        startCameraSession()
    }

    func viewWillDisappear() {
        stopCameraSession()
    }

    func didTapDismiss() {
        parentCoordinator.dismiss()
    }

    func didScanToken(_ token: QRLoginToken) {
        // Give the user a tap to let them know they've successfully scanned the code
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        // Stop the camera immediately to prevent further scanning
        stopCameraSession()

        // Show the next step in the flow
        parentCoordinator.didScanToken(token)
    }
}

// MARK: - Private: Camera Related Code
private extension QRLoginScanningCoordinator {
    func startCameraSession() {
        session?.startRunning()
    }

    func stopCameraSession() {
        session?.stopRunning()
    }

    func configureCamera() {
        try? configureCaptureDevice()
        configureCaptureSession()
    }

    func showNoCameraError() {
        view.showError(Strings.noCameraError)
    }

    /// Attempts to grab the default camera for the device
    func configureCaptureDevice() throws {
       guard let camera = AVCaptureDevice.default(for: .video) else {
           return
       }

       if camera.isFocusModeSupported(.continuousAutoFocus) {
           try camera.lockForConfiguration()
           camera.focusMode = .continuousAutoFocus
           camera.unlockForConfiguration()
       }

        cameraDevice = camera
   }

    func configureCaptureSession() {
        guard let cameraDevice = cameraDevice, let deviceInput = try? AVCaptureDeviceInput(device: cameraDevice) else {
            return
        }

        let session = AVCaptureSession()
        if session.canAddInput(deviceInput) {
            session.addInput(deviceInput)
        }

        let output = AVCaptureMetadataOutput()

        // Add the QR Code scanning
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            output.metadataObjectTypes = [.qr]
        }

        self.session = session
    }

    func configureCameraPreview() {
        guard let session = session else {
            showNoCameraError()
            return
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill

        view.showCameraLayer(previewLayer)
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

// MARK: - AVCaptureMetadataOutputObjectsDelegate
extension QRLoginScanningCoordinator: AVCaptureMetadataOutputObjectsDelegate {
    func validLink(_ stringValue: String) -> Bool {
        guard let url = URL(string: stringValue), QRLoginURLParser.isValidHost(url: url) else {
            return false
        }

        return true
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Wait until we have at least 1 scanned object with a URL
        guard let first = metadataObjects.first as? AVMetadataMachineReadableCodeObject, let string = first.stringValue else {
            return
        }

        guard validLink(string) else {
            return
        }

        guard let token = QRLoginURLParser(urlString: string).parse() else {
            return
        }

        didScanToken(token)
    }
}
