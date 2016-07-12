import Foundation
import WordPressShared

extension WPStyleGuide
{
    public class func configureTableViewBlogCell(cell: UITableViewCell) {
        configureTableViewCell(cell)
        cell.detailTextLabel?.font = self.subtitleFont()
        cell.detailTextLabel?.textColor = self.greyDarken10()
        cell.backgroundColor = self.lightGrey()
    }


    public class func cellGridiconAccessoryColor() -> UIColor {
        return UIColor(red: 200.0 / 255.0, green: 200.0 / 255.0, blue: 205.0 / 255.0, alpha: 1.0)
    }
}
