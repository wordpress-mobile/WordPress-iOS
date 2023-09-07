import Foundation
import WordPressShared

/// - Warning:
/// This configuration struct has a **Jetpack** counterpart in the Jetpack bundle.
/// Make sure to keep them in sync to avoid build errors when building the Jetpack target.
struct AppStyleGuide {
    static let navigationBarStandardFont: UIFont = WPStyleGuide.fixedSerifFontForTextStyle(.headline, fontWeight: .semibold)
    static let navigationBarLargeFont: UIFont = WPStyleGuide.fixedSerifFontForTextStyle(.largeTitle, fontWeight: .semibold)
    static let epilogueTitleFont: UIFont = WPStyleGuide.fixedSerifFontForTextStyle(.largeTitle, fontWeight: .semibold)
}

// MARK: - Colors
extension AppStyleGuide {
    static let accent = MurielColor(name: .pink)
    static let brand = MurielColor(name: .wordPressBlue)
    static let divider = MurielColor(name: .gray, shade: .shade10)
    static let error = MurielColor(name: .red)
    static let gray = MurielColor(name: .gray)
    static let primary = MurielColor(name: .blue)
    static let success = MurielColor(name: .green)
    static let text = MurielColor(name: .gray, shade: .shade80)
    static let textSubtle = MurielColor(name: .gray, shade: .shade50)
    static let warning = MurielColor(name: .yellow)
    static let jetpackGreen = MurielColor(name: .jetpackGreen)
    static let editorPrimary = MurielColor(name: .blue)
}

// MARK: - Images
extension AppStyleGuide {
    static let mySiteTabIcon = UIImage(named: "icon-tab-mysites")
    static let aboutAppIcon = UIImage(named: "icon-wp")
    static let quickStartExistingSite = UIImage(named: "wp-illustration-quickstart-existing-site")
}

// MARK: - Fonts
extension AppStyleGuide {
    static func prominentFont(textStyle: UIFont.TextStyle, weight: UIFont.Weight) -> UIFont {
        WPStyleGuide.serifFontForTextStyle(textStyle, fontWeight: weight)
    }
}
