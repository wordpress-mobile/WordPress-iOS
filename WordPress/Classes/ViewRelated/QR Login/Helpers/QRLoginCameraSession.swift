import Foundation
import AVFoundation

class QRLoginCameraSession: NSObject, QRCodeScanningSession {
    var session: AVCaptureSession?
    var cameraDevice: AVCaptureDevice?

    var hasCamera: Bool {
        return cameraDevice != nil
    }

    var previewLayer: CALayer? {
        guard let session = session else {
            return nil
        }

        return AVCaptureVideoPreviewLayer(session: session)
    }

    var scanningDelegate: QRCodeScanningDelegate?

    func configure() {
        configureCamera()
    }

    func start() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.session?.startRunning()
        }
    }

    func stop() {
        session?.stopRunning()
    }
}

private extension QRLoginCameraSession {
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

    // Attempts to grab the default camera for the device
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
}

extension QRLoginCameraSession: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Wait until we have at least 1 scanned object with a URL
        guard let first = metadataObjects.first as? AVMetadataMachineReadableCodeObject, let string = first.stringValue else {
            return
        }

        guard let delegate = scanningDelegate else {
            return
        }

        guard delegate.validLink(string) else {
            return
        }

        delegate.didScanURLString(string)
    }
}
