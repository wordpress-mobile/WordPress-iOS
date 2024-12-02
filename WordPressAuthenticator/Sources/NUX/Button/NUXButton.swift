import UIKit
import WordPressShared
import WordPressKit

public struct NUXButtonStyle {
    public let normal: ButtonStyle
    public let highlighted: ButtonStyle
    public let disabled: ButtonStyle

    public struct ButtonStyle {
        public let backgroundColor: UIColor
        public let borderColor: UIColor
        public let titleColor: UIColor

        public init(backgroundColor: UIColor, borderColor: UIColor, titleColor: UIColor) {
            self.backgroundColor = backgroundColor
            self.borderColor = borderColor
            self.titleColor = titleColor
        }
    }

    public init(normal: ButtonStyle, highlighted: ButtonStyle, disabled: ButtonStyle) {
        self.normal = normal
        self.highlighted = highlighted
        self.disabled = disabled
    }

    public static var linkButtonStyle: NUXButtonStyle {
        let backgroundColor = UIColor.clear
        let buttonTitleColor = WordPressAuthenticator.shared.unifiedStyle?.textButtonColor ?? WordPressAuthenticator.shared.style.textButtonColor
        let buttonHighlightColor = WordPressAuthenticator.shared.unifiedStyle?.textButtonHighlightColor ?? WordPressAuthenticator.shared.style.textButtonHighlightColor

        let normalButtonStyle = ButtonStyle(backgroundColor: backgroundColor,
                                            borderColor: backgroundColor,
                                            titleColor: buttonTitleColor)
        let highlightedButtonStyle = ButtonStyle(backgroundColor: backgroundColor,
                                                 borderColor: backgroundColor,
                                                 titleColor: buttonHighlightColor)
        let disabledButtonStyle = ButtonStyle(backgroundColor: backgroundColor,
                                              borderColor: backgroundColor,
                                              titleColor: buttonTitleColor.withAlphaComponent(0.5))
        return NUXButtonStyle(normal: normalButtonStyle,
                              highlighted: highlightedButtonStyle,
                              disabled: disabledButtonStyle)
    }
}
/// A stylized button used by Login controllers. It also can display a `UIActivityIndicatorView`.
@objc open class NUXButton: UIButton {
    @objc var isAnimating: Bool {
        return activityIndicator.isAnimating
    }

    var buttonStyle: NUXButtonStyle?

    open override var isEnabled: Bool {
        didSet {
            activityIndicator.color = activityIndicatorColor(isEnabled: isEnabled)
        }
    }

    @objc let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    var titleFont = WPStyleGuide.mediumWeightFont(forStyle: .title3)

    override open func layoutSubviews() {
        super.layoutSubviews()

        if activityIndicator.isAnimating {
            titleLabel?.frame = CGRect.zero

            var frm = activityIndicator.frame
            frm.origin.x = (frame.width - frm.width) / 2.0
            frm.origin.y = (frame.height - frm.height) / 2.0
            activityIndicator.frame = frm.integral
        }
    }

    open override func tintColorDidChange() {
        // Update colors when toggling light/dark mode.
        super.tintColorDidChange()
        configureBackgrounds()
        configureTitleColors()

        if socialService == .apple {
            setAttributedTitle(WPStyleGuide.formattedAppleString(), for: .normal)
        }
    }

    // MARK: - Instance Methods

    /// Toggles the visibility of the activity indicator.  When visible the button
    /// title is hidden.
    ///
    /// - Parameter show: True to show the spinner. False hides it.
    ///
    open func showActivityIndicator(_ show: Bool) {
        if show {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
        setNeedsLayout()
    }

    func didChangePreferredContentSize() {
        titleLabel?.adjustsFontForContentSizeCategory = true
    }

    func customizeFont(_ font: UIFont) {
        titleFont = font
    }

    /// Indicates if the current instance should be rendered with the "Primary" Style.
    ///
    @IBInspectable public var isPrimary: Bool = false {
        didSet {
            configureBackgrounds()
            configureTitleColors()
        }
    }

    var socialService: SocialServiceName?

    // MARK: - LifeCycle Methods

    open override func didMoveToWindow() {
        super.didMoveToWindow()
        configureAppearance()
    }

    open override func awakeFromNib() {
        super.awakeFromNib()
        configureAppearance()
    }

    /// Setup: Everything = [Insets, Backgrounds, titleColor(s), titleLabel]
    ///
    private func configureAppearance() {
        configureInsets()
        configureBackgrounds()
        configureActivityIndicator()
        configureTitleColors()
        configureTitleLabel()
    }

    /// Setup: NUXButton's Default Settings
    ///
    private func configureInsets() {
        contentEdgeInsets = UIImage.DefaultRenderMetrics.contentInsets
    }

    /// Setup: ActivityIndicator
    ///
    private func configureActivityIndicator() {
        activityIndicator.color = activityIndicatorColor()
        addSubview(activityIndicator)
    }

    /// Setup: BackgroundImage
    ///
    private func configureBackgrounds() {
        guard let buttonStyle else {
            legacyConfigureBackgrounds()
            return
        }

        let normalImage = UIImage.renderBackgroundImage(fill: buttonStyle.normal.backgroundColor,
                                                        border: buttonStyle.normal.borderColor)

        let highlightedImage = UIImage.renderBackgroundImage(fill: buttonStyle.highlighted.backgroundColor,
                                                             border: buttonStyle.highlighted.borderColor)

        let disabledImage = UIImage.renderBackgroundImage(fill: buttonStyle.disabled.backgroundColor,
                                                          border: buttonStyle.disabled.borderColor)

        setBackgroundImage(normalImage, for: .normal)
        setBackgroundImage(highlightedImage, for: .highlighted)
        setBackgroundImage(disabledImage, for: .disabled)
    }

    /// Fallback method to configure the background colors based on the shared `WordPressAuthenticatorStyle`
    ///
    private func legacyConfigureBackgrounds() {
        let style = WordPressAuthenticator.shared.style

        let normalImage: UIImage
        let highlightedImage: UIImage
        let disabledImage = UIImage.renderBackgroundImage(fill: style.disabledBackgroundColor,
                                                          border: style.disabledBorderColor)

        if isPrimary {
            normalImage = UIImage.renderBackgroundImage(fill: style.primaryNormalBackgroundColor,
                                                        border: style.primaryNormalBorderColor)
            highlightedImage = UIImage.renderBackgroundImage(fill: style.primaryHighlightBackgroundColor,
                                                             border: style.primaryHighlightBorderColor)
        } else {
            normalImage = UIImage.renderBackgroundImage(fill: style.secondaryNormalBackgroundColor,
                                                        border: style.secondaryNormalBorderColor)
            highlightedImage = UIImage.renderBackgroundImage(fill: style.secondaryHighlightBackgroundColor,
                                                             border: style.secondaryHighlightBorderColor)
        }

        setBackgroundImage(normalImage, for: .normal)
        setBackgroundImage(highlightedImage, for: .highlighted)
        setBackgroundImage(disabledImage, for: .disabled)
    }

    /// Setup: TitleColor
    ///
    private func configureTitleColors() {
        guard let buttonStyle else {
            legacyConfigureTitleColors()
            return
        }

        setTitleColor(buttonStyle.normal.titleColor, for: .normal)
        setTitleColor(buttonStyle.highlighted.titleColor, for: .highlighted)
        setTitleColor(buttonStyle.disabled.titleColor, for: .disabled)
    }

    /// Fallback method to configure the title colors based on the shared `WordPressAuthenticatorStyle`
    ///
    private func legacyConfigureTitleColors() {
        let style = WordPressAuthenticator.shared.style
        let titleColorNormal = isPrimary ? style.primaryTitleColor : style.secondaryTitleColor

        setTitleColor(titleColorNormal, for: .normal)
        setTitleColor(titleColorNormal, for: .highlighted)
        setTitleColor(style.disabledTitleColor, for: .disabled)
    }

    /// Setup: TitleLabel
    ///
    private func configureTitleLabel() {
        titleLabel?.font = self.titleFont
        titleLabel?.adjustsFontForContentSizeCategory = true
        titleLabel?.textAlignment = .center
    }

    /// Returns the current color that should be used for the activity indicator
    ///
    private func activityIndicatorColor(isEnabled: Bool = true) -> UIColor {
        guard let style = buttonStyle else {
            let style = WordPressAuthenticator.shared.style

            return isEnabled ? style.primaryTitleColor : style.disabledButtonActivityIndicatorColor
        }

        return isEnabled ? style.normal.titleColor : style.disabled.titleColor
    }
}

// MARK: -
//
extension NUXButton {
    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            didChangePreferredContentSize()
        }
    }
}
