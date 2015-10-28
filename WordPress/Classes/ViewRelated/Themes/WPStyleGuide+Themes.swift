import Foundation

/**
    A WPStyleGuide extension with styles and methods specific to the
    Themes feature.
*/
extension WPStyleGuide
{
    public struct Themes
    {
        // MARK: - General Styles

        public static let borderColor = UIColor(red: 208.0/255.0, green: 220.0/255.0, blue: 229.0/255.0, alpha: 1)
        public static let dividerColor = UIColor(red: 224.0/255.0, green: 239.0/255.0, blue: 233.0/255.0, alpha: 1)

        // MARK: - Current Theme Styles

        public static let currentThemeLabelFont = WPFontManager.openSansRegularFontOfSize(11)
        public static let currentThemeLabelColor = WPStyleGuide.greyDarken20()
        
        public static let currentThemeNameFont = WPFontManager.openSansSemiBoldFontOfSize(14)
        public static let currentThemeNameColor = WPStyleGuide.darkGrey()

        public static let currentThemeButtonFont = WPFontManager.openSansRegularFontOfSize(13)
        public static let currentThemeButtonColor = WPStyleGuide.darkGrey()
        
       // MARK: - Cell Styles

        public static let cellNameFont = WPFontManager.openSansSemiBoldFontOfSize(14)
        public static let cellInfoFont = WPFontManager.openSansSemiBoldFontOfSize(12)

        public static let placeholderColor = WPStyleGuide.greyLighten20()

        public static let activeCellBackgroundColor = WPStyleGuide.mediumBlue()
        public static let activeCellNameColor = UIColor.whiteColor()
        public static let activeCellInfoColor = WPStyleGuide.lightBlue()

        public static let inactiveCellBackgroundColor = UIColor.whiteColor()
        public static let inactiveCellNameColor = WPStyleGuide.darkGrey()
        public static let inactiveCellPriceColor = WPStyleGuide.validGreen()

        // MARK: - Metrics

        public static let currentBarItemHeight: CGFloat = 53
        public static let currentBarHeightCompact: CGFloat = currentBarHeightRegular + currentBarItemHeight + 1
        public static let currentBarHeightRegular: CGFloat = currentBarItemHeight + (columnMargin * 2)

        public static let columnMargin: CGFloat = 16
        public static let minimumColumnWidth: CGFloat = 330

        public static let cellImageInset: CGFloat = 2
        public static let cellImageRatio: CGFloat = 0.75
        public static let cellInfoBarHeight: CGFloat = 55

        public static let footerHeight: CGFloat = 50
    }

}
