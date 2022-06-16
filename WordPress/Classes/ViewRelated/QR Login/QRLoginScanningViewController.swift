import UIKit
class QRLoginScanningViewController: UIViewController {
    var coordinator: QRLoginScanningCoordinator?
}
extension QRLoginScanningViewController: QRLoginScanningView {
    func showError(_ message: String) {
    }
    func showCameraLayer(_ previewLayer: AVCaptureVideoPreviewLayer) {
    }
}
