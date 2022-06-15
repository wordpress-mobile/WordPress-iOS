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
        scanFocusImageView.isHidden = true
        stopAnimations()

        view.backgroundColor = .black

        errorLabel.text = message
        errorLabel.font = WPStyleGuide.regularTextFont()
        errorLabel.textColor = .white
        errorLabel.isHidden = false
    }

    func showCameraLayer(_ previewLayer: AVCaptureVideoPreviewLayer) {
        previewLayer.frame = view.layer.bounds

        // Insert the layer below our scan focus overlay image
        view.layer.insertSublayer(previewLayer, below: overlayView.layer)
    }
}

// MARK: - View Methods
extension QRLoginScanningViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        errorLabel.isHidden = true
        coordinator?.start()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        coordinator?.viewDidAppear()
        startAnimations()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        coordinator?.viewWillDisappear()
        stopAnimations()
    }

    @IBAction func didTapCloseButton(_ sender: Any) {
        dismiss(animated: true)
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
        layerAnimation.fromValue = AnimationConstants.scale.min
        layerAnimation.toValue = AnimationConstants.scale.max
        layerAnimation.duration = AnimationConstants.timing.durationInSeconds
        layerAnimation.repeatCount = AnimationConstants.timing.repeatCount

        layerAnimation.isAdditive = false
        layerAnimation.fillMode = .forwards
        layerAnimation.isRemovedOnCompletion = true
        layerAnimation.autoreverses = true

        scanFocusImageView.layer.add(layerAnimation, forKey: "pulsateAnimation")
    }

    enum AnimationConstants {
        enum scale {
            static let min = 1
            static let max = 1.05
        }

        enum timing {
            static let durationInSeconds: CFTimeInterval = 1
            static let repeatCount: Float = .infinity
        }
    }
}
