import Foundation
import Gridicons

extension WPStyleGuide {
    // MARK: - Styles Used by Stats
    //
    class Stats {

        enum ImageTintColor: Int {
            case blue
            case grey

            var styleGuideColor: UIColor {
                switch self {
                case .blue:
                    return WPStyleGuide.mediumBlue()
                case .grey:
                    return WPStyleGuide.greyLighten10()
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

        static func configureBorderForView(_ borderedView: UIView) {
            borderedView.layer.borderColor = cellBorderColor
            borderedView.layer.borderWidth = cellBorderWidth
        }

        static func configureViewAsSeperator(_ seperatorView: UIView) {
            seperatorView.backgroundColor = seperatorColor
        }

        static func configureLabelAsHeader(_ label: UILabel) {
            label.textColor = defaultTextColor
            label.font = headerFont
        }

        static func configureLabelAsSummary(_ label: UILabel) {
            label.textColor = summaryTextColor
            label.font = summaryFont
        }

        static func configureLabelAsSubtitle(_ label: UILabel) {
            label.textColor = secondaryTextColor
            label.font = subTitleFont
            label.text = label.text?.localizedUppercase
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

        static func configureFilterTabBar(_ filterTabBar: FilterTabBar) {
            filterTabBar.tintColor = filterTintColor
            filterTabBar.deselectedTabColor = filterDeselectedColor
            filterTabBar.dividerColor = filterDividerColor
        }

        // MARK: - Style Values

        static let defaultTextColor = WPStyleGuide.darkGrey()
        static let secondaryTextColor = WPStyleGuide.grey()
        static let itemDetailTextColor = WPStyleGuide.greyDarken10()
        static let actionTextColor = WPStyleGuide.wordPressBlue()
        static let summaryTextColor = WPStyleGuide.darkGrey()
        static let substringHighlightTextColor = WPStyleGuide.wordPressBlue()

        static let headerFont = WPStyleGuide.fontForTextStyle(.headline, fontWeight: .semibold)
        static let subTitleFont = WPStyleGuide.fontForTextStyle(.footnote, fontWeight: .medium)
        static let summaryFont = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .regular)
        static let substringHighlightFont = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .semibold)

        static let tableBackgroundColor = WPStyleGuide.greyLighten30()
        static let cellBackgroundColor = WPStyleGuide.greyLighten30()
        static let cellBorderColor = WPStyleGuide.greyLighten20().cgColor
        static let cellBorderWidth = CGFloat(0.5)
        static let seperatorColor = WPStyleGuide.greyLighten20()

        static let filterTintColor = WPStyleGuide.wordPressBlue()
        static let filterDeselectedColor = WPStyleGuide.greyDarken10()
        static let filterDividerColor = WPStyleGuide.greyLighten20()

        static let gridiconSize = CGSize(width: 24, height: 24)
    }

}
