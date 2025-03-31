import UIKit
import Gridicons
import WordPressShared

// MARK: - WordPress Authenticator Styles
//
public struct WordPressAuthenticatorStyle {
    /// Style: Primary + Normal State
    ///
    public let primaryNormalBackgroundColor: UIColor

    public let primaryNormalBorderColor: UIColor?

    /// Style: Primary + Highlighted State
    ///
    public let primaryHighlightBackgroundColor: UIColor

    public let primaryHighlightBorderColor: UIColor?

    /// Style: Secondary
    ///
    public let secondaryNormalBackgroundColor: UIColor

    public let secondaryNormalBorderColor: UIColor

    public let secondaryHighlightBackgroundColor: UIColor

    public let secondaryHighlightBorderColor: UIColor

    /// Style: Disabled State
    ///
    public let disabledBackgroundColor: UIColor

    public let disabledBorderColor: UIColor

    public let primaryTitleColor: UIColor

    public let secondaryTitleColor: UIColor

    public let disabledTitleColor: UIColor

    /// Color of the spinner that is shown when a button is disabled.
    public let disabledButtonActivityIndicatorColor: UIColor

    /// Style: Text Buttons
    ///
    public let textButtonColor: UIColor

    public let textButtonHighlightColor: UIColor

    /// Style: Labels
    ///
    public let instructionColor: UIColor

    public let subheadlineColor: UIColor

    public let placeholderColor: UIColor

    /// Style: Login screen background colors
    ///
    public let viewControllerBackgroundColor: UIColor

    public let textFieldBackgroundColor: UIColor

    // If not specified, falls back to viewControllerBackgroundColor.
    public let buttonViewBackgroundColor: UIColor

    /// Style: shadow image view on top of the button view like a divider.
    /// If not specified, falls back to image "darkgrey-shadow".
    ///
    public let buttonViewTopShadowImage: UIImage?

    /// Style: nav bar
    ///
    public let navBarImage: UIImage

    public let navBarBadgeColor: UIColor

    public let navBarBackgroundColor: UIColor

    public let navButtonTextColor: UIColor

    /// Style: prologue background colors
    ///
    public let prologueBackgroundColor: UIColor

    /// Style: optional prologue background image
    ///
    public let prologueBackgroundImage: UIImage?

    /// Style: prologue background colors
    ///
    public let prologueTitleColor: UIColor

    /// Style: optional prologue buttons blur effect
    public let prologueButtonsBlurEffect: UIBlurEffect?

    /// Style: primary button on the prologue view (continue)
    /// When `nil` it will use the primary styles defined here
    /// Defaults to `nil`
    ///
    public let prologuePrimaryButtonStyle: NUXButtonStyle?

    /// Style: secondary button on the prologue view (site address)
    /// When `nil` it will use the secondary styles defined here
    /// Defaults to `nil`
    ///
    public let prologueSecondaryButtonStyle: NUXButtonStyle?

    /// Style: prologue top container child view controller
    /// When nil, `LoginProloguePageViewController` is displayed in the top container
    ///
    public let prologueTopContainerChildViewController: () -> UIViewController?

    /// Style: status bar style
    ///
    public let statusBarStyle: UIStatusBarStyle

    /// Style: OR divider separator color
    ///
    /// Used in `NUXStackedButtonsViewController`
    ///
    public let orDividerSeparatorColor: UIColor

    /// Style: OR divider text color
    ///
    /// Used in `NUXStackedButtonsViewController`
    ///
    public let orDividerTextColor: UIColor

    /// Designated initializer
    ///
    public init(primaryNormalBackgroundColor: UIColor,
                primaryNormalBorderColor: UIColor?,
                primaryHighlightBackgroundColor: UIColor,
                primaryHighlightBorderColor: UIColor?,
                secondaryNormalBackgroundColor: UIColor,
                secondaryNormalBorderColor: UIColor,
                secondaryHighlightBackgroundColor: UIColor,
                secondaryHighlightBorderColor: UIColor,
                disabledBackgroundColor: UIColor,
                disabledBorderColor: UIColor,
                primaryTitleColor: UIColor,
                secondaryTitleColor: UIColor,
                disabledTitleColor: UIColor,
                disabledButtonActivityIndicatorColor: UIColor,
                textButtonColor: UIColor,
                textButtonHighlightColor: UIColor,
                instructionColor: UIColor,
                subheadlineColor: UIColor,
                placeholderColor: UIColor,
                viewControllerBackgroundColor: UIColor,
                textFieldBackgroundColor: UIColor,
                buttonViewBackgroundColor: UIColor? = nil,
                buttonViewTopShadowImage: UIImage? = UIImage(named: "darkgrey-shadow"),
                navBarImage: UIImage,
                navBarBadgeColor: UIColor,
                navBarBackgroundColor: UIColor,
                navButtonTextColor: UIColor = .white,
                prologueBackgroundColor: UIColor = WPStyleGuide.wordPressBlue(),
                prologueBackgroundImage: UIImage? = nil,
                prologueTitleColor: UIColor = .white,
                prologueButtonsBlurEffect: UIBlurEffect? = nil,
                prologuePrimaryButtonStyle: NUXButtonStyle? = nil,
                prologueSecondaryButtonStyle: NUXButtonStyle? = nil,
                prologueTopContainerChildViewController: @autoclosure @escaping () -> UIViewController? = nil,
                statusBarStyle: UIStatusBarStyle = .lightContent,
                orDividerSeparatorColor: UIColor = .tertiaryLabel,
                orDividerTextColor: UIColor = .secondaryLabel) {
        self.primaryNormalBackgroundColor = primaryNormalBackgroundColor
        self.primaryNormalBorderColor = primaryNormalBorderColor
        self.primaryHighlightBackgroundColor = primaryHighlightBackgroundColor
        self.primaryHighlightBorderColor = primaryHighlightBorderColor
        self.secondaryNormalBackgroundColor = secondaryNormalBackgroundColor
        self.secondaryNormalBorderColor = secondaryNormalBorderColor
        self.secondaryHighlightBackgroundColor = secondaryHighlightBackgroundColor
        self.secondaryHighlightBorderColor = secondaryHighlightBorderColor
        self.disabledBackgroundColor = disabledBackgroundColor
        self.disabledBorderColor = disabledBorderColor
        self.primaryTitleColor = primaryTitleColor
        self.secondaryTitleColor = secondaryTitleColor
        self.disabledTitleColor = disabledTitleColor
        self.disabledButtonActivityIndicatorColor = disabledButtonActivityIndicatorColor
        self.textButtonColor = textButtonColor
        self.textButtonHighlightColor = textButtonHighlightColor
        self.instructionColor = instructionColor
        self.subheadlineColor = subheadlineColor
        self.placeholderColor = placeholderColor
        self.viewControllerBackgroundColor = viewControllerBackgroundColor
        self.textFieldBackgroundColor = textFieldBackgroundColor
        self.buttonViewBackgroundColor = buttonViewBackgroundColor ?? viewControllerBackgroundColor
        self.buttonViewTopShadowImage = buttonViewTopShadowImage
        self.navBarImage = navBarImage
        self.navBarBadgeColor = navBarBadgeColor
        self.navBarBackgroundColor = navBarBackgroundColor
        self.navButtonTextColor = navButtonTextColor
        self.prologueBackgroundColor = prologueBackgroundColor
        self.prologueBackgroundImage = prologueBackgroundImage
        self.prologueTitleColor = prologueTitleColor
        self.prologueButtonsBlurEffect = prologueButtonsBlurEffect
        self.prologuePrimaryButtonStyle = prologuePrimaryButtonStyle
        self.prologueSecondaryButtonStyle = prologueSecondaryButtonStyle
        self.prologueTopContainerChildViewController = prologueTopContainerChildViewController
        self.statusBarStyle = statusBarStyle
        self.orDividerSeparatorColor = orDividerSeparatorColor
        self.orDividerTextColor = orDividerTextColor
    }
}

// MARK: - WordPress Unified Authenticator Styles
//
// Styles specifically for the unified auth flows.
//
public struct WordPressAuthenticatorUnifiedStyle {

    /// Style: Auth view border colors
    ///
    public let borderColor: UIColor

    /// Style Auth default error color
    ///
    public let errorColor: UIColor

    /// Style: Auth default text color
    ///
    public let textColor: UIColor

    /// Style: Auth subtle text color
    ///
    public let textSubtleColor: UIColor

    /// Style: Auth plain text button normal state color
    ///
    public let textButtonColor: UIColor

    /// Style: Auth plain text button highlight state color
    ///
    public let textButtonHighlightColor: UIColor

    /// Style: Auth view background colors
    ///
    public let viewControllerBackgroundColor: UIColor

    /// Style: Auth Prologue buttons background color
    public let prologueButtonsBackgroundColor: UIColor

    /// Style: Auth Prologue view background color
    public let prologueViewBackgroundColor: UIColor

    /// Style: optional auth Prologue view background image
    public let prologueBackgroundImage: UIImage?

    /// Style: optional blur effect for the buttons view
    public let prologueButtonsBlurEffect: UIBlurEffect?

    /// Style: Status bar style. Defaults to `default`.
    ///
    public let statusBarStyle: UIStatusBarStyle

    /// Style: Navigation bar.
    ///
    public let navBarBackgroundColor: UIColor
    public let navButtonTextColor: UIColor
    public let navTitleTextColor: UIColor

    /// Style: Text color to be used for email in `GravatarEmailTableViewCell`
    ///
    public let gravatarEmailTextColor: UIColor?

    /// Designated initializer
    ///
    public init(borderColor: UIColor,
                errorColor: UIColor,
                textColor: UIColor,
                textSubtleColor: UIColor,
                textButtonColor: UIColor,
                textButtonHighlightColor: UIColor,
                viewControllerBackgroundColor: UIColor,
                prologueButtonsBackgroundColor: UIColor = .clear,
                prologueViewBackgroundColor: UIColor? = nil,
                prologueBackgroundImage: UIImage? = nil,
                prologueButtonsBlurEffect: UIBlurEffect? = nil,
                statusBarStyle: UIStatusBarStyle = .default,
                navBarBackgroundColor: UIColor,
                navButtonTextColor: UIColor,
                navTitleTextColor: UIColor,
                gravatarEmailTextColor: UIColor? = nil) {
        self.borderColor = borderColor
        self.errorColor = errorColor
        self.textColor = textColor
        self.textSubtleColor = textSubtleColor
        self.textButtonColor = textButtonColor
        self.textButtonHighlightColor = textButtonHighlightColor
        self.viewControllerBackgroundColor = viewControllerBackgroundColor
        self.prologueButtonsBackgroundColor = prologueButtonsBackgroundColor
        self.prologueViewBackgroundColor = prologueViewBackgroundColor ?? viewControllerBackgroundColor
        self.prologueBackgroundImage = prologueBackgroundImage
        self.prologueButtonsBlurEffect = prologueButtonsBlurEffect
        self.statusBarStyle = statusBarStyle
        self.navBarBackgroundColor = navBarBackgroundColor
        self.navButtonTextColor = navButtonTextColor
        self.navTitleTextColor = navTitleTextColor
        self.gravatarEmailTextColor = gravatarEmailTextColor
    }
}
