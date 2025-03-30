import Foundation
import WordPressShared
import WordPressUI

extension WPStyleGuide {
    // MARK: - Styles Used by the WordPress Share Extension
    //
    class Share {
        static func configureModuleCell(_ cell: UITableViewCell) {
            cell.textLabel?.font = tableviewTextFont()
            cell.textLabel?.sizeToFit()
            cell.textLabel?.textColor = .label

            cell.detailTextLabel?.font = .preferredFont(forTextStyle: .callout)
            cell.detailTextLabel?.sizeToFit()
            cell.detailTextLabel?.textColor = .secondaryLabel

            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.separatorInset = UIEdgeInsets.zero
        }

        static func configureCategoryCell(_ cell: UITableViewCell) {
            cell.textLabel?.font = tableviewTextFont()
            cell.textLabel?.sizeToFit()
            cell.textLabel?.textColor = .label
            cell.textLabel?.numberOfLines = 0

            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.separatorInset = UIEdgeInsets.zero
            cell.tintColor = UIAppColor.primary
        }

        static func configureTagCell(_ cell: UITableViewCell) {
            cell.textLabel?.font = tableviewTextFont()
            cell.textLabel?.sizeToFit()
            cell.textLabel?.textColor = .label

            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.separatorInset = UIEdgeInsets.zero
        }

        static func configurePostTypeCell(_ cell: UITableViewCell) {
            cell.textLabel?.font = tableviewTextFont()
            cell.textLabel?.sizeToFit()
            cell.textLabel?.textColor = .label
            cell.textLabel?.numberOfLines = 0

            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.separatorInset = UIEdgeInsets.zero
            cell.tintColor = UIAppColor.primary
        }

        static func configureLoadingTagCell(_ cell: UITableViewCell) {
            cell.textLabel?.font = tableviewTextFont()
            cell.textLabel?.sizeToFit()
            cell.textLabel?.textColor = .label

            cell.backgroundColor = UIAppColor.neutral(.shade5)
            cell.separatorInset = UIEdgeInsets.zero
        }

        static func configureTableViewSummaryCell(_ cell: UITableViewCell) {
            cell.textLabel?.font = tableviewTextFont()
            cell.textLabel?.sizeToFit()
            cell.textLabel?.textColor = .label

            cell.backgroundColor = UIColor.clear
            cell.separatorInset = UIEdgeInsets.zero
        }
    }
}
