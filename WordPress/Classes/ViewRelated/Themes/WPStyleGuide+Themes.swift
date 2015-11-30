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
        // MARK: - Bar Styles

        public static let barBorderColor = UIColor(red: 208.0/255.0, green: 220.0/255.0, blue: 229.0/255.0, alpha: 1)
        public static let barDividerColor = UIColor(red: 224.0/255.0, green: 239.0/255.0, blue: 233.0/255.0, alpha: 1)
        public static let barBackgroundColor = UIColor.whiteColor()
        public static let barContentInset = 15

        public static func styleBar(view: UIView, background: UIColor) {
            view.layer.borderWidth = 1
            view.layer.borderColor = barBorderColor.CGColor
            view.backgroundColor = background
        }
        
        // MARK: - Current Theme Styles

        public static let currentThemeLabelFont = WPFontManager.openSansRegularFontOfSize(11)
        public static let currentThemeLabelColor = WPStyleGuide.greyDarken20()
        
        public static let currentThemeNameFont = WPFontManager.openSansSemiBoldFontOfSize(14)
        public static let currentThemeNameColor = WPStyleGuide.darkGrey()

        public static let currentThemeButtonFont = WPFontManager.openSansRegularFontOfSize(13)
        public static let currentThemeButtonColor = WPStyleGuide.darkGrey()
        
        public static func styleCurrentThemeButton(button: UIButton) {
            button.titleLabel?.font = currentThemeButtonFont
            button.setTitleColor(currentThemeButtonColor, forState: .Normal)
        }
        
        // MARK: - Search Styles

        public static let searchTypeTitleFont = WPFontManager.openSansSemiBoldFontOfSize(14)
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

        public static let rowMargin: CGFloat = 16
        public static let currentBarLineHeight: CGFloat = 53
        public static let currentBarSeparator: CGFloat = 1
        public static let searchBarHeight: CGFloat = 53
       
        public static func headerHeight(horizontallyCompact: Bool) -> CGFloat {
            var headerHeight = searchBarHeight + (rowMargin * 3)
            if (horizontallyCompact) {
                headerHeight += (currentBarLineHeight * 2) + currentBarSeparator
            } else {
                headerHeight += currentBarLineHeight
            }
            return headerHeight
        }

        public static let columnMargin: CGFloat = 16
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

        public static let footerHeight: CGFloat = 50

        public static let searchMargins = UIEdgeInsets(top: rowMargin, left: columnMargin, bottom: rowMargin, right: columnMargin)
        public static let syncingMargins = UIEdgeInsets(top: 0, left:columnMargin, bottom: 0, right: columnMargin)
        public static let syncedMargins = UIEdgeInsets(top: 0, left:columnMargin, bottom: rowMargin, right: columnMargin)
    }

}
