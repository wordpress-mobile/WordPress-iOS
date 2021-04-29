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

    var gradientLayer: CALayer = {
        let gradientLayer = CAGradientLayer()

        // Start color is the background color with no alpha because if we use clear it will fade to black
        // instead of just disappearing
        let startColor = JetpackPrologueStyleGuide.backgroundColor.withAlphaComponent(0)
        let endColor = JetpackPrologueStyleGuide.backgroundColor

        gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
        gradientLayer.locations = [0.0, 0.9]

        return gradientLayer
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = JetpackPrologueStyleGuide.backgroundColor
        view.addSubview(starFieldView)
        view.layer.addSublayer(gradientLayer)

        titleLabel.text = NSLocalizedString("Site security and performance\nfrom your pocket", comment: "Prologue title label, the \n force splits it into 2 lines.")
        titleLabel.font = JetpackPrologueStyleGuide.Title.font
        titleLabel.textColor = JetpackPrologueStyleGuide.Title.textColor

        // Move the layers to appear below everything else
        starFieldView.layer.zPosition = Constants.starLayerPosition
        gradientLayer.zPosition = Constants.gradientLayerPosition

        addParallax()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        starFieldView.frame = view.bounds
        gradientLayer.frame = view.bounds
    }

    /// Slightly moves the logo / text when moving the device
    private func addParallax() {
        let amount = Constants.parallaxAmount

        let horizontal = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        horizontal.minimumRelativeValue = -amount
        horizontal.maximumRelativeValue = amount

        let vertical = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
        vertical.minimumRelativeValue = -amount
        vertical.maximumRelativeValue = amount

        let group = UIMotionEffectGroup()
        group.motionEffects = [horizontal, vertical]

        stackView.addMotionEffect(group)
    }

    private struct Constants {
        static let parallaxAmount: CGFloat = 20
        static let starLayerPosition: CGFloat = -100
        static let gradientLayerPosition: CGFloat = -99
    }
}
