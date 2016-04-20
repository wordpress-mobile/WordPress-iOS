import Foundation
import WordPressShared

/**
    A WPStyleGuide extension with styles and methods specific to the
    Themes feature.
*/
extension WPStyleGuide
{
    public struct Themes
    {
        // MARK: - Current Theme Styles

        public static let currentThemeBackgroundColor = UIColor.whiteColor()
        public static let currentThemeDividerColor = WPStyleGuide.greyLighten30()

        public static let currentThemeLabelFont = WPFontManager.systemRegularFontOfSize(11)
        public static let currentThemeLabelColor = WPStyleGuide.greyDarken20()
        
        public static let currentThemeNameFont = WPFontManager.systemSemiBoldFontOfSize(14)
        public static let currentThemeNameColor = WPStyleGuide.darkGrey()

        public static let currentThemeButtonFont = WPFontManager.systemRegularFontOfSize(13)
        public static let currentThemeButtonColor = WPStyleGuide.darkGrey()
        
        public static func styleCurrentThemeButton(button: UIButton) {
            button.titleLabel?.font = currentThemeButtonFont
            button.setTitleColor(currentThemeButtonColor, forState: .Normal)
        }
        
        // MARK: - Search Styles

        public static let searchBarBackgroundColor = WPStyleGuide.lightGrey()
        public static let searchBarBorderColor = WPStyleGuide.greyLighten20()

        public static let searchTypeTitleFont = WPFontManager.systemSemiBoldFontOfSize(14)
        public static let searchTypeTitleColor = WPStyleGuide.darkGrey()

        public static func styleSearchTypeButton(button: UIButton, title: String) {
            button.setTitleColor(searchTypeTitleColor, forState: .Normal)
            button.setTitle(title, forState:.Normal)
            button.titleLabel?.font = searchTypeTitleFont
            let imageWidth = button.imageView?.frame.size.width ?? 0
            button.titleEdgeInsets = UIEdgeInsets(top: 0, left: -imageWidth, bottom: 0, right: imageWidth)
            let titleWidth = button.titleLabel?.frame.size.width ?? 0
            button.imageEdgeInsets = UIEdgeInsets(top: 0, left: titleWidth, bottom: 0, right: -titleWidth)
        }

        // MARK: - Cell Styles

        public static let cellNameFont = WPFontManager.systemSemiBoldFontOfSize(14)
        public static let cellInfoFont = WPFontManager.systemSemiBoldFontOfSize(12)

        public static let placeholderColor = WPStyleGuide.greyLighten20()

        public static let activeCellBackgroundColor = WPStyleGuide.mediumBlue()
        public static let activeCellBorderColor = WPStyleGuide.mediumBlue()
        public static let activeCellDividerColor = WPStyleGuide.lightBlue()
        public static let activeCellNameColor = UIColor.whiteColor()
        public static let activeCellInfoColor = WPStyleGuide.lightBlue()

        public static let inactiveCellBackgroundColor = UIColor.whiteColor()
        public static let inactiveCellBorderColor = WPStyleGuide.greyLighten20()
        public static let inactiveCellDividerColor = WPStyleGuide.greyLighten30()
        public static let inactiveCellNameColor = WPStyleGuide.darkGrey()
        public static let inactiveCellPriceColor = WPStyleGuide.validGreen()

        // MARK: - Metrics

        public static let currentBarLineHeight: CGFloat = 53
        public static let currentBarSeparator: CGFloat = 1
        public static let searchBarHeight: CGFloat = 53
       
        public static func headerHeight(horizontallyCompact: Bool) -> CGFloat {
            var headerHeight = searchBarHeight + (currentBarSeparator * 2)
            if (horizontallyCompact) {
                headerHeight += (currentBarLineHeight * 2) + currentBarSeparator
            } else {
                headerHeight += currentBarLineHeight
            }
            return headerHeight
        }

        public static let columnMargin: CGFloat = 7
        public static let rowMargin: CGFloat = 10
        public static let minimumColumnWidth: CGFloat = 330

        public static let cellImageInset: CGFloat = 2
        public static let cellImageRatio: CGFloat = 0.75
        public static let cellInfoBarHeight: CGFloat = 55
        
        public static func cellWidthForFrameWidth(width: CGFloat) -> CGFloat {
            let numberOfColumns = max(1, trunc(width / minimumColumnWidth))
            let numberOfMargins = numberOfColumns + 1
            let marginsWidth = numberOfMargins * columnMargin
            let columnsWidth = width - marginsWidth
            let columnWidth = trunc(columnsWidth / numberOfColumns)
            return columnWidth
        }
        public static func cellHeightForCellWidth(width: CGFloat) -> CGFloat {
            let imageHeight = (width - cellImageInset) * cellImageRatio
            return imageHeight + cellInfoBarHeight
        }
        public static func cellHeightForFrameWidth(width: CGFloat) -> CGFloat {
            let cellWidth = cellWidthForFrameWidth(width)
            return cellHeightForCellWidth(cellWidth)
        }
        public static func cellSizeForFrameWidth(width: CGFloat) -> CGSize {
            let cellWidth = cellWidthForFrameWidth(width)
            let cellHeight = cellHeightForCellWidth(cellWidth)
            return CGSize(width: cellWidth, height: cellHeight)
        }
        public static func imageWidthForFrameWidth(width: CGFloat) -> CGFloat {
            let cellWidth = cellWidthForFrameWidth(width)
            return cellWidth - cellImageInset
        }

        public static let footerHeight: CGFloat = 50

        public static let themeMargins = UIEdgeInsets(top: rowMargin, left: columnMargin, bottom: rowMargin, right: columnMargin)
        public static let infoMargins = UIEdgeInsets()
        
        public static let minimumSearchHeight: CGFloat = 44
        public static let searchAnimationDuration: NSTimeInterval = 0.2
    }

}
