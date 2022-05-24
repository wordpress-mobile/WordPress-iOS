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
// MARK: - Animations
private extension QRLoginScanningViewController {
    func startAnimations() {
        pulsateFocusArea()
    }

    func stopAnimations() {
        scanFocusImageView.layer.removeAllAnimations()
    }

    /// Creates a pulsing animation that scales the focus area corners up and down
    func pulsateFocusArea() {
        let layerAnimation = CABasicAnimation(keyPath: "transform.scale")
        layerAnimation.fromValue = 1
        layerAnimation.toValue = 1.05
        layerAnimation.isAdditive = false
        layerAnimation.duration = 1
        layerAnimation.fillMode = .forwards
        layerAnimation.isRemovedOnCompletion = true
        layerAnimation.repeatCount = .infinity
        layerAnimation.autoreverses = true

        scanFocusImageView.layer.add(layerAnimation, forKey: "growingAnimation")
    }
}
