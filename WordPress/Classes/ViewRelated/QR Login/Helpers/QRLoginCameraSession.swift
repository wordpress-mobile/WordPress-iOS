import Foundation
import AVFoundation

class QRLoginCameraSession: NSObject, QRCodeScanningSession {
    var session: AVCaptureSession?
    // > Delegate any interaction with the AVCaptureSession—including its inputs and outputs—to a
    // > dedicated serial dispatch queue, so that the interaction doesn’t block the main queue.
    // >
    // > – https://developer.apple.com/documentation/avfoundation/capture_setup/avcam_building_a_camera_app
    let sessionQueue = DispatchQueue(label: "qrlogincamerasession.queue.serial")

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
        sessionQueue.async { [weak self] in
            self?.session?.startRunning()
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            self?.session?.stopRunning()
        }
    }
}

private extension QRLoginCameraSession {
    func startCameraSession() {
        sessionQueue.async { [weak self] in
            self?.session?.startRunning()
        }
    }

    func stopCameraSession() {
        sessionQueue.async { [weak self] in
            self?.session?.stopRunning()
        }
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
