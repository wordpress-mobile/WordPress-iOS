import Foundation
import WordPressShared

@objc class AppConfiguration: NSObject, TargetConfiguration {
    @objc static let isJetpack: Bool = false
}

extension AppConfiguration: TargetFontConfiguration {
    static let navigationBarStandardFont: UIFont = WPStyleGuide.fixedSerifFontForTextStyle(.headline, fontWeight: .semibold)
    static let navigationBarLargeFont: UIFont = WPStyleGuide.fixedSerifFontForTextStyle(.largeTitle, fontWeight: .semibold)
    static let blogDetailHeaderTitleFont: UIFont = WPStyleGuide.serifFontForTextStyle(.title2, fontWeight: .semibold)
}
