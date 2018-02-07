import Foundation
import WordPressUIKit

extension WPStyleGuide {
    // MARK: - Styles Used by the WordPress Share Extension
    //
    class Share {
        static let blavatarPlaceholderImage = UIImage(named: "blavatar-default")

        static func configureTableViewSummaryCell(_ cell: UITableViewCell) {
            cell.textLabel?.font = tableviewTextFont()
            cell.textLabel?.sizeToFit()
            cell.textLabel?.textColor = darkGrey()

            cell.backgroundColor = UIColor.clear
            cell.separatorInset = UIEdgeInsets.zero
        }

        static func configureTableViewSiteCell(_ cell: UITableViewCell) {
            cell.textLabel?.font = tableviewTextFont()
            cell.textLabel?.sizeToFit()
            cell.textLabel?.textColor = darkGrey()

            cell.detailTextLabel?.font = subtitleFont()
            cell.detailTextLabel?.sizeToFit()
            cell.detailTextLabel?.textColor = greyDarken10()

            cell.imageView?.layer.borderColor = UIColor.white.cgColor
            cell.imageView?.layer.borderWidth = 1
            cell.imageView?.tintColor = greyLighten10()

            cell.backgroundColor = UIColor.white
            cell.tintColor = wordPressBlue()
        }
    }
}
