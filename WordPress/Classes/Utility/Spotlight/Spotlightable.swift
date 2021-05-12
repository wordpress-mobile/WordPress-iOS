
protocol Spotlightable: UIView {
    var spotlight: QuickStartSpotlightView? { get }
    var shouldShowSpotlight: Bool { get set }
}

class SpotlightableButton: UIButton, Spotlightable {

    var spotlight: QuickStartSpotlightView?
    var originalTitle: String?

    /// If this property is set, the default offset will be overridden.
    ///
    var spotlightOffset: UIOffset?
    private var spotlightXConstraint: NSLayoutConstraint?
    private var spotlightYConstraint: NSLayoutConstraint?

    var shouldShowSpotlight: Bool {
        get {
            spotlight != nil
        }
        set {
            switch newValue {
            case true:
                setupSpotlight()
            case false:
                spotlight?.removeFromSuperview()
                spotlight = nil
            }
        }
    }

    func startLoading() {
        originalTitle = titleLabel?.text
        setTitle("", for: .normal)
        activityIndicator.startAnimating()
    }

    func stopLoading() {
        activityIndicator.stopAnimating()
        setTitle(originalTitle, for: .normal)
    }

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            activityIndicator.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            activityIndicator.centerXAnchor.constraint(equalTo: self.centerXAnchor)
        ])

        return activityIndicator
    }()

    private func setupSpotlight() {
        spotlight?.removeFromSuperview()

        let spotlightView = QuickStartSpotlightView()
        addSubview(spotlightView)
        spotlightView.translatesAutoresizingMaskIntoConstraints = false

        let spotlightXConstraint = spotlightView.centerXAnchor.constraint(equalTo: leadingAnchor)
        let spotlightYConstraint = spotlightView.centerYAnchor.constraint(equalTo: centerYAnchor)

        self.spotlightXConstraint = spotlightXConstraint
        self.spotlightYConstraint = spotlightYConstraint
        updateConstraintConstants()

        let newSpotlightWidth = spotlightView.widthAnchor.constraint(equalToConstant: Constants.spotlightDiameter)
        let newSpotlightHeight = spotlightView.heightAnchor.constraint(equalToConstant: Constants.spotlightDiameter)

        NSLayoutConstraint.activate([
            spotlightXConstraint,
            spotlightYConstraint,
            newSpotlightWidth,
            newSpotlightHeight
        ])

        spotlight = spotlightView
    }

    private func updateConstraintConstants() {
        let offset = spotlightOffset ?? Constants.defaultOffset

        spotlightXConstraint?.constant = offset.horizontal
        spotlightYConstraint?.constant = offset.vertical
    }

    private enum Constants {
        static let spotlightDiameter: CGFloat = 40
        static let defaultOffset = UIOffset(horizontal: -10, vertical: 0)
    }
}
