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
}
