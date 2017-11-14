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
    }

    private enum Animations {
        static let rotationAmount = Float.pi * 2.0
        static let rotationDuration: TimeInterval = 1.2
        static let strokeDuration: TimeInterval = 0.8
        static let strokeSlowdownPoint: Float = 0.8
        static let strokeBeginTime: TimeInterval = 0.5
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
        let strokeEnd = CAKeyframeAnimation(keyPath: "strokeEnd")
        strokeEnd.duration = Animations.strokeDuration
        strokeEnd.values = [0.0, 1.0]

        let strokeStart = CAKeyframeAnimation(keyPath: "strokeStart")
        strokeStart.duration = Animations.strokeDuration
        strokeStart.values = [0.0, Animations.strokeSlowdownPoint, 1.0]
        strokeStart.beginTime = Animations.strokeBeginTime

        let group = CAAnimationGroup()
        group.animations = [strokeEnd, strokeStart]
        group.duration = Animations.strokeDuration + strokeStart.beginTime
        group.repeatCount = Float.infinity

        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.fromValue = 0
        animation.toValue = Animations.rotationAmount
        animation.duration = Animations.rotationDuration
        animation.repeatCount = Float.infinity

        progressLayer.add(animation, forKey: "rotation")
        progressLayer.add(group, forKey: "rotationGroup")
    }

    func stopAnimating() {
        progressLayer.removeAllAnimations()
    }
}
