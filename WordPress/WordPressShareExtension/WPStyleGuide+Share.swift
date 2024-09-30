import Foundation
import WordPressShared

extension WPStyleGuide {
    // MARK: - Styles Used by the WordPress Share Extension
    //
    class Share {
        static let blavatarPlaceholderImage = UIImage(named: "blavatar-default")

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

        static func configureTableViewSiteCell(_ cell: UITableViewCell) {
            cell.textLabel?.font = tableviewTextFont()
            cell.textLabel?.sizeToFit()
            cell.textLabel?.textColor = .label
            cell.textLabel?.numberOfLines = 0

            cell.detailTextLabel?.font = subtitleFont()
            cell.detailTextLabel?.sizeToFit()
            cell.detailTextLabel?.textColor = .secondaryLabel
            cell.detailTextLabel?.numberOfLines = 0

            cell.imageView?.layer.borderColor = UIColor.white.cgColor
            cell.imageView?.layer.borderWidth = 1
            cell.imageView?.tintColor = UIAppColor.neutral(.shade30)

            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.tintColor = UIAppColor.primary
        }
    }
}
