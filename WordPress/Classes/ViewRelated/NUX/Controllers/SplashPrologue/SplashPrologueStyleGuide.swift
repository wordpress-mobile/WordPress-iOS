import UIKit
import SwiftUI
import WordPressUI

struct SplashPrologueStyleGuide {
    static let backgroundColor = UIColor(light: .colorFromHex("F6F7F7"), dark: .colorFromHex("2C3338"))

    struct Title {
        static let font = Font.system(size: 25, weight: .regular, design: .serif)
        static let textColor = UIColor(light: .colorFromHex("101517"), dark: .white)
    }

    struct BrushStroke {
        static let color = UIColor(light: .colorFromHex("BBE0FA"), dark: .colorFromHex("101517"))
            .withAlphaComponent(0.3)
    }

    /// Use the same shade for light and dark modes
    private static let primaryButtonColor: UIColor = UIAppColor.primary
        .resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
    private static let primaryButtonHighlightedColor: UIColor = UIAppColor.primary(.shade60)
        .resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))

    private static let secondaryButtonColor: UIColor = .white
    private static let secondaryButtonHighlightedColor: UIColor = UIAppColor.gray(.shade5)
}

// MARK: - Prologue button configurations

extension SplashPrologueStyleGuide {
    static func primaryButtonConfiguration(highlighted: Bool = false) -> UIButton.Configuration {
        var configuration = UIButton.Configuration.filled()
        configuration.baseBackgroundColor = highlighted ? primaryButtonHighlightedColor : primaryButtonColor
        configuration.baseForegroundColor = .white
        applyPrologueButtonMetrics(to: &configuration)
        return configuration
    }

    static func secondaryButtonConfiguration(highlighted: Bool = false) -> UIButton.Configuration {
        var configuration = UIButton.Configuration.filled()
        configuration.baseBackgroundColor = highlighted ? secondaryButtonHighlightedColor : secondaryButtonColor
        configuration.baseForegroundColor = .black
        configuration.background.strokeColor = secondaryButtonHighlightedColor
        configuration.background.strokeWidth = 1
        applyPrologueButtonMetrics(to: &configuration)
        return configuration
    }

    private static func applyPrologueButtonMetrics(to configuration: inout UIButton.Configuration) {
        configuration.cornerStyle = .fixed
        configuration.background.cornerRadius = 8
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
    }
}
