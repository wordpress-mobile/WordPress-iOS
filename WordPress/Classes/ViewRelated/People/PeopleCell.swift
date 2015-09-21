import UIKit

class PeopleCell: UITableViewCell {
    @IBOutlet var avatarImageView: CircularImageView!
    @IBOutlet var displayNameLabel: UILabel!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var roleBadge: PeopleRoleBadgeView!

    override func awakeFromNib() {
        displayNameLabel.font = WPFontManager.merriweatherBoldFontOfSize(14)
    }
}
