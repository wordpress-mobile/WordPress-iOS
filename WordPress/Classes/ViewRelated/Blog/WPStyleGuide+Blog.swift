import Foundation
import WordPressShared

extension WPStyleGuide {
    public class func configureTableViewBlogCell(_ cell: UITableViewCell) {
        configureTableViewCell(cell)
        cell.detailTextLabel?.font = self.subtitleFont()
        cell.detailTextLabel?.textColor = self.greyDarken10()
        cell.backgroundColor = UIColor.white

        cell.imageView?.layer.borderColor = UIColor.white.cgColor
        cell.imageView?.layer.borderWidth = 1
    }

    public class func cellGridiconAccessoryColor() -> UIColor {
        return UIColor(red: 200.0 / 255.0, green: 200.0 / 255.0, blue: 205.0 / 255.0, alpha: 1.0)
    }
}
