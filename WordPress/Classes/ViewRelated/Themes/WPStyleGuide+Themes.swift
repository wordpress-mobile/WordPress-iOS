import Foundation

/**
    A WPStyleGuide extension with styles and methods specific to the
    Themes feature.
*/
extension WPStyleGuide
{
    public struct Themes
    {
        // MARK: - Cell Styles

        public static let cellNameFont = WPFontManager.openSansSemiBoldFontOfSize(14)
        public static let cellInfoFont = WPFontManager.openSansSemiBoldFontOfSize(12)

        public static let activeCellBackgroundColor = WPStyleGuide.mediumBlue()
        public static let activeCellNameColor = UIColor.whiteColor()
        public static let activeCellInfoColor = WPStyleGuide.lightBlue()

        public static let inactiveCellBackgroundColor = UIColor.whiteColor()
        public static let inactiveCellNameColor = WPStyleGuide.darkGrey()
        public static let inactiveCellPriceColor = WPStyleGuide.validGreen()

        // MARK: - Metrics

        public static let columnMargin: CGFloat = 16
        public static let minimumColumnWidth: CGFloat = 330

        public static let cellImageInset: CGFloat = 2
        public static let cellImageRatio: CGFloat = 0.75
        public static let cellInfoBarHeight: CGFloat = 55
    }

}
