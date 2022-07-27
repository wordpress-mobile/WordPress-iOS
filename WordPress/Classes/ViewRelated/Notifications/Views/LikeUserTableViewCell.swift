import Foundation

class LikeUserTableViewCell: UITableViewCell, NibReusable {

    // MARK: - Properties

    @IBOutlet weak var gravatarImageView: CircularImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var separatorHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var separatorLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var cellStackViewLeadingConstraint: NSLayoutConstraint!

    static let estimatedRowHeight: CGFloat = 80
    private typealias Style = WPStyleGuide.Notifications

    // MARK: - View

    override func awakeFromNib() {
        super.awakeFromNib()
        configureCell()
    }

    // MARK: - Public Methods

    func configure(withUser user: LikeUser, isLastRow: Bool = false) {
        nameLabel.text = user.displayName
        usernameLabel.text = String(format: Constants.usernameFormat, user.username)
        downloadGravatarWithURL(user.avatarUrl)
        separatorLeadingConstraint.constant = isLastRow ? 0 : cellStackViewLeadingConstraint.constant
    }

}

// MARK: - Private Extension

private extension LikeUserTableViewCell {

    func configureCell() {
        nameLabel.textColor = Style.blockTextColor
        usernameLabel.textColor = .textSubtle
        backgroundColor = Style.blockBackgroundColor
        separatorView.backgroundColor = Style.blockSeparatorColor
        separatorHeightConstraint.constant = .hairlineBorderWidth
    }

    func downloadGravatarWithURL(_ url: String?) {
        // Always reset gravatar
        gravatarImageView.cancelImageDownload()
        gravatarImageView.image = .gravatarPlaceholderImage

        guard let url = url,
              let gravatarURL = URL(string: url) else {
            return
        }

        gravatarImageView.downloadImage(from: gravatarURL, placeholderImage: .gravatarPlaceholderImage)
    }

    struct Constants {
        static let usernameFormat = NSLocalizedString("@%1$@", comment: "Label displaying the user's username preceeded by an '@' symbol. %1$@ is a placeholder for the username.")
    }

}
