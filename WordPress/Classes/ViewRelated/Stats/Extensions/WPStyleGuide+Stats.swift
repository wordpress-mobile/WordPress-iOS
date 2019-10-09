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
            case icon

            var styleGuideColor: UIColor {
                switch self {
                case .blue:
                    return .primary(.shade40)
                case .grey:
                    return .textQuaternary
                case .darkGrey:
                    return .textSubtle
                case .icon:
                    return .listIcon
                }
            }
        }

        // MARK: - Style Methods

        static func configureTable(_ table: UITableView) {
            table.backgroundColor = tableBackgroundColor
            table.separatorStyle = .none
        }

        static func configureCell(_ cell: UITableViewCell) {
            cell.backgroundColor = tableBackgroundColor
            cell.contentView.backgroundColor = cellBackgroundColor
        }

        static func configureHeaderCell(_ cell: UITableViewCell) {
            cell.backgroundColor = tableBackgroundColor
            cell.contentView.backgroundColor = tableBackgroundColor
        }

        static func configureViewAsSeparator(_ separatorView: UIView) {
            separatorView.backgroundColor = separatorColor
            separatorView.constraints.first(where: { $0.firstAttribute == .height })?.isActive = false
            separatorView.heightAnchor.constraint(equalToConstant: separatorHeight).isActive = true
        }

        static func configureViewAsVerticalSeparator(_ separatorView: UIView) {
            separatorView.backgroundColor = verticalSeparatorColor
        }

        static func configureViewAsDataBar(_ dataBar: UIView) {
            dataBar.backgroundColor = dataBarColor
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
            label.textColor = defaultTextColor
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

        static func configureLabelAsCustomizeTitle(_ label: UILabel) {
            label.textColor = defaultTextColor
            label.font = customizeInsightsTitleFont
        }

        static func configureAsCustomizeDismissButton(_ button: UIButton) {
            button.setTitleColor(customizeInsightsButtonTextColor, for: .normal)
            button.titleLabel?.font = customizeInsightsDismissButtonFont
        }

        static func configureAsCustomizeTryButton(_ button: UIButton) {
            button.setTitleColor(customizeInsightsButtonTextColor, for: .normal)
            button.titleLabel?.font = customizeInsightsTryButtonFont
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
            WPStyleGuide.configureFilterTabBar(filterTabBar)

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

        static let defaultTextColor = UIColor.text
        static let headerTextColor = UIColor.textSubtle
        static let secondaryTextColor = UIColor.textSubtle
        static let itemDetailTextColor = UIColor.textSubtle
        static let actionTextColor = UIColor.primary
        static let summaryTextColor = UIColor.neutral(.shade70)
        static let substringHighlightTextColor = UIColor.primary
        static let iconLoadingBackgroundColor = UIColor.neutral(.shade10)

        static let subTitleFont = WPStyleGuide.fontForTextStyle(.footnote, fontWeight: .medium)
        static let summaryFont = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .regular)
        static let substringHighlightFont = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .semibold)

        static let tableBackgroundColor = UIColor.listBackground
        static let cellBackgroundColor = UIColor.listForeground
        static let separatorColor = UIColor.divider
        static let dataBarColor = UIColor.textTertiary
        static let separatorHeight: CGFloat = 1.0 / UIScreen.main.scale
        static let verticalSeparatorColor = UIColor.neutral(.shade5)

        static let defaultFilterTintColor = UIColor.filterBarSelected
        static let tabbedCardFilterTintColor = UIColor.filterBarSelected
        static let tabbedCardFilterSelectedTitleColor = UIColor.filterBarSelected

        static let overviewCardFilterTitleFont = WPStyleGuide.fontForTextStyle(.caption2, fontWeight: .regular)
        static let overviewCardFilterDataFont = WPStyleGuide.fontForTextStyle(.headline, fontWeight: .semibold)

        static let postTitleFont = WPFontManager.notoBoldFont(ofSize: 17.0)

        static let customizeInsightsTitleFont = WPStyleGuide.fontForTextStyle(.title3, fontWeight: .semibold)
        static let customizeInsightsButtonTextColor = UIColor.primary
        static let customizeInsightsDismissButtonFont = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        static let customizeInsightsTryButtonFont = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .medium)

        static let manageInsightsButtonTintColor = UIColor.textSubtle

        static let positiveColor = UIColor.success
        static let negativeColor = UIColor.error

        static let gridiconSize = CGSize(width: 24, height: 24)

        struct PostingActivityColors {
            static let range1 = UIColor(light: .neutral(.shade5), dark: .neutral(.shade10))
            static let range2 = UIColor.primary(.shade5)
            static let range3 = UIColor.primaryLight
            static let range4 = UIColor.primary
            static let range5 = UIColor.primaryDark
            static let selectedDay = UIColor.accent
        }

        static var mapBackground: UIColor {
            if #available(iOS 13, *) {
                return .systemGray4
            }
            return .neutral(.shade10)
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
