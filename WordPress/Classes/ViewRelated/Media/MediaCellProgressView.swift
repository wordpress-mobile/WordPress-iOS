import UIKit
import WordPressShared

/// Progress view displayed in cells in the media library to indicate that an
/// asset is currently being processed, uploaded, or has failed to upload.
///
class MediaCellProgressView: UIView {
    let progressIndicator = ProgressIndicatorView()

    override var isHidden: Bool {
        didSet {
            if isHidden {
                progressIndicator.state = .stopped
            }
        }
    }

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
class ProgressIndicatorView: UIView {
    private let indeterminateLayer = CAShapeLayer()
    private let progressTrackLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()

    private enum Appearance {
        static let defaultSize: CGFloat = 25.0
        static let lineWidth: CGFloat = 3.0
        static let lineColor: UIColor = .white
        static let trackColor: UIColor = WPStyleGuide.grey()
    }

    private enum Animations {
        static let rotationAmount = Float.pi * 2.0
        static let rotationDuration: TimeInterval = 1.2
        static let strokeDuration: TimeInterval = 0.8
        static let strokeSlowdownPoint: Float = 0.8
        static let strokeBeginTime: TimeInterval = 0.5
    }

    enum State: Equatable {
        case stopped
        case indeterminate
        case progress(Double)

        static func ==(lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.stopped, .stopped): return true
            case (.indeterminate, .indeterminate): return true
            case let (.progress(l), .progress(r)): return l == r
            default: return false
            }
        }
    }

    var state: State = .stopped {
        didSet {
            stateDidChange()
        }
    }

    private var isAnimating = false

    convenience init() {
        self.init(frame: CGRect(x: 0, y: 0, width: Appearance.defaultSize, height: Appearance.defaultSize))
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        configureLayer(indeterminateLayer)
        layer.addSublayer(indeterminateLayer)

        configureLayer(progressTrackLayer)
        progressTrackLayer.strokeColor = Appearance.trackColor.cgColor
        layer.addSublayer(progressTrackLayer)

        configureLayer(progressLayer)
        progressTrackLayer.addSublayer(progressLayer)
        progressLayer.isHidden = false
        progressLayer.strokeEnd = 0.0
    }

    func configureLayer(_ layer: CAShapeLayer) {
        layer.frame = bounds

        layer.lineWidth = Appearance.lineWidth
        layer.strokeColor = Appearance.lineColor.cgColor
        layer.fillColor = UIColor.clear.cgColor
        layer.path = UIBezierPath(roundedRect: bounds, cornerRadius: bounds.width / 2.0).cgPath

        layer.isHidden = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        return bounds.size
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()

        if state == .indeterminate {
            startAnimating()
        }
    }

    private func stateDidChange() {
        switch state {
        case .stopped:
            stopAnimating()
            updateProgressLayer(with: 0.0, hidden: true)
        case .indeterminate:
            startAnimating()
        case .progress(let progress):
            stopAnimating()
            updateProgressLayer(with: progress)
            break
        }
    }

    func updateProgressLayer(with progress: Double, hidden: Bool = false) {
        progressLayer.strokeEnd = CGFloat(progress)
        progressTrackLayer.isHidden = hidden
    }

    @objc func startAnimating() {
        guard !isAnimating && window != nil else {
            return
        }

        isAnimating = true

        progressLayer.strokeEnd = 0
        progressTrackLayer.isHidden = true
        indeterminateLayer.isHidden = false

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

        indeterminateLayer.add(animation, forKey: "rotation")
        indeterminateLayer.add(group, forKey: "rotationGroup")
    }

    @objc func stopAnimating() {
        guard isAnimating else {
            return
        }

        indeterminateLayer.isHidden = true
        indeterminateLayer.removeAllAnimations()

        isAnimating = false
    }
}
