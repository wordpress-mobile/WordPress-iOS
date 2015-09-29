import UIKit

class PeopleCell: UITableViewCell {
    @IBOutlet var avatarImageView: CircularImageView!
    @IBOutlet var displayNameLabel: UILabel!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var superAdminRoleBadge: PeopleRoleBadgeView!
    @IBOutlet var roleBadge: PeopleRoleBadgeView!

    override func awakeFromNib() {
        displayNameLabel.font = WPFontManager.merriweatherBoldFontOfSize(14)
    }

    func bindViewModel(viewModel: PeopleCellViewModel) {
        setAvatarURL(viewModel.avatarURL)
        displayNameLabel.text = viewModel.displayName
        usernameLabel.text = viewModel.usernameText
        roleBadge.borderColor = viewModel.roleBorderColor
        roleBadge.backgroundColor = viewModel.roleBackgroundColor
        roleBadge.textColor = viewModel.roleTextColor
        roleBadge.text = viewModel.roleText
        superAdminRoleBadge.hidden = viewModel.superAdminHidden
    }

    func setAvatarURL(avatarURL: NSURL?) {
        let placeholder = UIImage(named: "gravatar")!
        if let avatarURL = avatarURL {
            let size = avatarImageView.frame.width * avatarImageView.contentScaleFactor
            let scaledURL = avatarURL.patchGravatarUrlWithSize(size)

            avatarImageView.setImageWithURL(scaledURL, placeholderImage: placeholder)
        } else {
            avatarImageView.image = placeholder
        }
    }
}
