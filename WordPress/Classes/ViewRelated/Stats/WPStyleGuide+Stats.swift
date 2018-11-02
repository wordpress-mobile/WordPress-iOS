import Foundation
import Gridicons

extension WPStyleGuide {
    // MARK: - Styles Used by Stats
    //
    class Stats {

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

        static func configureLabelAsHeader(_ label: UILabel) {
            label.textColor = defaultTextColor
            label.font = headerFont
        }

        static func configureLabelAsSummary(_ label: UILabel) {
            label.textColor = summaryTextColor
            label.font = summaryFont
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

        static func imageForGridiconType(_ iconType: GridiconType) -> UIImage? {
            return Gridicon.iconOfType(iconType).imageWithTintColor(imageTintColor)
        }

        static func configureFilterTabBar(_ filterTabBar: FilterTabBar) {
            filterTabBar.tintColor = filterTintColor
            filterTabBar.deselectedTabColor = filterDeselectedColor
            filterTabBar.dividerColor = filterDividerColor
        }

        // MARK: - Style Values

        static let defaultTextColor = WPStyleGuide.darkGrey()
        static let actionTextColor = WPStyleGuide.wordPressBlue()
        static let summaryTextColor = WPStyleGuide.darkGrey()
        static let substringHighlightTextColor = WPStyleGuide.wordPressBlue()

        static let imageTintColor = WPStyleGuide.mediumBlue()

        static let headerFont = WPStyleGuide.fontForTextStyle(.headline, fontWeight: .semibold)
        static let summaryFont = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .regular)
        static let substringHighlightFont = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .semibold)

        static let tableBackgroundColor = WPStyleGuide.greyLighten30()
        static let cellBackgroundColor = WPStyleGuide.greyLighten30()
        static let cellBorderColor = WPStyleGuide.greyLighten20().cgColor
        static let cellBorderWidth = CGFloat(0.5)

        static let filterTintColor = WPStyleGuide.wordPressBlue()
        static let filterDeselectedColor = WPStyleGuide.greyDarken10()
        static let filterDividerColor = WPStyleGuide.greyLighten20()
    }

}
