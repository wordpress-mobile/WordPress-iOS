import UIKit
import Gridicons
import WordPressShared

/// Progress view displayed in cells in the media library to indicate that an
/// asset is currently being processed, uploaded, or has failed to upload.
///
class CircularProgressView: UIView {

    enum State: Equatable {
        case stopped
        case retry
        case indeterminate
        case progress(Double)
        case error

        static func ==(lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.stopped, .stopped): return true
            case (.retry, .retry): return true
            case (.indeterminate, .indeterminate): return true
            case let (.progress(l), .progress(r)): return l == r
            case (.error, .error): return true
            default: return false
            }
        }
    }

    @objc(CircularProgressViewStyle)
    enum Style: Int {
        case wordPressBlue
        case white
        case mediaCell

        fileprivate var appearance: Appearance {
            switch self {
            case .wordPressBlue:
                return Appearance(
                    progressIndicatorAppearance: ProgressIndicatorView.Appearance(lineColor: WPStyleGuide.mediumBlue()),
                    backgroundColor: .clear,
                    accessoryViewTintColor: WPStyleGuide.darkGrey(),
                    accessoryViewBackgroundColor: WPStyleGuide.lightGrey())
            case .mediaCell:
                return Appearance(
                    progressIndicatorAppearance: ProgressIndicatorView.Appearance(lineColor: .white),
                    backgroundColor: WPStyleGuide.darkGrey(),
                    accessoryViewTintColor: .white,
                    accessoryViewBackgroundColor: .clear)
            case .white:
                return Appearance(
                    progressIndicatorAppearance: ProgressIndicatorView.Appearance(lineColor: .white),
                    backgroundColor: .clear,
                    accessoryViewTintColor: .white,
                    accessoryViewBackgroundColor: WPStyleGuide.lightGrey())
            }
        }
    }

    fileprivate struct Appearance {
        let progressIndicatorAppearance: ProgressIndicatorView.Appearance
        let backgroundColor: UIColor
        let accessoryViewTintColor: UIColor
        let accessoryViewBackgroundColor: UIColor
    }

    // MARK: - public fields

    let retryView = RetryView()
    var errorTintColor = UIColor.white

    var state: State = .stopped {
        didSet {
            refreshState()
        }
    }

    // MARK: - private fields

    private let progressIndicator: ProgressIndicatorView
    private var errorView: UIView?
    private var style: Style

    // MARK: - inits

    @objc init(style: Style) {
        self.style = style
        progressIndicator = ProgressIndicatorView(appearance: style.appearance.progressIndicatorAppearance)
        super.init(frame: .zero)
        setup()
    }

    override init(frame: CGRect) {
        self.style = Style.mediaCell
        progressIndicator = ProgressIndicatorView(appearance: style.appearance.progressIndicatorAppearance)
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIView overrides

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

    // MARK: - public methods

    func addErrorView(_ view: UIView) {
        errorView?.removeFromSuperview()
        errorView = view
        addSubview(view)
        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: centerXAnchor),
            view.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
        view.isHidden = true
    }

    @objc func showError() {
        state = .error
    }

    // MARK: - private methods

    private func refreshState() {
        switch state {
        case .stopped:
            progressIndicator.state = .stopped
            retryView.isHidden = true
            errorView?.isHidden = true
        case .retry:
            progressIndicator.state = .stopped
            retryView.isHidden = false
            errorView?.isHidden = true
        case .indeterminate:
            progressIndicator.state = .indeterminate
            retryView.isHidden = true
            errorView?.isHidden = true
        case .progress:
            progressIndicator.state = state
            retryView.isHidden = true
            errorView?.isHidden = true
        case .error:
            progressIndicator.state = .stopped
            retryView.isHidden = true
            errorView?.isHidden = false
        }
    }

    fileprivate func setup() {
        addProgressIndicator()
        addRetryViews()
        backgroundColor = style.appearance.backgroundColor
    }

    fileprivate func setRetryContainerDimmed(_ dimmed: Bool) {
        retryView.alpha = (dimmed) ? 0.5 : 1.0
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
        addSubview(retryView)
        NSLayoutConstraint.activate([
            retryView.centerYAnchor.constraint(equalTo: centerYAnchor),
            retryView.centerXAnchor.constraint(equalTo: centerXAnchor),
            ])

        retryView.isHidden = true
    }
}

/// View used to show in the `retry` progress state
///
final class RetryView: UIView {

    enum Appearance {
        static let horizontalPadding: CGFloat = 4.0
        static let verticalSpacing: CGFloat = 3.0
        static let fontSize: CGFloat = 14.0
    }

    override var tintColor: UIColor! {
        didSet {
            label.textColor = tintColor
            imageView.tintColor = tintColor
        }
    }

    let imageView = UIImageView(image: Gridicon.iconOfType(.refresh))

    let label: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: Appearance.fontSize)
        label.textAlignment = .center
        label.text = NSLocalizedString("Retry", comment: "Retry. Verb – retry a failed media upload.")
        label.numberOfLines = 2
        return label
    }()


    private let container: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = Appearance.verticalSpacing
        stackView.distribution = .fillProportionally

        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layout()
    }

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        layout()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        layout()
    }

    private func layout() {
        container.addArrangedSubview(imageView)
        container.addArrangedSubview(label)
        addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor, constant: RetryView.Appearance.horizontalPadding),
            container.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -RetryView.Appearance.horizontalPadding)
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

    struct Appearance {
        let defaultSize: CGFloat
        let lineWidth: CGFloat
        let lineColor: UIColor
        let trackColor: UIColor

        init(size: CGFloat = 25.0,
             lineWidth: CGFloat = 3.0,
             lineColor: UIColor = .white,
             trackColor: UIColor = .gray) {

            defaultSize = size
            self.lineWidth = lineWidth
            self.lineColor = lineColor
            self.trackColor = trackColor
        }
    }

    private enum Animations {
        static let rotationAmount = Float.pi * 2.0
        static let rotationDuration: TimeInterval = 0.84
        static let strokeDuration: TimeInterval = 0.56
        static let strokeSlowdownPoint: Float = 0.8
        static let strokeBeginTime: TimeInterval = 0.35
    }

    var state: CircularProgressView.State = .stopped {
        didSet {
            stateDidChange()
        }
    }

    let appearance: Appearance

    private var isAnimating = false

    init(appearance: Appearance = Appearance()) {
        self.appearance = appearance
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
