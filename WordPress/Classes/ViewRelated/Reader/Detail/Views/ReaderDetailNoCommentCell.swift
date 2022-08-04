import UIKit

class ReaderDetailNoCommentCell: UITableViewCell, NibReusable {

    @IBOutlet weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .basicBackground
        titleLabel.textColor = .textSubtle
    }

}
