import UIKit
import CoreMotion

class JetpackPrologueViewController: UIViewController {
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var titleLabel: UILabel!

    var starFieldView: StarFieldView = {
        let config = StarFieldViewConfig(particleImage: JetpackPrologueStyleGuide.Stars.particleImage,
                                         starColors: JetpackPrologueStyleGuide.Stars.colors)
        let view = StarFieldView(with: config)
        view.layer.masksToBounds = true
        return view
    }()

    private let motion: CMMotionManager? = {
        let motion = CMMotionManager()
        motion.deviceMotionUpdateInterval = Constants.deviceMotionUpdateInterval
        return motion
    }()

    private lazy var jetpackAnimatedView: UIView = {
        let jetpackAnimatedView = InfiniteScrollerView { JetpackLandingScreenView() }
        jetpackAnimatedView.scrollerDelegate = self
        jetpackAnimatedView.translatesAutoresizingMaskIntoConstraints = false
        return jetpackAnimatedView
    }()

    private lazy var logoImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "jetpack-logo"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var gradientLayer: CALayer = {
        makeGradientLayer()
    }()

    private lazy var logoWidthConstraint: NSLayoutConstraint = {
        let width = Constants.logoWidth(for: traitCollection.horizontalSizeClass)
        return logoImageView.widthAnchor.constraint(equalToConstant: width)
    }()

    private func makeGradientLayer() -> CAGradientLayer {
        let gradientLayer = CAGradientLayer()

        // Start color is the background color with no alpha because if we use clear it will fade to black
        // instead of just disappearing
        let startColor = JetpackPrologueStyleGuide.gradientColor.withAlphaComponent(0)
        let midTopColor = JetpackPrologueStyleGuide.gradientColor.withAlphaComponent(0.9)
        let midBottomColor = JetpackPrologueStyleGuide.gradientColor.withAlphaComponent(0.2)
        let endColor = JetpackPrologueStyleGuide.gradientColor

        gradientLayer.colors = [endColor.cgColor, midTopColor.cgColor, midBottomColor.cgColor, startColor.cgColor]
        gradientLayer.locations = [0.0, 0.4, 0.6, 1.0]

        return gradientLayer
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = JetpackPrologueStyleGuide.backgroundColor

        loadNewPrologueView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let motion = motion, motion.isGyroAvailable {
            motion.startDeviceMotionUpdates()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        motion?.stopDeviceMotionUpdates()
    }

    private func loadNewPrologueView() {
        // hide old view unused elements
        stackView.isHidden = true
        titleLabel.isHidden = true

        // animated view

        view.addSubview(jetpackAnimatedView)
        view.pinSubviewToAllEdges(jetpackAnimatedView)
        // Jetpack logo with parallax
        view.addSubview(logoImageView)
        addParallax(to: logoImageView)
        // linear gradient above the animated view
        view.layer.insertSublayer(gradientLayer, above: jetpackAnimatedView.layer)
        // constraints
        NSLayoutConstraint.activate([
            logoWidthConstraint,
            logoImageView.heightAnchor.constraint(equalTo: logoImageView.widthAnchor),
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 68)
        ])
    }

    private func loadOldPrologueView() {
        view.addSubview(starFieldView)
        view.layer.addSublayer(gradientLayer)
        titleLabel.text = NSLocalizedString("Site security and performance\nfrom your pocket", comment: "Prologue title label, the \n force splits it into 2 lines.")
        titleLabel.textColor = JetpackPrologueStyleGuide.Title.textColor
        titleLabel.font = JetpackPrologueStyleGuide.Title.font
        // Move the layers to appear below everything else
        starFieldView.layer.zPosition = Constants.starLayerPosition
        gradientLayer.zPosition = Constants.gradientLayerPosition
        addParallax(to: stackView)
        updateLabel(for: traitCollection)
    }

    func updateLabel(for traitCollection: UITraitCollection) {
        let contentSize = traitCollection.preferredContentSizeCategory

        // Hide the title label if the accessibility larger font size option is enabled
        // this prevents the label from becoming truncated or clipped
        titleLabel.isHidden = contentSize.isAccessibilityCategory
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        logoWidthConstraint.constant = Constants.logoWidth(for: traitCollection.horizontalSizeClass)

        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else {
            updateLabel(for: traitCollection)
            return
        }
        gradientLayer.removeFromSuperlayer()
        gradientLayer = makeGradientLayer()
        view.layer.insertSublayer(gradientLayer, above: jetpackAnimatedView.layer)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }

    /// Slightly moves the logo / text when moving the device
    private func addParallax(to view: UIView) {
        let amount = Constants.parallaxAmount

        let horizontal = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        horizontal.minimumRelativeValue = -amount
        horizontal.maximumRelativeValue = amount

        let vertical = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
        vertical.minimumRelativeValue = -amount
        vertical.maximumRelativeValue = amount

        let group = UIMotionEffectGroup()
        group.motionEffects = [horizontal, vertical]

        view.addMotionEffect(group)
    }

    private struct Constants {
        static let parallaxAmount: CGFloat = 30
        static let starLayerPosition: CGFloat = -100
        static let gradientLayerPosition: CGFloat = -99

        /// New landing screen

        /// Rate that the device is polled for motion updates
        static let deviceMotionUpdateInterval: Double = 1 / 10
        /// Angle to use for the scroll rate when a device can't supply motion data
        static let defaultAngleDegrees: Double = 30.0
        /// Uniform multiplier used to tweak the rate generated from an angle
        static let angleRateMultiplier: CGFloat = 1.3
        /// Returns the Jetpack logo width depending on the given size class
        static func logoWidth(for sizeClass: UIUserInterfaceSizeClass) -> CGFloat {
            return sizeClass == .compact ? 68 : 78
        }
    }
}

extension JetpackPrologueViewController: InfiniteScrollerViewDelegate {
    /// Provides rate in points per second for a given angle in degrees.
    ///
    /// - Returns: Points per second.
    private func rateForAngle(angle: Double) -> CGFloat {
        return -angle * Self.Constants.angleRateMultiplier
    }

    /// Returns the angle in degrees of the device independently of the view's orientation.
    ///
    /// Assuming the view is in the normal, upright position when displayed on the device:
    /// - +90 degrees is perpendicular to the ground, facing the user.
    /// - 0 degrees is parallel to the ground (flat on a surface).
    /// - -90 degrees is perpendicular to the ground and upside down, facing away from the user.
    ///
    /// - Returns: Angle in degrees, or `nil` if the device didn't supply motion data.
    private func angleForDeviceOrientation() -> Double? {
        guard let attitude = motion?.deviceMotion?.attitude else {
            return nil
        }

        let angleRad: Double

        switch UIApplication.shared.currentStatusBarOrientation {
        case .portrait:
            angleRad = attitude.pitch
        case .portraitUpsideDown:
            angleRad = -attitude.pitch
        case .landscapeLeft:
            angleRad = attitude.roll
        case .landscapeRight:
            angleRad = -attitude.roll
        default:
            angleRad = 0
        }

        /// Convert radians to degrees
        return angleRad * 180 / .pi
    }

    func rate(for infiniteScrollerView: InfiniteScrollerView) -> CGFloat {
        let deviceAngle = angleForDeviceOrientation() ?? Self.Constants.defaultAngleDegrees
        return rateForAngle(angle: deviceAngle)
    }
}
