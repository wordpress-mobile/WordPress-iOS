import Foundation
import UIKit


// MARK: - FancyButton
//
open class FancyButton: UIButton {

    /// Style: Primary + Normal State
    ///
    @objc public dynamic var primaryNormalBackgroundColor = Primary.normalBackgroundColor
    @objc public dynamic var primaryNormalBorderColor = Primary.normalBorderColor

    /// Style: Primary + Highlighted State
    ///
    @objc public dynamic var primaryHighlightBackgroundColor = Primary.highlightBackgroundColor
    @objc public dynamic var primaryHighlightBorderColor = Primary.highlightBorderColor

    /// Style: Secondary
    ///
    @objc public dynamic var secondaryNormalBackgroundColor = Secondary.normalBackgroundColor
    @objc public dynamic var secondaryNormalBorderColor = Secondary.normalBorderColor
    @objc public dynamic var secondaryHighlightBackgroundColor = Secondary.highlightBackgroundColor
    @objc public dynamic var secondaryHighlightBorderColor = Secondary.highlightBorderColor

    /// Style: Disabled State
    ///
    @objc public dynamic var disabledBackgroundColor = Disabled.backgroundColor
    @objc public dynamic var disabledBorderColor = Disabled.borderColor

    /// Style: Title!
    ///
    @objc public dynamic var titleFont = Title.defaultFont
    @objc public dynamic var primaryTitleColor = Title.primaryColor
    @objc public dynamic var secondaryTitleColor = Title.secondaryColor
    @objc public dynamic var disabledTitleColor = Title.disabledColor

    /// Insets to be applied over the Contents.
    ///
    @objc public dynamic var contentInsets = Metrics.contentInsets

    /// Indicates if the current instance should be rendered with the "Primary" Style.
    ///
    @IBInspectable var isPrimary: Bool = false {
        didSet {
            configureButton()
        }
    }


    // MARK: - LifeCycle Methods

    open override func awakeFromNib() {
        super.awakeFromNib()
        configureButton()
    }


    /// Configure the appearance of the button.
    ///
    private func configureButton() {
        contentEdgeInsets = contentInsets

        /// Setup: BackgroundImage
        ///
        let normalImage: UIImage
        let highlightedImage: UIImage
        let disabledImage = renderBackgroundImage(fill: disabledBackgroundColor, border: disabledBorderColor)

        if isPrimary {
            normalImage = renderBackgroundImage(fill: primaryNormalBackgroundColor, border: primaryNormalBorderColor)
            highlightedImage = renderBackgroundImage(fill: primaryHighlightBackgroundColor, border: primaryHighlightBorderColor)
        } else {
            normalImage = renderBackgroundImage(fill: secondaryNormalBackgroundColor, border: secondaryNormalBorderColor)
            highlightedImage = renderBackgroundImage(fill: secondaryHighlightBackgroundColor, border: secondaryHighlightBorderColor)
        }

        setBackgroundImage(normalImage, for: .normal)
        setBackgroundImage(highlightedImage, for: .highlighted)
        setBackgroundImage(disabledImage, for: .disabled)

        /// Setup: TitleColor
        ///
        let titleColorNormal = isPrimary ? primaryTitleColor : secondaryTitleColor

        setTitleColor(titleColorNormal, for: .normal)
        setTitleColor(titleColorNormal, for: .highlighted)
        setTitleColor(disabledTitleColor, for: .disabled)

        /// Setup: TitleLabel
        ///
        titleLabel?.font = titleFont
        titleLabel?.adjustsFontForContentSizeCategory = true
        titleLabel?.textAlignment = .center
    }
}


// MARK: - Rendering Methods
//
private extension FancyButton {

    /// Renders the Background Image with the specified Background + Size + Radius + Insets parameters.
    ///
    func renderBackgroundImage(fill: UIColor,
                     border: UIColor,
                     size: CGSize = Metrics.backgroundImageSize,
                     cornerRadius: CGFloat = Metrics.backgroundCornerRadius,
                     capInsets: UIEdgeInsets = Metrics.backgroundCapInsets,
                     shadowOffset: CGSize = Metrics.backgroundShadowOffset,
                     shadowBlurRadius: CGFloat = Metrics.backgroundShadowBlurRadius) -> UIImage {

        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in

            let lineWidthInPixels = 1 / UIScreen.main.scale
            let cgContext = context.cgContext

            /// Apply a 1px inset to the bounds, for our bezier (so that the border doesn't fall outside, capicci?)
            ///
            var bounds = renderer.format.bounds
            bounds.origin.x += lineWidthInPixels
            bounds.origin.y += lineWidthInPixels
            bounds.size.height -= lineWidthInPixels * 2
            bounds.size.width -= lineWidthInPixels * 2

            let path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius)

            /// Draw: Background + Shadow
            cgContext.saveGState()
            cgContext.setShadow(offset: shadowOffset, blur: shadowBlurRadius, color: border.cgColor)
            fill.setFill()

            path.fill()

            cgContext.restoreGState()

            /// Draw: Border!
            border.setStroke()
            path.stroke()
        }

        return image.resizableImage(withCapInsets: capInsets)
    }
}


// MARK: - Nested Types
//
private extension FancyButton {

    /// Style: Primary
    ///
    struct Primary {
        static let normalBackgroundColor = UIColor(red: 0x00/255.0, green: 0xAA/255.0, blue: 0xDC/255.0, alpha: 0xFF/255.0)
        static let normalBorderColor = UIColor(red: 0x00/255.0, green: 0x87/255.0, blue: 0xBE/255.0, alpha: 0xFF/255.0)
        static let highlightBackgroundColor = UIColor(red: 0x00/255.0, green: 0x87/255.0, blue: 0xBE/255.0, alpha: 0xFF/255.0)
        static let highlightBorderColor = normalBorderColor
    }

    /// Style: Secondary
    ///
    struct Secondary {
        static let normalBackgroundColor = UIColor.white
        static let normalBorderColor = UIColor(red: 0xBD/255.0, green: 0xCE/255.0, blue: 0xDA/255.0, alpha: 0xFF/255.0)
        static let highlightBackgroundColor = UIColor(red: 0xBD/255.0, green: 0xCE/255.0, blue: 0xDA/255.0, alpha: 0xFF/255.0)
        static let highlightBorderColor = highlightBackgroundColor
    }

    /// Style: Disabled
    ///
    struct Disabled {
        static let backgroundColor = UIColor.white
        static let borderColor = UIColor(red: 0xE4/255.0, green: 0xEB/255.0, blue: 0xF0/255.0, alpha: 0xFF/255.0)
    }

    /// Style: Title
    ///
    struct Title {
        static let primaryColor = UIColor.white
        static let secondaryColor = UIColor(red: 46/255.0, green: 68/255.0, blue: 83/255.0, alpha: 255.0/255.0)
        static let disabledColor = UIColor(red: 233/255.0, green: 239/255.0, blue: 243/255.0, alpha: 255.0/255.0)
        static let defaultFont = UIFont.systemFont(ofSize: 22)
    }

    /// Default Metrics
    ///
    struct Metrics {
        static let backgroundImageSize = CGSize(width: 44, height: 44)
        static let backgroundCornerRadius = CGFloat(7)
        static let backgroundCapInsets = UIEdgeInsets(top: 18, left: 18, bottom: 18, right: 18)
        static let backgroundShadowOffset = CGSize(width: 0, height: 1)
        static let backgroundShadowBlurRadius = CGFloat(0)
        static let contentInsets = UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20)
    }
}
