import Foundation
import WordPressShared.WPStyleGuide


// MARK: - NoteBlockHeaderTableViewCell
//
class NoteBlockHeaderTableViewCell: NoteBlockTableViewCell {

    // MARK: - Private
    private var authorAvatarURL: URL?
    private typealias Style = WPStyleGuide.Notifications

    // MARK: - IBOutlets
    @IBOutlet private var authorAvatarImageView: UIImageView!
    @IBOutlet private var headerTitleLabel: UILabel!
    @IBOutlet private var headerDetailsLabel: UILabel!

    // MARK: - Public Properties
    @objc var headerTitle: String? {
        set {
            headerTitleLabel.text  = newValue
        }
        get {
            return headerTitleLabel.text
        }
    }

    @objc var attributedHeaderTitle: NSAttributedString? {
        set {
            headerTitleLabel.attributedText  = newValue
        }
        get {
            return headerTitleLabel.attributedText
        }
    }

    @objc var headerDetails: String? {
        set {
            headerDetailsLabel.text = newValue
        }
        get {
            return headerDetailsLabel.text
        }
    }

    @objc var attributedHeaderDetails: NSAttributedString? {
        set {
            headerDetailsLabel.attributedText  = newValue
        }
        get {
            return headerDetailsLabel.attributedText
        }
    }


    // MARK: - Public Methods

    @objc(downloadAuthorAvatarWithURL:)
    func downloadAuthorAvatar(with url: URL?) {
        guard url != authorAvatarURL else {
            return
        }

        authorAvatarURL = url

        guard let url = url else {
            authorAvatarImageView.image = .gravatarPlaceholderImage
            return
        }

        if let gravatar = Gravatar(url) {
            authorAvatarImageView.downloadGravatar(gravatar, placeholder: .gravatarPlaceholderImage, animate: true)
        } else {
            authorAvatarImageView.downloadSiteIcon(at: url.absoluteString)
        }
    }

    // MARK: - View Methods

    override func awakeFromNib() {
        super.awakeFromNib()

        accessoryType = .disclosureIndicator
        backgroundColor = Style.blockBackgroundColor

        headerTitleLabel.font = Style.headerTitleBoldFont
        headerTitleLabel.textColor = Style.headerTitleColor
        headerDetailsLabel.font = Style.headerDetailsRegularFont
        headerDetailsLabel.textColor = Style.headerDetailsColor
        authorAvatarImageView.image = .gravatarPlaceholderImage
    }

    // MARK: - Overriden Methods
    override func refreshSeparators() {
        separatorsView.bottomVisible = true
        separatorsView.bottomInsets = UIEdgeInsets.zero
    }
}
