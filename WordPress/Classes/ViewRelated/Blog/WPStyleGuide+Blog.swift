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
        // TODO: make this dynamic size once @elibud's dynamic type code is merged
        cell.textLabel?.font = WPFontManager.systemSemiBoldFont(ofSize: 15.0)
        cell.textLabel?.sizeToFit()
        cell.textLabel?.textColor = .text

        cell.detailTextLabel?.font = UIFont.preferredFont(forTextStyle: .footnote)
        cell.detailTextLabel?.sizeToFit()
        cell.detailTextLabel?.textColor = .text

        cell.imageView?.layer.borderColor = UIColor.neutral(.shade10).cgColor
        cell.imageView?.layer.borderWidth = 1
        cell.imageView?.tintColor = .neutral(.shade30)

        cell.backgroundColor = .listBackground
    }

 }
