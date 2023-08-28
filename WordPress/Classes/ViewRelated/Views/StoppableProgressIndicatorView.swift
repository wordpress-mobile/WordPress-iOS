import Foundation
import UIKit

private let rotationAnimationKey = "rotation"

@objcMembers class StoppableProgressIndicatorView: UIView {

    private let progressIndicator: CAShapeLayer
    let stopButton: UIControl

    var hidesWhenStopped: Bool = true {
        didSet {
            if hidesWhenStopped, !isAnimating {
                isHidden = true
            }
        }
    }

    var mayStop: Bool {
        get { !stopButton.isHidden }
        set { stopButton.isHidden = !newValue }
    }

    var isAnimating: Bool {
        progressIndicator.animation(forKey: rotationAnimationKey) != nil
    }

    private var resumeAnimation: Bool = true

    override init(frame: CGRect) {
        stopButton = UIControl(frame: .zero)
        progressIndicator = CAShapeLayer()
        progressIndicator.isHidden = true
        progressIndicator.lineWidth = 2
        super.init(frame: frame)

        layer.addSublayer(progressIndicator)
        addSubview(stopButton)
        stopButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stopButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            stopButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            stopButton.widthAnchor.constraint(equalTo: stopButton.heightAnchor),
            stopButton.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.3),
        ])

        updateAppearance()
        NotificationCenter.default.addObserver(self, selector: #selector(enterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()
        updateAppearance()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        progressIndicator.frame = layer.bounds
        resetIndicatorShape()
    }

    func startAnimating() {
        if isAnimating {
            return
        }

        isHidden = false
        progressIndicator.isHidden = false
        resumeAnimation = true

        let rotation = CABasicAnimation(keyPath: "transform.rotation")
        rotation.toValue = CGFloat.pi * 2
        rotation.duration = 1
        rotation.repeatCount = Float.infinity
        progressIndicator.add(rotation, forKey: rotationAnimationKey)
    }

    func stopAnimating() {
        resumeAnimation = false
        progressIndicator.removeAnimation(forKey: rotationAnimationKey)
        progressIndicator.isHidden = true

        if hidesWhenStopped {
            isHidden = true
        }
    }

    func enterForeground() {
        if resumeAnimation {
            startAnimating()
        }
    }

    private func resetIndicatorShape() {
        let bounds = progressIndicator.bounds
        let path = CGMutablePath()
        path.addArc(
            center: CGPoint(x: bounds.midX, y: bounds.midY),
            radius: (bounds.width - progressIndicator.lineWidth) / 2,
            startAngle: -CGFloat.pi / 2,
            endAngle: -CGFloat.pi / 2 + CGFloat.pi * 1.8,
            clockwise: false
        )
        progressIndicator.path = path
    }

    private func updateAppearance() {
        stopButton.backgroundColor = tintColor
        progressIndicator.strokeColor = tintColor.cgColor
        progressIndicator.fillColor = nil
    }

}
