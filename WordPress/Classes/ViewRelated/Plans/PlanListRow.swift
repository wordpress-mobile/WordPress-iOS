import UIKit
import WordPressShared

struct PlanListRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(WPTableViewCellSubtitle.self)
    static let customHeight: Float? = 92

    let title: String
    let description: String

    let action: ImmuTableAction?

    func configureCell(_ cell: UITableViewCell) {
        WPStyleGuide.configureTableViewSmallSubtitleCell(cell)
        cell.textLabel?.attributedText = attributedTitle
        cell.textLabel?.adjustsFontSizeToFitWidth = true
        cell.detailTextLabel?.text = description
        cell.detailTextLabel?.textColor = WPStyleGuide.grey()
        cell.detailTextLabel?.font = WPFontManager.systemRegularFont(ofSize: 14.0)
        cell.separatorInset = UIEdgeInsets.zero
    }

    fileprivate var attributedTitle: NSAttributedString {
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: WPStyleGuide.tableviewTextFont(),
            .foregroundColor: WPStyleGuide.tableViewActionColor()
        ]
        return NSAttributedString(string: title, attributes: titleAttributes)
    }
}
