import Foundation
import BuildSettingsKit
import DesignSystem
import WordPressShared

struct AppStyleGuide {
    var navigationBarStandardFont: UIFont
    var navigationBarLargeFont: UIFont
    var epilogueTitleFont: UIFont

    static var current: AppStyleGuide {
        switch AppBrand.current {
        case .wordpress: .wordpress
        case .jetpack: .jetpack
        case .reader: .reader
        }
    }

    static let wordpress = AppStyleGuide(
        navigationBarStandardFont: WPStyleGuide.fixedSerifFontForTextStyle(.headline, fontWeight: .semibold),
        navigationBarLargeFont: WPStyleGuide.fixedSerifFontForTextStyle(.largeTitle, fontWeight: .semibold),
        epilogueTitleFont: WPStyleGuide.fixedSerifFontForTextStyle(.largeTitle, fontWeight: .semibold)
    )

    static let jetpack = AppStyleGuide(
        navigationBarStandardFont: WPStyleGuide.fontForTextStyle(.headline, fontWeight: .semibold),
        navigationBarLargeFont: WPStyleGuide.fontForTextStyle(.largeTitle, fontWeight: .bold),
        epilogueTitleFont: WPStyleGuide.fontForTextStyle(.largeTitle, fontWeight: .semibold)
    )

    static let reader = AppStyleGuide(
        navigationBarStandardFont: UIFont.preferredFont(forTextStyle: .headline).withWeight(.semibold),
        navigationBarLargeFont: UIFont.make(.recoleta, textStyle: .largeTitle, weight: .medium),
        epilogueTitleFont: UIFont.make(.recoleta, textStyle: .largeTitle, weight: .semibold)
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
