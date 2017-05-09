import UIKit

/// Simulates a top down shadow with a gradient
///
class ShadowView: UIView {
    let gradient = CAGradientLayer()

    override var tintColor: UIColor! {
        didSet {
            updateGradientColors()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addGradient()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addGradient()
    }

    func addGradient() {
        clipsToBounds = false
        layer.addSublayer(gradient)
        updateGradientColors()
    }

    func updateGradientColors() {
        let startColor = tintColor.withAlphaComponent(0.3)
        let endColor = tintColor.withAlphaComponent(0)
        gradient.colors = [startColor.cgColor, endColor.cgColor]
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
    }
}
