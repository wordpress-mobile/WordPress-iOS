
protocol Spotlightable: UIView {
    var spotlight: QuickStartSpotlightView? { get }
    var shouldShowSpotlight: Bool { get set }
}

class SpotlightableButton: UIButton, Spotlightable {

    var spotlight: QuickStartSpotlightView?
    var originalTitle: String?

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

        let newSpotlightCenterX = spotlightView.centerXAnchor.constraint(equalTo: self.leadingAnchor, constant: Constants.leftOffset)
        let newSpotlightCenterY = spotlightView.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        let newSpotlightWidth = spotlightView.widthAnchor.constraint(equalToConstant: Constants.spotlightDiameter)
        let newSpotlightHeight = spotlightView.heightAnchor.constraint(equalToConstant: Constants.spotlightDiameter)

        NSLayoutConstraint.activate([newSpotlightCenterX, newSpotlightCenterY, newSpotlightWidth, newSpotlightHeight])
        spotlight = spotlightView
    }

    private enum Constants {
        static let spotlightDiameter: CGFloat = 40
        static let leftOffset: CGFloat = -10
    }
}
