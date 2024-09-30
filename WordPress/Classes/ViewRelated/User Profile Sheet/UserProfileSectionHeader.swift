import UIKit

class UserProfileSectionHeader: UITableViewHeaderFooterView, NibReusable {

    @IBOutlet weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.textColor = .secondaryLabel
        contentView.backgroundColor = .systemBackground
    }

}
