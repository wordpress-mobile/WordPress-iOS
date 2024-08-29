import Foundation
import WordPressShared
import Gridicons

/// - Warning:
/// This configuration struct has a **WordPress** counterpart in the WordPress bundle.
/// Make sure to keep them in sync to avoid build errors when building the WordPress target.
struct AppStyleGuide {
    static let navigationBarStandardFont: UIFont = Feature.enabled(.serif) ? WPStyleGuide.fixedSerifFontForTextStyle(.headline, fontWeight: .semibold) : WPStyleGuide.fontForTextStyle(.headline, fontWeight: .semibold)
    static let navigationBarLargeFont: UIFont = Feature.enabled(.serif) ? WPStyleGuide.fixedSerifFontForTextStyle(.largeTitle, fontWeight: .semibold) : WPStyleGuide.fontForTextStyle(.largeTitle, fontWeight: .semibold)
    static let epilogueTitleFont: UIFont = Feature.enabled(.serif) ? WPStyleGuide.fixedSerifFontForTextStyle(.largeTitle, fontWeight: .semibold) : WPStyleGuide.fontForTextStyle(.largeTitle, fontWeight: .semibold)
}

// MARK: - Images
extension AppStyleGuide {
    static let mySiteTabIcon = UIImage(named: "jetpack-icon-tab-mysites")
}

// MARK: - Fonts
extension AppStyleGuide {
    static func prominentFont(textStyle: UIFont.TextStyle, weight: UIFont.Weight) -> UIFont {
        WPStyleGuide.fontForTextStyle(textStyle, fontWeight: weight)
    }
}
