import UIKit
import AVFoundation

class QRLoginScanningViewController: UIViewController {
    @IBOutlet weak var overlayView: UIView!
    @IBOutlet weak var scanFocusImageView: UIImageView!
    @IBOutlet weak var errorLabel: UILabel!

    var coordinator: QRLoginScanningCoordinator?
}
extension QRLoginScanningViewController: QRLoginScanningView {
    func showError(_ message: String) {
    }
    func showCameraLayer(_ previewLayer: AVCaptureVideoPreviewLayer) {
        previewLayer.frame = view.layer.bounds

        // Insert the layer below our scan focus overlay image
        view.layer.insertSublayer(previewLayer, below: overlayView.layer)
    }
}
    }
}
