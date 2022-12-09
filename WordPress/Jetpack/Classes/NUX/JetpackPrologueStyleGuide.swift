import UIKit
import WordPressAuthenticator


/// The colors in here intentionally do not support light or dark modes since they're the same on both.
///
struct JetpackPrologueStyleGuide {
    // Background colors
    // old
    static let oldBackgroundColor = UIColor(red: 0.00, green: 0.11, blue: 0.18, alpha: 1.00)
    // combined
    static let backgroundColor = FeatureFlag.newJetpackLandingScreen.enabled ? .clear : oldBackgroundColor

    // Gradient overlay colors
    // new
    static let newGradientColor = UIColor(light: .muriel(color: .jetpackGreen, .shade0), dark: .muriel(color: .jetpackGreen, .shade100))
    // combined
    static let gradientColor = FeatureFlag.newJetpackLandingScreen.enabled ? newGradientColor : oldBackgroundColor

    // Continue with WordPress button colors
    // old
    static let oldContinueHighlightedFillColor = UIColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 0.90)
    // new
    static let newContinueFillColor = UIColor(light: .muriel(color: .jetpackGreen, .shade50), dark: .white)
    static let newContinueHighlightedFillColor = UIColor(light: .muriel(color: .jetpackGreen, .shade90), dark: whiteWithAlpha07)
    static let newContinueTextColor = UIColor(light: .white, dark: .muriel(color: .jetpackGreen, .shade80))

    // combined
    static let continueFillColor = FeatureFlag.newJetpackLandingScreen.enabled ? newContinueFillColor : .white
    static let continueHighlightedFillColor = FeatureFlag.newJetpackLandingScreen.enabled ? newContinueHighlightedFillColor : oldContinueHighlightedFillColor
    static let continueTextColor = FeatureFlag.newJetpackLandingScreen.enabled ? newContinueTextColor : oldBackgroundColor
    static let continueHighlightedTextColor = FeatureFlag.newJetpackLandingScreen.enabled ? whiteWithAlpha07 : oldBackgroundColor


    // Enter your site address button
    // old
    static let oldSiteBorderColor = UIColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 0.40)
    static let newSiteTextColor = UIColor(light: .muriel(color: .jetpackGreen, .shade90), dark: .white)
    static let newSiteHighlightedTextColor = UIColor(light: .muriel(color: .jetpackGreen, .shade50), dark: whiteWithAlpha07)
    static let oldSiteHighlightedBorderColor = UIColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 0.20)
    // combined
    static let siteFillColor = FeatureFlag.newJetpackLandingScreen.enabled ? .clear : oldBackgroundColor
    static let siteBorderColor = FeatureFlag.newJetpackLandingScreen.enabled ? .clear : oldSiteBorderColor
    static let siteTextColor = FeatureFlag.newJetpackLandingScreen.enabled ? newSiteTextColor : UIColor.white
    static let siteHighlightedFillColor = FeatureFlag.newJetpackLandingScreen.enabled ? whiteWithAlpha07 : oldBackgroundColor
    static let siteHighlightedBorderColor = FeatureFlag.newJetpackLandingScreen.enabled ? whiteWithAlpha07 : oldSiteHighlightedBorderColor
    static let siteHighlightedTextColor = FeatureFlag.newJetpackLandingScreen.enabled ? newSiteHighlightedTextColor : whiteWithAlpha07

    // Color used in both old and versions
    static let whiteWithAlpha07 = UIColor.white.withAlphaComponent(0.7)

    // Background image with gradient for the new Jetpack prologue screen
    static let prologueBackgroundImage: UIImage? = FeatureFlag.newJetpackLandingScreen.enabled ? UIImage(named: "JPBackground") : nil
    // Blur effect for the prologue buttons
    static let prologueButtonsBlurEffect: UIBlurEffect?  = FeatureFlag.newJetpackLandingScreen.enabled ? UIBlurEffect(style: .regular) : nil




    struct Title {
        static let font: UIFont = WPStyleGuide.fontForTextStyle(.title3, fontWeight: .semibold)
        static let textColor: UIColor = .white
    }

    struct Stars {
        static let particleImage = UIImage(named: "circle-particle")

        static let colors = [
            UIColor(red: 0.05, green: 0.27, blue: 0.44, alpha: 1.00),
            UIColor(red: 0.64, green: 0.68, blue: 0.71, alpha: 1.00),
            UIColor(red: 0.99, green: 0.99, blue: 0.99, alpha: 1.00)
        ]
    }

    static let continueButtonStyle = NUXButtonStyle(normal: .init(backgroundColor: continueFillColor,
                                                                  borderColor: continueFillColor,
                                                                  titleColor: continueTextColor),
                                                    highlighted: .init(backgroundColor: continueHighlightedFillColor,
                                                                       borderColor: continueHighlightedFillColor,
                                                                       titleColor: continueHighlightedTextColor),

                                                    disabled: .init(backgroundColor: .white,
                                                                    borderColor: .white,
                                                                    titleColor: backgroundColor))

    static let siteAddressButtonStyle = NUXButtonStyle(normal: .init(backgroundColor: siteFillColor,
                                                                     borderColor: siteBorderColor,
                                                                   titleColor: siteTextColor),

                                                     highlighted: .init(backgroundColor: siteHighlightedFillColor,
                                                                        borderColor: siteHighlightedBorderColor,
                                                                        titleColor: siteHighlightedTextColor),

                                                     disabled: .init(backgroundColor: .white,
                                                                     borderColor: .white,
                                                                     titleColor: backgroundColor))

}
