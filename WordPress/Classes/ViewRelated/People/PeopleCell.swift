import UIKit

class PeopleCell: UITableViewCell {
    @IBOutlet var avatarImageView: CircularImageView!
    @IBOutlet var displayNameLabel: UILabel!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var roleBadge: PeopleRoleBadgeView!

    override func awakeFromNib() {
        displayNameLabel.font = WPFontManager.merriweatherBoldFontOfSize(14)
    }

    func bindViewModel(viewModel: PeopleCellViewModel) {
        avatarImageView.image = viewModel.avatar
        displayNameLabel.text = viewModel.displayName
        usernameLabel.text = viewModel.usernameText
        roleBadge.borderColor = viewModel.roleBorderColor
        roleBadge.backgroundColor = viewModel.roleBackgroundColor
        roleBadge.textColor = viewModel.roleTextColor
        roleBadge.text = viewModel.roleText
    }
}
