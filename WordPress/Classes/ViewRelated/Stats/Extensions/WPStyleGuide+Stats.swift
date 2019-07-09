import Foundation
import Gridicons

extension WPStyleGuide {
    // MARK: - Styles Used by Stats
    //
    class Stats {

        enum ImageTintColor: Int {
            case blue
            case grey
            case darkGrey

            var styleGuideColor: UIColor {
                switch self {
                case .blue:
                    return .primary(shade: .shade40)
                case .grey:
                    return .neutral(shade: .shade20)
                case .darkGrey:
                    return .neutral(shade: .shade70)
                }
            }
        }

        // MARK: - Style Methods

        static func configureTable(_ table: UITableView) {
            table.backgroundColor = tableBackgroundColor
            table.separatorStyle = .none
        }

        static func configureCell(_ cell: UITableViewCell) {
            cell.contentView.backgroundColor = cellBackgroundColor
        }

        static func configureViewAsSeparator(_ separatorView: UIView) {
            separatorView.backgroundColor = separatorColor
        }

        static func configureViewAsVerticalSeparator(_ separatorView: UIView) {
            separatorView.backgroundColor = verticalSeparatorColor
        }

        static func configureViewAsDataBar(_ dataBar: UIView) {
            dataBar.backgroundColor = separatorColor
            dataBar.layer.cornerRadius = dataBar.frame.height * 0.5
        }

        static func configureLabelAsHeader(_ label: UILabel) {
            label.textColor = headerTextColor
            label.text = label.text?.localizedUppercase
        }

        static func configureLabelAsSummary(_ label: UILabel) {
            label.textColor = summaryTextColor
            label.font = summaryFont
        }

        static func configureLabelAsSubtitle(_ label: UILabel) {
            label.textColor = secondaryTextColor
            label.font = subTitleFont
        }

        static func configureLabelItemDetail(_ label: UILabel) {
            label.textColor = itemDetailTextColor
        }

        static func configureLabelAsCellRowTitle(_ label: UILabel) {
            label.textColor = defaultTextColor
        }

        static func configureLabelAsData(_ label: UILabel) {
            label.textColor = secondaryTextColor
        }

        static func configureLabelAsChildRowTitle(_ label: UILabel) {
            label.textColor = secondaryTextColor
        }

        static func configureLabelAsNoData(_ label: UILabel) {
            label.textColor = secondaryTextColor
        }

        static func configureLabelAsPostingMonth(_ label: UILabel) {
            label.textColor = defaultTextColor
            label.font = subTitleFont
        }

        static func configureLabelAsPostingLegend(_ label: UILabel) {
            label.textColor = defaultTextColor
        }

        static func configureLabelAsPostingDate(_ label: UILabel) {
            label.textColor = defaultTextColor
        }

        static func configureLabelAsPostingCount(_ label: UILabel) {
            label.textColor = secondaryTextColor
        }

        static func configureLabelAsTotalCount(_ label: UILabel) {
            label.textColor = defaultTextColor
        }

        static func configureLabelAsPostStatsTitle(_ label: UILabel) {
            label.textColor = defaultTextColor
        }

        static func configureLabelAsPostTitle(_ label: UILabel) {
            label.textColor = defaultTextColor
            label.font = postTitleFont
        }

        static func configureLabelForOverview(_ label: UILabel) {
            label.textColor = defaultTextColor
        }

        static func highlightString(_ subString: String, inString: String) -> NSAttributedString {
            let attributedString = NSMutableAttributedString(string: inString)

            guard let subStringRange = inString.nsRange(of: subString) else {
                return attributedString
            }

            attributedString.addAttributes( [
                .foregroundColor: substringHighlightTextColor,
                .font: substringHighlightFont
                ], range: subStringRange)

            return attributedString
        }

        static func imageForGridiconType(_ iconType: GridiconType, withTint tintColor: ImageTintColor = .grey) -> UIImage? {
            return Gridicon.iconOfType(iconType, withSize: gridiconSize).imageWithTintColor(tintColor.styleGuideColor)
        }

        static func gravatarPlaceholderImage() -> UIImage? {
            return UIImage(named: "gravatar")
        }

        static func configureFilterTabBar(_ filterTabBar: FilterTabBar,
                                          forTabbedCard: Bool = false,
                                          forOverviewCard: Bool = false) {
            filterTabBar.dividerColor = filterDividerColor
            filterTabBar.deselectedTabColor = filterDeselectedColor
            filterTabBar.tintColor = defaultFilterTintColor

            // For FilterTabBar on TabbedTotalsCell
            if forTabbedCard {
                filterTabBar.tabSizingStyle = .equalWidths
                filterTabBar.tintColor = tabbedCardFilterTintColor
                filterTabBar.selectedTitleColor = tabbedCardFilterSelectedTitleColor
            }

            // For FilterTabBar on OverviewCell
            if forOverviewCard {
                filterTabBar.tabSizingStyle = .equalWidths
                filterTabBar.tintColor = defaultFilterTintColor
                filterTabBar.selectedTitleColor = tabbedCardFilterSelectedTitleColor
            }
        }

        // MARK: - Style Values

        static let defaultTextColor = UIColor.neutral(shade: .shade70)
        static let headerTextColor = UIColor.neutral(shade: .shade50)
        static let secondaryTextColor = UIColor.neutral(shade: .shade30)
        static let itemDetailTextColor = UIColor.neutral(shade: .shade40)
        static let actionTextColor = UIColor.primary
        static let summaryTextColor = UIColor.neutral(shade: .shade70)
        static let substringHighlightTextColor = UIColor.primary
        static let iconLoadingBackgroundColor = UIColor.neutral(shade: .shade10)

        static let subTitleFont = WPStyleGuide.fontForTextStyle(.footnote, fontWeight: .medium)
        static let summaryFont = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .regular)
        static let substringHighlightFont = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .semibold)

        static let tableBackgroundColor = UIColor.neutral(shade: .shade5)
        static let cellBackgroundColor = UIColor.white
        static let separatorColor = UIColor.neutral(shade: .shade10)
        static let verticalSeparatorColor = UIColor.neutral(shade: .shade5)

        static let defaultFilterTintColor: UIColor = .primary
        static let tabbedCardFilterTintColor = UIColor.neutral(shade: .shade10)
        static let tabbedCardFilterSelectedTitleColor = UIColor.neutral(shade: .shade70)
        static let filterDeselectedColor = UIColor.neutral(shade: .shade40)
        static let filterDividerColor = UIColor.neutral(shade: .shade10)

        static let overviewCardFilterTitleFont = WPStyleGuide.fontForTextStyle(.caption2, fontWeight: .regular)
        static let overviewCardFilterDataFont = WPStyleGuide.fontForTextStyle(.headline, fontWeight: .semibold)

        static let postTitleFont = WPFontManager.notoBoldFont(ofSize: 17.0)

        static let positiveColor = UIColor.success
        static let negativeColor = UIColor.error

        static let gridiconSize = CGSize(width: 24, height: 24)

        struct PostingActivityColors {
            static let lightGrey = UIColor.neutral(shade: .shade10)
            static let lightBlue = UIColor(fromRGBAColorWithRed: 145.0, green: 226.0, blue: 251.0, alpha: 1)
            static let mediumBlue = UIColor(fromRGBAColorWithRed: 0.0, green: 190.0, blue: 246.0, alpha: 1)
            static let darkBlue = UIColor(fromRGBAColorWithRed: 0.0, green: 131.0, blue: 169.0, alpha: 1)
            static let darkGrey = UIColor.neutral(shade: .shade70)
            static let orange = UIColor(fromRGBAColorWithRed: 245.0, green: 131.0, blue: 53.0, alpha: 1)
        }

        // MARK: - Posting Activity Collection View Styles

        // Value of PostingActivityMonth view width for five columns
        static let minimumColumnWidth: CGFloat = 104
        // Value of PostingActivityMonth view height
        static let cellHeight: CGFloat = 135

        static func cellSizeForFrameWidth(_ width: CGFloat) -> CGSize {
            let cellWidth = cellWidthForFrameWidth(width)
            return CGSize(width: cellWidth.zeroIfNaN(), height: cellHeight.zeroIfNaN())
        }

        static func cellWidthForFrameWidth(_ width: CGFloat) -> CGFloat {
            let numberOfColumns = max(1, trunc(width / minimumColumnWidth))
            let columnWidth = trunc(width / numberOfColumns)
            return columnWidth
        }
    }

}
