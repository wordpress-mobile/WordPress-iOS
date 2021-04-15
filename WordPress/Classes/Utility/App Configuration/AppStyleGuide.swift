import Foundation
import WordPressShared

struct AppStyleGuide {
    static let navigationBarStandardFont: UIFont = WPStyleGuide.fixedSerifFontForTextStyle(.headline, fontWeight: .semibold)
    static let navigationBarLargeFont: UIFont = WPStyleGuide.fixedSerifFontForTextStyle(.largeTitle, fontWeight: .semibold)
    static let blogDetailHeaderTitleFont: UIFont = WPStyleGuide.serifFontForTextStyle(.title2, fontWeight: .semibold)
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
}

// MARK: - Images
extension AppStyleGuide {
    static let mySiteTabIcon = UIImage(named: "icon-tab-mysites")
    static let aboutAppIcon = UIImage(named: "icon-wp")
}
