import Foundation
import WordPressShared

extension WPStyleGuide {
    @objc public class func configureTableViewBlogCell(_ cell: UITableViewCell) {
        cell.textLabel?.font = tableviewTextFont()
        cell.textLabel?.sizeToFit()
        cell.textLabel?.textColor = .text

        cell.detailTextLabel?.font = self.subtitleFont()
        cell.detailTextLabel?.sizeToFit()
        cell.detailTextLabel?.textColor = .textSubtle

        cell.imageView?.layer.borderColor = UIColor.white.cgColor
        cell.imageView?.layer.borderWidth = 1
        cell.imageView?.tintColor = .listIcon

        cell.backgroundColor = UIColor.listForeground
    }

    @objc public class func configureCellForLogin(_ cell: WPBlogTableViewCell) {
        cell.textLabel?.textColor = .text
        cell.textLabel?.font = fontForTextStyle(.subheadline, fontWeight: .medium)

        cell.detailTextLabel?.textColor = .textSubtle
        cell.detailTextLabel?.font = fontForTextStyle(.subheadline)

        cell.imageView?.layer.borderColor = UIColor.neutral(.shade10).cgColor
        cell.imageView?.layer.borderWidth = 1
        cell.imageView?.tintColor = .neutral(.shade30)

        cell.backgroundColor = .basicBackground
    }

 }
