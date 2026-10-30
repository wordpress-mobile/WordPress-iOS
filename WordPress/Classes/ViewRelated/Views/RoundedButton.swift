import UIKit
import WordPressShared

@IBDesignable
class RoundedButton: UIButton {

    @IBInspectable var isCircular: Bool = false

    @IBInspectable var cornerRadius: CGFloat = 4.0 {
        didSet {
            updateAppearance()
        }
    }

    @IBInspectable var borderWidth: CGFloat = 0.0 {
        didSet {
            updateAppearance()
        }
    }

    @IBInspectable var borderColor: UIColor? = nil {
        didSet {
            updateAppearance()
        }
    }

    @IBInspectable var horizontalEdgeInset: CGFloat = 19.0 {
        didSet {
            updateAppearance()
        }
    }

    @IBInspectable var verticalEdgeInset: CGFloat = 5.0 {
        didSet {
            updateAppearance()
        }
    }

    @IBInspectable var selectedBackgroundColor: UIColor? {
        didSet {
            updateAppearance()
        }
    }

    override var reversesTitleShadowWhenHighlighted: Bool {
        didSet {
            updateAppearance()
        }
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()

        updateAppearance()
    }

    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)

        updateAppearance()
    }

    fileprivate func updateAppearance() {
        var configuration = self.configuration ?? UIButton.Configuration.plain()
        configuration.contentInsets = NSDirectionalEdgeInsets(top: verticalEdgeInset, leading: horizontalEdgeInset, bottom: verticalEdgeInset, trailing: horizontalEdgeInset)
        configuration.baseForegroundColor = tintColor
        configuration.background.backgroundColor = .clear
        self.configuration = configuration

        layer.masksToBounds = true
        if !isCircular {
            layer.cornerRadius = cornerRadius
        }
        layer.borderWidth = borderWidth
        layer.borderColor = borderColor?.cgColor ?? tintColor.cgColor

        configurationUpdateHandler = { button in
            guard let button = button as? RoundedButton else {
                return
            }
            var configuration = button.configuration
            if button.isHighlighted {
                if button.reversesTitleShadowWhenHighlighted {
                    configuration?.baseForegroundColor = button.backgroundColor
                    configuration?.background.backgroundColor = button.tintColor
                } else {
                    configuration?.baseForegroundColor = button.tintColor.withAlphaComponent(0.5)
                    configuration?.background.backgroundColor = button.selectedBackgroundColor ?? button.backgroundColor ?? .clear
                }
            } else {
                configuration?.baseForegroundColor = button.tintColor
                configuration?.background.backgroundColor = .clear
            }
            button.configuration = configuration
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if isCircular {
            layer.cornerRadius = frame.size.width / 2
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            updateFontSizeToMatchSystem()
        }
    }

    public func updateFontSizeToMatchSystem() {
        var configuration = self.configuration ?? UIButton.Configuration.plain()
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = WPStyleGuide.fontForTextStyle(.subheadline)
            return attributes
        }
        self.configuration = configuration
    }
}
