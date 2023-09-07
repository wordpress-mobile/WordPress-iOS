import UIKit

protocol Spotlightable: UIView {
    var spotlight: QuickStartSpotlightView? { get }
    var shouldShowSpotlight: Bool { get set }
}

class SpotlightableButton: UIButton, Spotlightable {

    enum SpotlightHorizontalPosition {
        case leading
        case trailing

        var defaultOffset: UIOffset {
            switch self {
            case .leading:
                return Constants.leadingDefaultOffset
            case .trailing:
                return Constants.trailingDefaultOffset
            }
        }
    }

    var spotlight: QuickStartSpotlightView?
    var originalTitle: String?
    var spotlightHorizontalPosition: SpotlightHorizontalPosition = .leading

    private var spotlightHorizontalAnchor: NSLayoutXAxisAnchor {
        switch spotlightHorizontalPosition {
        case .leading:
            return leadingAnchor
        case .trailing:
            return trailingAnchor
        }
    }

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
        setTitle(" ", for: .normal) // Non-empty title so that it retains its height
        activityIndicator.startAnimating()
    }

    func stopLoading() {
        activityIndicator.stopAnimating()
        setTitle(originalTitle, for: .normal)
    }

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
            activityIndicator.leadingAnchor.constraint(equalTo: leadingAnchor)
        ])

        return activityIndicator
    }()

    private func setupSpotlight() {
        spotlight?.removeFromSuperview()

        let spotlightView = QuickStartSpotlightView()
        addSubview(spotlightView)
        spotlightView.translatesAutoresizingMaskIntoConstraints = false

        let spotlightXConstraint = spotlightView.centerXAnchor.constraint(equalTo: spotlightHorizontalAnchor)
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
        let offset = spotlightOffset ?? spotlightHorizontalPosition.defaultOffset

        spotlightXConstraint?.constant = offset.horizontal
        spotlightYConstraint?.constant = offset.vertical
    }

    private enum Constants {
        static let spotlightDiameter: CGFloat = 40
        static let leadingDefaultOffset = UIOffset(horizontal: -10, vertical: 0)
        static let trailingDefaultOffset = UIOffset(horizontal: 10, vertical: 0)
    }
}
