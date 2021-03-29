import Foundation
import WordPressShared

struct AppStyleGuide: TargetStyleGuide {
    static let navigationBarStandardFont: UIFont = WPStyleGuide.fontForTextStyle(.headline, fontWeight: .semibold)
    static let navigationBarLargeFont: UIFont = WPStyleGuide.fontForTextStyle(.largeTitle, fontWeight: .semibold)
    static let blogDetailHeaderTitleFont: UIFont = WPStyleGuide.fontForTextStyle(.title2, fontWeight: .semibold)
}
