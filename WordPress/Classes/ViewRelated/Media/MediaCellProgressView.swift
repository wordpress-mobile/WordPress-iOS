import UIKit
import MRProgress
import WordPressShared

/// Progress view displayed in cells in the media library to indicate that an
/// asset is currently being processed, uploaded, or has failed to upload.
///
class MediaCellProgressView: UIView {
    fileprivate let progressIndicator = ProgressIndicatorView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addProgressIndicator()

        backgroundColor = WPStyleGuide.darkGrey()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addProgressIndicator() {
        addSubview(progressIndicator)
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            progressIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            progressIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
    }
}

/// Small circular progress indicator view, currently just used in media cells
/// during the processing / upload flow.
///
private class ProgressIndicatorView: UIView {
    private let progressLayer = CAShapeLayer()

    private enum Appearance {
        static let defaultSize: CGFloat = 25.0
        static let lineWidth: CGFloat = 3.0
        static let lineColor: UIColor = .white
        static let strokeEnd: CGFloat = 0.85
    }

    private enum Animations {
        static let rotationAmount = Float.pi * 2.0
        static let duration: TimeInterval = 1.2
    }

    convenience init() {
        self.init(frame: CGRect(x: 0, y: 0, width: Appearance.defaultSize, height: Appearance.defaultSize))
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        progressLayer.frame = bounds
        layer.addSublayer(progressLayer)

        progressLayer.lineWidth = Appearance.lineWidth
        progressLayer.strokeColor = Appearance.lineColor.cgColor
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: bounds.width / 2.0).cgPath
        progressLayer.strokeEnd = Appearance.strokeEnd
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        return bounds.size
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()

        startAnimating()
    }

    func startAnimating() {
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.fromValue = 0
        animation.toValue = Animations.rotationAmount
        animation.duration = Animations.duration
        animation.repeatCount = Float.infinity

        progressLayer.add(animation, forKey: "rotation")
    }

    func stopAnimating() {
        progressLayer.removeAllAnimations()
    }
}
