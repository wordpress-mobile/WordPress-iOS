class UserProfileUserInfoCell: UITableViewCell, NibReusable {

    // MARK: - Properties

    @IBOutlet weak var gravatarImageView: CircularImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var userBioLabel: UILabel!

    static let estimatedRowHeight: CGFloat = 200

    // MARK: - View

    override func awakeFromNib() {
        super.awakeFromNib()
        configureCell()
    }

    // MARK: - Public Methods

    func configure(withUser user: RemoteUser) {
        nameLabel.text = user.displayName
        usernameLabel.text = String(format: Constants.usernameFormat, user.username)

        // TODO:
        // - replace with actual bio.
        // - hide label if no bio.
        userBioLabel.text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Consectetur purus ut faucibus pulvinar. Tincidunt eget nullam non nisi est sit amet facilisis magna. Morbi tincidunt augue interdum velit euismod in pellentesque. Sed adipiscing diam donec adipiscing."

        downloadGravatarWithURL(user.avatarURL)
    }

}

// MARK: - Private Extension

private extension UserProfileUserInfoCell {

    func configureCell() {
        nameLabel.textColor = .text
        nameLabel.font = WPStyleGuide.serifFontForTextStyle(.title3, fontWeight: .semibold)
        usernameLabel.textColor = .textSubtle
        userBioLabel.textColor = .text
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
