import Foundation
import WordPressShared

extension WPStyleGuide {
    public struct AlertView {
        // MARK: - Title Styles
        public static let titleRegularFont          = WPStyleGuide.fontForTextStyle(.callout, fontWeight: .light)
        public static let titleColor                = WPStyleGuide.grey()


        // MARK: - Detail Styles
        public static let detailsRegularFont        = WPStyleGuide.fontForTextStyle(.footnote)
        public static let detailsBoldFont           = WPStyleGuide.fontForTextStyle(.footnote, fontWeight: .semibold)
        public static let detailsColor              = WPStyleGuide.darkGrey()

        public static let detailsRegularAttributes: [NSAttributedStringKey: Any] = [.font: detailsRegularFont,
                                                                                    .foregroundColor: detailsColor]

        public static let detailsBoldAttributes: [NSAttributedStringKey: Any] = [.font: detailsBoldFont,
                                                                                 .foregroundColor: detailsColor]

        // MARK: - Button Styles
        public static let buttonFont = WPFontManager.systemRegularFont(ofSize: 16)
    }
}
