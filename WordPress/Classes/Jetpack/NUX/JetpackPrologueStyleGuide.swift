import UIKit
import WordPressUI

struct JetpackPrologueStyleGuide {
    // Background color
    static let backgroundColor = UIColor.clear

    // Gradient overlay color
    static let gradientColor = UIColor(
        light: .white,
        dark: UIColor(fromHex: 0x050A21)
    )

    // Continue with WordPress button colors
    static let continueFillColor = JetpackPromptsConfiguration.Constants.evenColor
    static let continueHighlightedFillColor = continueFillColor.withAlphaComponent(0.9)
    static let continueTextColor = UIColor.white
    static let continueHighlightedTextColor = whiteWithAlpha07

    // Enter your site address button
    static let siteTextColor = UIColor(light: UIAppColor.jetpackGreen(.shade90), dark: .white)
    static let siteHighlightedTextColor = UIColor(light: UIAppColor.jetpackGreen(.shade50), dark: whiteWithAlpha07)

    // Color used in both old and versions
    static let whiteWithAlpha07 = UIColor.white.withAlphaComponent(0.7)

    // Blur effect for the prologue buttons
    static let prologueButtonsBlurEffect: UIBlurEffect? = UIBlurEffect(style: .regular)

    struct Title {
        static let font: UIFont = WPStyleGuide.fontForTextStyle(.title3, fontWeight: .semibold)
        static let textColor: UIColor = .white
    }
}

// MARK: - Prologue button configurations

extension JetpackPrologueStyleGuide {
    static func primaryButtonConfiguration(highlighted: Bool = false) -> UIButton.Configuration {
        var configuration = UIButton.Configuration.filled()
        configuration.baseBackgroundColor = highlighted ? continueHighlightedFillColor : continueFillColor
        configuration.baseForegroundColor = highlighted ? continueHighlightedTextColor : continueTextColor
        applyPrologueButtonMetrics(to: &configuration)
        return configuration
    }

    static func secondaryButtonConfiguration(highlighted: Bool = false) -> UIButton.Configuration {
        var configuration = UIButton.Configuration.plain()
        configuration.baseForegroundColor = highlighted ? siteHighlightedTextColor : siteTextColor
        applyPrologueButtonMetrics(to: &configuration)
        return configuration
    }

    private static func applyPrologueButtonMetrics(to configuration: inout UIButton.Configuration) {
        configuration.cornerStyle = .fixed
        configuration.background.cornerRadius = 8
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
    }
}
