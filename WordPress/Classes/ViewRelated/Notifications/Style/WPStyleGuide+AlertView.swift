import Foundation
import WordPressShared

extension WPStyleGuide {
    public struct AlertView {
        // MARK: - Title Styles
        public static let titleRegularFont          = WPStyleGuide.fontForTextStyle(.callout,
                                                                                    fontWeight: UIFontWeightLight)
        public static let titleColor                = WPStyleGuide.grey()


        // MARK: - Detail Styles
        public static let detailsRegularFont        = WPStyleGuide.fontForTextStyle(.footnote)
        public static let detailsBoldFont           = WPStyleGuide.fontForTextStyle(.footnote,
                                                                                    fontWeight: UIFontWeightSemibold)
        public static let detailsColor              = WPStyleGuide.darkGrey()

        public static let detailsRegularAttributes  = [
                                                            NSFontAttributeName: detailsRegularFont,
                                                            NSForegroundColorAttributeName: detailsColor
                                                      ]

        public static let detailsBoldAttributes     = [
                                                            NSFontAttributeName: detailsBoldFont,
                                                            NSForegroundColorAttributeName: detailsColor
                                                      ]

        // MARK: - Button Styles
        public static let buttonFont                = WPFontManager.systemRegularFont(ofSize: 16)
    }
}
