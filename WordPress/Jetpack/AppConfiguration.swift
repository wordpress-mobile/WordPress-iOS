import Foundation

@objc class AppConfiguration: NSObject, TargetConfiguration {
    @objc static let isJetpack: Bool = true
}

extension AppConfiguration: TargetFontConfiguration {
    static let navigationBarStandardFont: UIFont = WPStyleGuide.fontForTextStyle(.headline, fontWeight: .semibold)
    static let navigationBarLargeFont: UIFont = WPStyleGuide.fontForTextStyle(.largeTitle, fontWeight: .semibold)
}
