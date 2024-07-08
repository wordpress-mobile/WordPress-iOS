import Foundation
import UIKit

// MARK: - FancyButton
//
open class FancyButton: UIButton {

    /// Style: Primary + Normal State
    ///
    @objc public dynamic var primaryNormalBackgroundColor = Primary.normalBackgroundColor {
        didSet {
            configureBackgrounds()
        }
    }
    @objc public dynamic var primaryNormalBorderColor: UIColor? {
        didSet {
            configureBackgrounds()
        }
    }

    /// Style: Primary + Highlighted State
    ///
    @objc public dynamic var primaryHighlightBackgroundColor = Primary.highlightBackgroundColor {
        didSet {
            configureBackgrounds()
        }
    }
    @objc public dynamic var primaryHighlightBorderColor: UIColor? {
        didSet {
            configureBackgrounds()
        }
    }

    /// Style: Secondary
    ///
    @objc public dynamic var secondaryNormalBackgroundColor = Secondary.normalBackgroundColor {
        didSet {
            configureBackgrounds()
        }
    }
    @objc public dynamic var secondaryNormalBorderColor = Secondary.normalBorderColor {
        didSet {
            configureBackgrounds()
        }
    }
    @objc public dynamic var secondaryHighlightBackgroundColor = Secondary.highlightBackgroundColor {
        didSet {
            configureBackgrounds()
        }
    }
    @objc public dynamic var secondaryHighlightBorderColor = Secondary.highlightBorderColor {
        didSet {
            configureBackgrounds()
        }
    }

    /// Style: Disabled State
    ///
    @objc public dynamic var disabledBackgroundColor = Disabled.backgroundColor {
        didSet {
            configureBackgrounds()
        }
    }
    @objc public dynamic var disabledBorderColor = Disabled.borderColor {
        didSet {
            configureBackgrounds()
        }
    }

    /// Style: Title!
    ///
    @objc public dynamic var titleFont = Title.defaultFont {
        didSet {
            configureTitleLabel()
        }
    }
    @objc public dynamic var primaryTitleColor = Title.primaryColor {
        didSet {
            configureTitleColors()
        }
    }
    @objc public dynamic var secondaryTitleColor = Title.secondaryColor {
        didSet {
            configureTitleColors()
        }
    }
    @objc public dynamic var disabledTitleColor = Title.disabledColor {
        didSet {
            configureTitleColors()
        }
    }

    /// Insets to be applied over the Contents.
    ///
    @objc public dynamic var contentInsets = UIImage.DefaultRenderMetrics.contentInsets {
        didSet {
            configureInsets()
        }
    }

    /// Indicates if the current instance should be rendered with the "Primary" Style.
    ///
    @IBInspectable public var isPrimary: Bool = false {
        didSet {
            configureBackgrounds()
            configureTitleColors()
        }
    }

    // MARK: - LifeCycle Methods

    open override func didMoveToWindow() {
        super.didMoveToWindow()
        configureAppearance()
    }

    open override func awakeFromNib() {
        super.awakeFromNib()
        configureAppearance()
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        configureBackgrounds()
    }

    // This implementation is required to allow the text of a button to
    // wrap appropriately including insets above and below.
    //
    open override var intrinsicContentSize: CGSize {
        guard let titleLabel = titleLabel else {
            return super.intrinsicContentSize
        }

        let horizontalInsets = contentEdgeInsets.left + contentEdgeInsets.right
        let verticalInsets = contentEdgeInsets.top + contentEdgeInsets.bottom

        var size = titleLabel.sizeThatFits(CGSize(width: titleLabel.preferredMaxLayoutWidth - horizontalInsets,
                                                  height: .greatestFiniteMagnitude))
        size.width += horizontalInsets
        size.height += verticalInsets

        return size
    }

    open override func layoutSubviews() {
        titleLabel?.preferredMaxLayoutWidth = bounds.width

        super.layoutSubviews()
    }

    /// Setup: Everything = [Insets, Backgrounds, titleColor(s), titleLabel]
    ///
    private func configureAppearance() {
        configureInsets()
        configureBackgrounds()
        configureTitleColors()
        configureTitleLabel()
    }

    /// Setup: FancyButton's Default Settings
    ///
    private func configureInsets() {
        contentEdgeInsets = contentInsets
    }

    /// Setup: BackgroundImage
    ///
    private func configureBackgrounds() {
        let normalImage: UIImage
        let highlightedImage: UIImage
        let disabledImage = UIImage.renderBackgroundImage(fill: disabledBackgroundColor, border: disabledBorderColor)

        if isPrimary {
            normalImage = UIImage.renderBackgroundImage(fill: primaryNormalBackgroundColor, border: primaryNormalBorderColor)
            highlightedImage = UIImage.renderBackgroundImage(fill: primaryHighlightBackgroundColor, border: primaryHighlightBorderColor)
        } else {
            normalImage = UIImage.renderBackgroundImage(fill: secondaryNormalBackgroundColor, border: secondaryNormalBorderColor)
            highlightedImage = UIImage.renderBackgroundImage(fill: secondaryHighlightBackgroundColor, border: secondaryHighlightBorderColor)
        }

        setBackgroundImage(normalImage, for: .normal)
        setBackgroundImage(highlightedImage, for: .highlighted)
        setBackgroundImage(disabledImage, for: .disabled)
    }

    /// Setup: TitleColor
    ///
    private func configureTitleColors() {
        let titleColorNormal = isPrimary ? primaryTitleColor : secondaryTitleColor

        setTitleColor(titleColorNormal, for: .normal)
        setTitleColor(titleColorNormal, for: .highlighted)
        setTitleColor(disabledTitleColor, for: .disabled)
    }

    /// Setup: TitleLabel
    ///
    private func configureTitleLabel() {
        titleLabel?.font = titleFont
        titleLabel?.adjustsFontForContentSizeCategory = true
        titleLabel?.textAlignment = .center
    }
}

// MARK: - Nested Types
//
private extension FancyButton {

    /// Style: Primary
    ///
    struct Primary {
        static let normalBackgroundColor = UIColor(red: 0x00/255.0, green: 0xAA/255.0, blue: 0xDC/255.0, alpha: 0xFF/255.0)
        static let highlightBackgroundColor = UIColor(red: 0x00/255.0, green: 0x87/255.0, blue: 0xBE/255.0, alpha: 0xFF/255.0)
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
}
