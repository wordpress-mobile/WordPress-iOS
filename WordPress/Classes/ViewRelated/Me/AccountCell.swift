import Foundation
import WordPressShared

class AccountCell: WPTableViewCell {
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        profileImageView.layer.borderWidth = 2
        profileImageView.layer.borderColor = UIColor.lightGrayColor().CGColor
    }
}
