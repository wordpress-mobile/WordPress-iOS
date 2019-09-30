import UIKit
import WordPressShared

struct PlanListRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(WPTableViewCellSubtitle.self)
    static let customHeight: Float? = 92
    fileprivate let iconSize = CGSize(width: 60, height: 60)

    let title: String
    let description: String
    let icon: String

    let action: ImmuTableAction?

    func configureCell(_ cell: UITableViewCell) {
        WPStyleGuide.configureTableViewSmallSubtitleCell(cell)
        if let iconURL = URL(string: icon) {
            cell.imageView?.downloadResizedImage(from: iconURL, placeholderImage: UIImage(named: "plan-placeholder")!, pointSize: iconSize)
        } else {
            cell.imageView?.image = UIImage(named: "plan-placeholder")
        }
        cell.textLabel?.attributedText = attributedTitle
        cell.textLabel?.adjustsFontSizeToFitWidth = true
        cell.detailTextLabel?.text = description
        cell.detailTextLabel?.textColor = .textSubtle
        cell.detailTextLabel?.font = WPFontManager.systemRegularFont(ofSize: 14.0)
        cell.separatorInset = UIEdgeInsets.zero
        cell.backgroundColor = .listForeground
    }

    fileprivate var attributedTitle: NSAttributedString {
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: WPStyleGuide.tableviewTextFont(),
            .foregroundColor: UIColor.primary
        ]
        return NSAttributedString(string: title, attributes: titleAttributes)
    }
}
