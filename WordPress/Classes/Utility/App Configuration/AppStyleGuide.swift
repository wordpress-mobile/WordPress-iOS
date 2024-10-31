import Foundation
import WordPressShared
import WordPressUI
import ColorStudio

struct AppStyleGuide {

#if IS_JETPACK
    static let navigationBarStandardFont: UIFont = WPStyleGuide.fontForTextStyle(.headline, fontWeight: .semibold)
    static let navigationBarLargeFont: UIFont = WPStyleGuide.fontForTextStyle(.largeTitle, fontWeight: .semibold)
    static let epilogueTitleFont: UIFont = WPStyleGuide.fontForTextStyle(.largeTitle, fontWeight: .semibold)
#endif

#if IS_WORDPRESS
    static let navigationBarStandardFont: UIFont = WPStyleGuide.fixedSerifFontForTextStyle(.headline, fontWeight: .semibold)
    static let navigationBarLargeFont: UIFont = WPStyleGuide.fixedSerifFontForTextStyle(.largeTitle, fontWeight: .semibold)
    static let epilogueTitleFont: UIFont = WPStyleGuide.fixedSerifFontForTextStyle(.largeTitle, fontWeight: .semibold)
#endif
}

// MARK: - Images
extension AppStyleGuide {
#if IS_JETPACK
    static let mySiteTabIcon = UIImage(named: "jetpack-icon-tab-mysites")
#endif

#if IS_WORDPRESS
    static let mySiteTabIcon = UIImage(named: "icon-tab-mysites")
#endif
}

// MARK: - Fonts
extension AppStyleGuide {
#if IS_JETPACK
    static func prominentFont(textStyle: UIFont.TextStyle, weight: UIFont.Weight) -> UIFont {
        WPStyleGuide.fontForTextStyle(textStyle, fontWeight: weight)
    }
#endif

#if IS_WORDPRESS
    static func prominentFont(textStyle: UIFont.TextStyle, weight: UIFont.Weight) -> UIFont {
        WPStyleGuide.serifFontForTextStyle(textStyle, fontWeight: weight)
    }
#endif
}
