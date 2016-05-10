import Foundation
import WordPressShared

extension WPStyleGuide
{
    // MARK: - Styles Used by the WordPress Share Extension
    //
    class Share
    {
        static let blavatarPlaceholderImage = UIImage(named: "blavatar-default")

        static func configureBlogTableViewCell(cell: UITableViewCell) {
            WPStyleGuide.configureTableViewCell(cell)
            cell.backgroundColor = UIColor.clearColor()
            cell.imageView?.backgroundColor = WPStyleGuide.lightGrey()
            cell.imageView?.layer.borderColor = UIColor.whiteColor().CGColor
            cell.imageView?.layer.borderWidth = 1.5
            cell.detailTextLabel?.font = WPStyleGuide.subtitleFont()
            cell.detailTextLabel?.textColor = WPStyleGuide.greyDarken10()
        }
    }
}
