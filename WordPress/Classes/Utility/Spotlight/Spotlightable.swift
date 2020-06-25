
protocol Spotlightable: UIView {
    var spotlight: QuickStartSpotlightView? { get }
    var shouldShowSpotlight: Bool { get set }
}

class SpotlightableLabel: UILabel, Spotlightable {

    var spotlight: QuickStartSpotlightView?

    init(_ showSpotlight: Bool = false) {

        super.init(frame: .zero)
        guard showSpotlight else {
            return
        }

        setupSpotlight()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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
