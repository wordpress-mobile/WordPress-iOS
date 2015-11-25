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
}
