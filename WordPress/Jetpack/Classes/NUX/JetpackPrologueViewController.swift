import UIKit

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

    private lazy var jetpackAnimatedView: UIView = {
        let jetpackAnimatedView = InfiniteScrollerView {
            UIView.embedSwiftUIView(JetpackLandingScreenView())
        }

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

    private func makeGradientLayer() -> CAGradientLayer {
        let gradientLayer = CAGradientLayer()

        // Start color is the background color with no alpha because if we use clear it will fade to black
        // instead of just disappearing
        let startColor = JetpackPrologueStyleGuide.gradientColor.withAlphaComponent(0)
        let midTopColor = JetpackPrologueStyleGuide.gradientColor.withAlphaComponent(0.9)
        let midBottomColor = JetpackPrologueStyleGuide.gradientColor.withAlphaComponent(0.2)
        let endColor = JetpackPrologueStyleGuide.gradientColor

        gradientLayer.colors = FeatureFlag.newLandingScreen.enabled ?
        [endColor.cgColor, midTopColor.cgColor, midBottomColor.cgColor, startColor.cgColor] :
        [startColor.cgColor, endColor.cgColor]

        gradientLayer.locations = FeatureFlag.newLandingScreen.enabled ? [0.0, 0.4, 0.6, 1.0] : [0.0, 0.9]

        return gradientLayer
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = JetpackPrologueStyleGuide.backgroundColor

        guard FeatureFlag.newLandingScreen.enabled else {
            loadOldPrologueView()
            return
        }
        loadNewPrologueView()
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
            logoImageView.widthAnchor.constraint(equalToConstant: 72),
            logoImageView.heightAnchor.constraint(equalTo: logoImageView.widthAnchor),
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 72)
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

        guard FeatureFlag.newLandingScreen.enabled,
        previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else {
            updateLabel(for: traitCollection)
            return
        }
        gradientLayer.removeFromSuperlayer()
        gradientLayer = makeGradientLayer()
        view.layer.insertSublayer(gradientLayer, above: jetpackAnimatedView.layer)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !FeatureFlag.newLandingScreen.enabled {
            starFieldView.frame = view.bounds
        }
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
    }
}

extension JetpackPrologueViewController: InfiniteScrollerViewDelegate {
    func rate(for infiniteScrollerView: InfiniteScrollerView) -> CGFloat {
        /// points per second
        return -60
    }
}
