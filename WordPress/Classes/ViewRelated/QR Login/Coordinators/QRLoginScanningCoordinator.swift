import Foundation
import AVFoundation

class QRLoginScanningCoordinator: NSObject {
    let parentCoordinator: QRLoginParentCoordinator
    let view: QRLoginScanningView

    // Camera Handling
    var session: AVCaptureSession?
    var cameraDevice: AVCaptureDevice?

    init(view: QRLoginScanningView, parentCoordinator: QRLoginParentCoordinator) {
        self.view = view
        self.parentCoordinator = parentCoordinator
    }

    func start() {
        parentCoordinator.track(.qrLoginScannerDisplayed)

        configureCamera()

        // Check if the camera is not accessible, and display an error if needed
        guard cameraDevice != nil else {
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
        startCameraSession()
    }

    func viewWillDisappear() {
        stopCameraSession()
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
        QRLoginCameraPermissionsHandler().showNeedAccessAlert(from: nil)
        
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
