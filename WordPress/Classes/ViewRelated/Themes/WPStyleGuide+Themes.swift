import Foundation
import WordPressShared

/// A WPStyleGuide extension with styles and methods specific to the Themes feature.
///
extension WPStyleGuide {
    public struct Themes {
        // MARK: - Current Theme Styles

        public static let currentThemeBackgroundColor = UIColor.white
        public static let currentThemeDividerColor = WPStyleGuide.greyLighten30()

        public static let currentThemeLabelFont = WPFontManager.systemRegularFont(ofSize: 11)
        public static let currentThemeLabelColor = WPStyleGuide.greyDarken20()

        public static let currentThemeNameFont = WPFontManager.systemSemiBoldFont(ofSize: 14)
        public static let currentThemeNameColor = WPStyleGuide.darkGrey()

        public static let currentThemeButtonFont = WPFontManager.systemRegularFont(ofSize: 13)
        public static let currentThemeButtonColor = WPStyleGuide.darkGrey()

        public static func styleCurrentThemeButton(_ button: UIButton) {
            button.titleLabel?.font = currentThemeButtonFont
            button.setTitleColor(currentThemeButtonColor, for: UIControlState())
        }

        // MARK: - Search Styles

        public static let searchBarBackgroundColor = WPStyleGuide.lightGrey()
        public static let searchBarBorderColor = WPStyleGuide.greyLighten20()

        public static let searchTypeTitleFont = WPFontManager.systemSemiBoldFont(ofSize: 14)
        public static let searchTypeTitleColor = WPStyleGuide.darkGrey()

        public static func styleSearchTypeButton(_ button: UIButton, title: String) {
            button.setTitleColor(searchTypeTitleColor, for: UIControlState())
            button.setTitle(title, for: UIControlState())
            button.titleLabel?.font = searchTypeTitleFont
            let imageWidth = button.imageView?.frame.size.width ?? 0
            button.titleEdgeInsets = UIEdgeInsets(top: 0, left: -imageWidth, bottom: 0, right: imageWidth)
            let titleWidth = button.titleLabel?.frame.size.width ?? 0
            button.imageEdgeInsets = UIEdgeInsets(top: 0, left: titleWidth, bottom: 0, right: -titleWidth)
        }

        // MARK: - Cell Styles

        public static let cellNameFont = WPFontManager.systemSemiBoldFont(ofSize: 14)
        public static let cellInfoFont = WPFontManager.systemSemiBoldFont(ofSize: 12)

        public static let placeholderColor = WPStyleGuide.greyLighten20()

        public static let activeCellBackgroundColor = WPStyleGuide.mediumBlue()
        public static let activeCellBorderColor = WPStyleGuide.mediumBlue()
        public static let activeCellDividerColor = WPStyleGuide.lightBlue()
        public static let activeCellNameColor = UIColor.white
        public static let activeCellInfoColor = WPStyleGuide.lightBlue()

        public static let inactiveCellBackgroundColor = UIColor.white
        public static let inactiveCellBorderColor = WPStyleGuide.greyLighten20()
        public static let inactiveCellDividerColor = WPStyleGuide.greyLighten30()
        public static let inactiveCellNameColor = WPStyleGuide.darkGrey()
        public static let inactiveCellPriceColor = WPStyleGuide.validGreen()

        // MARK: - Metrics

        public static let currentBarLineHeight: CGFloat = 53
        public static let currentBarSeparator: CGFloat = 1
        public static let searchBarHeight: CGFloat = 53
        public static let cellBorderWidth: CGFloat = 1

        public static func headerHeight(_ horizontallyCompact: Bool, includingSearchBar: Bool) -> CGFloat {
            var headerHeight = (currentBarSeparator * 2)
            if includingSearchBar {
                headerHeight += searchBarHeight
            }
            if horizontallyCompact {
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

        public static func cellWidthForFrameWidth(_ width: CGFloat) -> CGFloat {
            let numberOfColumns = max(1, trunc(width / minimumColumnWidth))
            let numberOfMargins = numberOfColumns + 1
            let marginsWidth = numberOfMargins * columnMargin
            let columnsWidth = width - marginsWidth
            let columnWidth = trunc(columnsWidth / numberOfColumns)
            return columnWidth
        }
        public static func cellHeightForCellWidth(_ width: CGFloat) -> CGFloat {
            let imageHeight = (width - cellImageInset) * cellImageRatio
            return imageHeight + cellInfoBarHeight
        }
        public static func cellHeightForFrameWidth(_ width: CGFloat) -> CGFloat {
            let cellWidth = cellWidthForFrameWidth(width)
            return cellHeightForCellWidth(cellWidth)
        }
        public static func cellSizeForFrameWidth(_ width: CGFloat) -> CGSize {
            let cellWidth = cellWidthForFrameWidth(width)
            let cellHeight = cellHeightForCellWidth(cellWidth)
            return CGSize(width: cellWidth, height: cellHeight)
        }
        public static func imageWidthForFrameWidth(_ width: CGFloat) -> CGFloat {
            let cellWidth = cellWidthForFrameWidth(width)
            return cellWidth - cellImageInset
        }

        public static let footerHeight: CGFloat = 50

        public static let themeMargins = UIEdgeInsets(top: rowMargin, left: columnMargin, bottom: rowMargin, right: columnMargin)
        public static let infoMargins = UIEdgeInsets()

        public static let minimumSearchHeight: CGFloat = 44
        public static let searchAnimationDuration: TimeInterval = 0.2
    }

}
