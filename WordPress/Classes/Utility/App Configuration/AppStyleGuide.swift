import Foundation
import BuildSettingsKit
import WordPressShared

struct AppStyleGuide {
    var navigationBarStandardFont: UIFont
    var navigationBarLargeFont: UIFont
    var epilogueTitleFont: UIFont

    static var current: AppStyleGuide {
        switch AppBrand.current {
        case .wordpress: .wordpress
        case .jetpack: .jetpack
        }
    }

    static let jetpack = AppStyleGuide(
        navigationBarStandardFont: WPStyleGuide.fontForTextStyle(.headline, fontWeight: .semibold),
        navigationBarLargeFont: WPStyleGuide.fontForTextStyle(.largeTitle, fontWeight: .semibold),
        epilogueTitleFont: WPStyleGuide.fontForTextStyle(.largeTitle, fontWeight: .semibold)
    )

    static let wordpress = AppStyleGuide(
        navigationBarStandardFont: WPStyleGuide.fixedSerifFontForTextStyle(.headline, fontWeight: .semibold),
        navigationBarLargeFont: WPStyleGuide.fixedSerifFontForTextStyle(.largeTitle, fontWeight: .semibold),
        epilogueTitleFont: WPStyleGuide.fixedSerifFontForTextStyle(.largeTitle, fontWeight: .semibold)
    )
}

private extension AppBrand {
    /// TODO: remove this when unit tests not longer rely on `BuildSettings.current`.
    static var current: AppBrand {
        if BuildSettingsEnvironment.current == .test {
            return .jetpack
        }
        return BuildSettings.current.brand
    }
}
