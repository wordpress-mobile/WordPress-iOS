import UIKit
import Gridicons
import WordPressShared

/// Progress view displayed in cells in the media library to indicate that an
/// asset is currently being processed, uploaded, or has failed to upload.
///
class MediaCellProgressView: UIView {
    let progressIndicator: ProgressIndicatorView

    private let retryContainer = UIStackView()

    @objc enum LoaderStyle: Int {
        case white
        case gray
        case black

        var appearance: ProgressIndicatorView.Appearance {
            switch self {
            case .white:
                return ProgressIndicatorView.Appearance(lineColor: WPStyleGuide.mediumBlue())
            case .gray:
                return ProgressIndicatorView.Appearance(lineColor: .white)
            case .black:
                return ProgressIndicatorView.Appearance(lineColor: .white)
            }
        }

        var backgroundColor: UIColor {
            switch self {
            case .white:
                return .clear
            case .gray:
                return WPStyleGuide.darkGrey()
            case .black:
                return .black
            }
        }
    }

    enum State: Equatable {
        case stopped
        case retry
        case indeterminate
        case progress(Double)

        static func ==(lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.stopped, .stopped): return true
            case (.retry, .retry): return true
            case (.indeterminate, .indeterminate): return true
            case let (.progress(l), .progress(r)): return l == r
            default: return false
            }
        }
    }

    var state: State = .stopped {
        didSet {
            switch state {
            case .stopped:
                progressIndicator.state = .stopped
                retryContainer.isHidden = true
            case .retry:
                progressIndicator.state = .stopped
                retryContainer.isHidden = false
            case .indeterminate:
                progressIndicator.state = .indeterminate
                retryContainer.isHidden = true
            case .progress:
                progressIndicator.state = state
                retryContainer.isHidden = true
            }
        }
    }

    var whiteStyle: ProgressIndicatorView.Appearance {
        return ProgressIndicatorView.Appearance(lineColor: WPStyleGuide.mediumBlue())
    }

    var grayStyle: ProgressIndicatorView.Appearance {
        return ProgressIndicatorView.Appearance(lineColor: .white)
    }

    var blackStyle: ProgressIndicatorView.Appearance {
        return ProgressIndicatorView.Appearance(lineColor: .white)
    }

    @objc init(style: LoaderStyle = .white, animationSpeed: Float = 1) {
        progressIndicator = ProgressIndicatorView(appearance: style.appearance, animationSpeed: animationSpeed)
        super.init(frame: .zero)
        setup(style)
    }

    override init(frame: CGRect) {
        let style = LoaderStyle.gray
        progressIndicator = ProgressIndicatorView(appearance: style.appearance)
        super.init(frame: frame)
        setup(style)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func setup(_ style: LoaderStyle) {
        addProgressIndicator()
        addRetryViews()

        backgroundColor = style.backgroundColor
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        setRetryContainerDimmed(true)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        setRetryContainerDimmed(false)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        setRetryContainerDimmed(false)
    }

    fileprivate func setRetryContainerDimmed(_ dimmed: Bool) {
        retryContainer.alpha = (dimmed) ? 0.5 : 1.0
    }

    private func addProgressIndicator() {
        addSubview(progressIndicator)
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            progressIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            progressIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
    }

    private func addRetryViews() {
        retryContainer.axis = .vertical
        retryContainer.alignment = .center
        retryContainer.spacing = RetryContainerAppearance.verticalSpacing
        retryContainer.distribution = .fillProportionally

        let retryIconView = UIImageView(image: Gridicon.iconOfType(.refresh))
        retryIconView.tintColor = .white
        retryContainer.addArrangedSubview(retryIconView)

        let retryLabel = UILabel()
        retryLabel.font = UIFont.systemFont(ofSize: RetryContainerAppearance.fontSize)
        retryLabel.textColor = .white
        retryLabel.textAlignment = .center
        retryLabel.text = NSLocalizedString("Retry", comment: "Retry. Verb – retry a failed media upload.")
        retryLabel.numberOfLines = 2
        retryContainer.addArrangedSubview(retryLabel)

        addSubview(retryContainer)
        retryContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            retryContainer.centerYAnchor.constraint(equalTo: centerYAnchor),
            retryContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: RetryContainerAppearance.horizontalPadding),
            retryContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -RetryContainerAppearance.horizontalPadding)
            ])

        retryContainer.isHidden = true
    }

    enum RetryContainerAppearance {
        static let horizontalPadding: CGFloat = 4.0
        static let verticalSpacing: CGFloat = 3.0
        static let fontSize: CGFloat = 14.0
    }
}

/// Small circular progress indicator view, currently just used in media cells
/// during the processing / upload flow.
///
class ProgressIndicatorView: UIView {
    private let indeterminateLayer = CAShapeLayer()
    private let progressTrackLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()

    struct Appearance {
        let defaultSize: CGFloat
        let lineWidth: CGFloat
        let lineColor: UIColor
        let trackColor: UIColor

        init(size: CGFloat = 25.0,
             lineWidth: CGFloat = 3.0,
             lineColor: UIColor = WPStyleGuide.mediumBlue(),
             trackColor: UIColor = WPStyleGuide.grey()) {

            defaultSize = size
            self.lineWidth = lineWidth
            self.lineColor = lineColor
            self.trackColor = trackColor
        }
    }

    private struct Animations {
        let speed: Float
        let rotationAmount = Float.pi * 2.0
        lazy var rotationDuration: TimeInterval = 1.2 / TimeInterval(speed)
        lazy var strokeDuration: TimeInterval = 0.8 / TimeInterval(speed)
        let strokeSlowdownPoint: Float = 0.8
        lazy var strokeBeginTime: TimeInterval = 0.5 / TimeInterval(speed)

        init(speed: Float) {
            self.speed = speed
        }
    }

    var state: MediaCellProgressView.State = .stopped {
        didSet {
            stateDidChange()
        }
    }

    private let appearance: Appearance
    private var animations: Animations

    private var isAnimating = false

    init(appearance: Appearance = Appearance(), animationSpeed: Float = 1) {
        self.appearance = appearance
        self.animations = Animations(speed: animationSpeed)
        super.init(frame: CGRect(x: 0, y: 0, width: appearance.defaultSize, height: appearance.defaultSize))
        setup()
    }

    private func setup () {
        configureLayer(indeterminateLayer)
        layer.addSublayer(indeterminateLayer)

        configureLayer(progressTrackLayer)
        progressTrackLayer.strokeColor = appearance.trackColor.cgColor
        layer.addSublayer(progressTrackLayer)

        configureLayer(progressLayer)
        progressTrackLayer.addSublayer(progressLayer)
        progressLayer.isHidden = false
        progressLayer.strokeEnd = 0.0
    }

    func configureLayer(_ layer: CAShapeLayer) {
        layer.frame = bounds

        layer.lineWidth = appearance.lineWidth
        layer.strokeColor = appearance.lineColor.cgColor
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
        default: break
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
        strokeEnd.duration = animations.strokeDuration
        strokeEnd.values = [0.0, 1.0]

        let strokeStart = CAKeyframeAnimation(keyPath: "strokeStart")
        strokeStart.duration = animations.strokeDuration
        strokeStart.values = [0.0, animations.strokeSlowdownPoint, 1.0]
        strokeStart.beginTime = animations.strokeBeginTime

        let group = CAAnimationGroup()
        group.animations = [strokeEnd, strokeStart]
        group.duration = animations.strokeDuration + strokeStart.beginTime
        group.repeatCount = Float.infinity

        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.fromValue = 0
        animation.toValue = animations.rotationAmount
        animation.duration = animations.rotationDuration
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
