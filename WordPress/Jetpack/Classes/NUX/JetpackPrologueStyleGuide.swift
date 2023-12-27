import UIKit
import WordPressAuthenticator


struct JetpackPrologueStyleGuide {
    // Background color
    static let backgroundColor = UIColor.clear

    // Gradient overlay color
    static let gradientColor = UIColor(
        light: .white,
        dark: UIColor(hexString: "050A21")
    )

    // Continue with WordPress button colors
    static let continueFillColor = JetpackPromptsConfiguration.Constants.evenColor ?? .systemBlue // This is just to satisfy the compiler
    static let continueHighlightedFillColor = continueFillColor.withAlphaComponent(0.9)
    static let continueTextColor = UIColor.white
    static let continueHighlightedTextColor = whiteWithAlpha07


    // Enter your site address button
    static let siteFillColor = UIColor.clear
    static let siteBorderColor = UIColor.clear
    static let siteTextColor = UIColor(light: .muriel(color: .jetpackGreen, .shade90), dark: .white)
    static let siteHighlightedFillColor = UIColor.clear
    static let siteHighlightedBorderColor = UIColor.clear
    static let siteHighlightedTextColor = UIColor(light: .muriel(color: .jetpackGreen, .shade50), dark: whiteWithAlpha07)

    // Color used in both old and versions
    static let whiteWithAlpha07 = UIColor.white.withAlphaComponent(0.7)

    // Background image with gradient for the new Jetpack prologue screen
    static let prologueBackgroundImage: UIImage? = UIImage(named: "JPBackground")
    // Blur effect for the prologue buttons
    static let prologueButtonsBlurEffect: UIBlurEffect? = UIBlurEffect(style: .regular)




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
