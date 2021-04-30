import Foundation
import WordPressShared
import Gridicons

struct AppStyleGuide {
    static let navigationBarStandardFont: UIFont = WPStyleGuide.fontForTextStyle(.headline, fontWeight: .semibold)
    static let navigationBarLargeFont: UIFont = WPStyleGuide.fontForTextStyle(.largeTitle, fontWeight: .semibold)
    static let blogDetailHeaderTitleFont: UIFont = WPStyleGuide.fontForTextStyle(.title2, fontWeight: .semibold)
    static let epilogueTitleFont: UIFont = WPStyleGuide.fontForTextStyle(.largeTitle, fontWeight: .semibold)
}

// MARK: - Colors
extension AppStyleGuide {
    static let accent = MurielColor(name: .jetpackGreen)
    static let brand = MurielColor(name: .jetpackGreen)
    static let divider = MurielColor(name: .gray, shade: .shade10)
    static let error = MurielColor(name: .red)
    static let gray = MurielColor(name: .gray)
    static let primary = MurielColor(name: .jetpackGreen)
    static let success = MurielColor(name: .green)
    static let text = MurielColor(name: .gray, shade: .shade80)
    static let textSubtle = MurielColor(name: .gray, shade: .shade50)
    static let warning = MurielColor(name: .yellow)
    static let jetpackGreen = MurielColor(name: .jetpackGreen)
}

// MARK: - Images
extension AppStyleGuide {
    static let mySiteTabIcon = UIImage.gridicon(.house)
    static let aboutAppIcon = UIImage(named: "jetpack-install-logo")
}
