import UIKit

/// A simple UIView subclass that displays a gradient.
/// Gradient colors and positioning can be set in code via properties
/// or in Interface Builder.
///
@IBDesignable
public class GradientView: UIView {
    private let gradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        layer.addSublayer(gradientLayer)

        updateGradientFrame()
        updateGradientColors()
        updateGradientPoints()
    }

    override public func layoutSubviews() {
        super.layoutSubviews()

        updateGradientFrame()
    }

    // MARK: - Inspectable appearance properties

    @IBInspectable
    public var fromColor: UIColor = Defaults.whiteColor {
        didSet {
            updateGradientColors()
        }
    }

    @IBInspectable
    public var toColor: UIColor =  Defaults.clearColor {
        didSet {
            updateGradientColors()
        }
    }

    /// Matches CAGradientLayer's startPoint
    @IBInspectable
    public var startPoint: CGPoint = Defaults.startPoint {
        didSet {
            updateGradientPoints()
        }
    }

    /// Matches CAGradientLayer's endPoint
    @IBInspectable
    public var endPoint: CGPoint = Defaults.endPoint {
        didSet {
            updateGradientPoints()
        }
    }

    private func updateGradientFrame() {
        gradientLayer.frame = bounds
    }

    private func updateGradientColors() {
        gradientLayer.colors = [fromColor.cgColor, toColor.cgColor]
    }

    private func updateGradientPoints() {
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
    }

    private enum Defaults {
        // We need to use white and alpha to ensure we use the same
        // colorspace when fading to a clear color.
        static let whiteColor = UIColor(white: 1.0, alpha: 1.0)
        static let clearColor = UIColor(white: 1.0, alpha: 0.0)
        static let startPoint = CGPoint(x: 0.5, y: 0.0)
        static let endPoint = CGPoint(x: 0.5, y: 1.0)
    }
}
