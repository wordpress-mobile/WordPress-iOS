import UIKit
import WordPressShared

class BlogDashboardPostCardGhostCell: UITableViewCell, NibReusable {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        WPStyleGuide.configureTableViewCell(self)

        backgroundColor = .clear
    }
}
