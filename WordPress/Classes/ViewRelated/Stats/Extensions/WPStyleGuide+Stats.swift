import Foundation
import Gridicons
import DesignSystem
import WordPressShared

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
                    return UIAppColor.primary(.shade40)
                case .grey:
                    return .quaternaryLabel
                case .darkGrey:
                    return .secondaryLabel
                case .icon:
                    return .secondaryLabel
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
            separatorView.backgroundColor = .clear
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
            label.textColor = .secondaryLabel
            label.font = .DS.font(.footnote)
            label.adjustsFontSizeToFitWidth = true
            label.maximumContentSizeCategory = .extraExtraExtraLarge
        }

        static func configureLabelAsLink(_ label: UILabel) {
            label.textColor = actionTextColor
        }

        static func configureLabelItemDetail(_ label: UILabel) {
            label.textColor = itemDetailTextColor
        }

        static func configureLabelAsCellRowTitle(_ label: UILabel) {
            label.textColor = defaultTextColor
            label.numberOfLines = 0
        }

        static func configureLabelAsCellValueTitle(_ label: UILabel) {
            label.font = UIFont.DS.font(.footnote)
            label.textColor = .secondaryLabel
        }

        static func configureLabelAsCellValue(_ label: UILabel) {
            label.font = UIFont.DS.font(.heading2).semibold()
            label.textColor = .label
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
            label.adjustsFontSizeToFitWidth = true
            label.numberOfLines = 0
            label.lineBreakMode = .byClipping
        }

        static func configureLabelAsPostingLegend(_ label: UILabel) {
            label.textColor = defaultTextColor
            label.numberOfLines = 0
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

        static func imageForGridiconType(_ iconType: GridiconType, withTint tintColor: ImageTintColor = .grey) -> UIImage? {
            return UIImage.gridicon(iconType, size: gridiconSize).imageWithTintColor(tintColor.styleGuideColor)
        }

        static func gravatarPlaceholderImage() -> UIImage? {
            return UIImage(named: "gravatar")
        }

        static func configureFilterTabBar(_ filterTabBar: FilterTabBar,
                                          forTabbedCard: Bool = false,
                                          forOverviewCard: Bool = false,
                                          forNewInsightsCard: Bool = false) {
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

            // For FilterTabBar on StatsInsights
            if forNewInsightsCard {
                filterTabBar.tabSizingStyle = .fitting
                filterTabBar.tintColor = UIColor.label
                filterTabBar.selectedTitleColor = UIColor.label
                filterTabBar.backgroundColor = .secondarySystemGroupedBackground
                filterTabBar.deselectedTabColor = UIColor(light: UIAppColor.neutral(.shade20), dark: UIAppColor.neutral(.shade50))
            }
        }

        // MARK: - Font Size

        static let maximumChartAxisFontPointSize: CGFloat = 18

        // MARK: - Style Values

        static let defaultTextColor = UIColor.label
        static let headerTextColor = UIColor.secondaryLabel
        static let secondaryTextColor = UIColor.secondaryLabel
        static let itemDetailTextColor = UIColor.secondaryLabel
        static let actionTextColor = UIAppColor.primary
        static let summaryTextColor = UIAppColor.neutral(.shade70)
        static let iconLoadingBackgroundColor = UIAppColor.neutral(.shade10)

        static let subTitleFont = WPStyleGuide.fontForTextStyle(.footnote, fontWeight: .medium)
        static let summaryFont = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .regular)
        static let insightsCountFont = UIFont.preferredFont(forTextStyle: .title1).bold()

        static let tableBackgroundColor = UIColor.systemGroupedBackground
        static let cellBackgroundColor = UIColor.secondarySystemGroupedBackground
        static let separatorColor = UIColor.separator
        static let dataBarColor = UIColor.tertiaryLabel
        static let separatorHeight: CGFloat = 1.0 / UIScreen.main.scale
        static let verticalSeparatorColor = UIColor.separator

        static let defaultFilterTintColor = UIColor.label
        static let tabbedCardFilterTintColor = UIColor.label
        static let tabbedCardFilterSelectedTitleColor = UIColor.label

        static let overviewCardFilterTitleFont = WPStyleGuide.fontForTextStyle(.caption2, fontWeight: .regular)
        static let overviewCardFilterDataFont = WPStyleGuide.fontForTextStyle(.headline, fontWeight: .semibold)

        static let postTitleFont = WPFontManager.notoBoldFont(ofSize: 17.0)

        static let customizeInsightsTitleFont = WPStyleGuide.fontForTextStyle(.title3, fontWeight: .semibold)
        static let customizeInsightsButtonTextColor = UIAppColor.primary
        static let customizeInsightsDismissButtonFont = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        static let customizeInsightsTryButtonFont = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .medium)

        static let positiveColor = UIAppColor.success
        static let negativeColor = UIAppColor.error
        static let neutralColor = UIAppColor.blue

        static let gridiconSize = CGSize(width: 24, height: 24)

        struct PostingActivityColors {
            static let range1 = UIColor(light: UIAppColor.neutral(.shade5), dark: UIAppColor.neutral(.shade10))
            static let range2 = UIAppColor.primary(.shade5)
            static let range3 = UIAppColor.primaryLight
            static let range4 = UIAppColor.primary
            static let range5 = UIAppColor.primaryDark
            static let selectedDay = UIAppColor.accent
        }

        static let mapBackground: UIColor = .systemGray4

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

        // MARK: - Referrer Details
        struct ReferrerDetails {
            static let standardCellSpacing: CGFloat = 16
            static let headerCellVerticalPadding: CGFloat = 7
            static let standardCellVerticalPadding: CGFloat = 11
        }
    }

}
