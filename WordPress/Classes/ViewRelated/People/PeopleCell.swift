import UIKit
import WordPressShared

class PeopleCell: WPTableViewCell {
    @IBOutlet var avatarImageView: CircularImageView!
    @IBOutlet var displayNameLabel: UILabel!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var roleBadge: PeopleRoleBadgeLabel!
    @IBOutlet var superAdminRoleBadge: PeopleRoleBadgeLabel!

    override func awakeFromNib() {
        forceCustomCellMargins = true
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
        superAdminRoleBadge.text = viewModel.superAdminText
        superAdminRoleBadge.hidden = viewModel.superAdminHidden
        superAdminRoleBadge.borderColor = viewModel.superAdminBorderColor
        superAdminRoleBadge.backgroundColor = viewModel.superAdminBackgroundColor
    }

    func setAvatarURL(avatarURL: NSURL?) {
        let gravatar = avatarURL.flatMap { Gravatar($0) }
        let placeholder = UIImage(named: "gravatar")!
        avatarImageView.downloadGravatar(gravatar, placeholder: placeholder, animate: false)
    }

    /*
    It seems UIKit clears the background of all the cells' subviews when
    highlighted/selected, so he have to set our wanted color again.

    Otherwise we get this: https://cldup.com/NT3pbaeIc1.png
    */
    override func setHighlighted(highlighted: Bool, animated: Bool) {
        let roleBackgroundColor = roleBadge.backgroundColor
        let superAdminBackgroundColor = superAdminRoleBadge.backgroundColor

        super.setHighlighted(highlighted, animated: animated)

        if highlighted {
            roleBadge.backgroundColor = roleBackgroundColor
            superAdminRoleBadge.backgroundColor = superAdminBackgroundColor
        }
    }

    override func setSelected(selected: Bool, animated: Bool) {
        let roleBackgroundColor = roleBadge.backgroundColor
        let superAdminBackgroundColor = superAdminRoleBadge.backgroundColor

        super.setSelected(selected, animated: animated)

        if selected {
            roleBadge.backgroundColor = roleBackgroundColor
            superAdminRoleBadge.backgroundColor = superAdminBackgroundColor
        }
    }
}
