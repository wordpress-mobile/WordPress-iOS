import Foundation
import WordPressShared.WPStyleGuide

class NoteBlockHeaderTableViewCell: NoteBlockTableViewCell {
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


    // MARK: - Public Methods
    @objc func downloadGravatarWithURL(_ url: URL?) {
        if url == gravatarURL {
            return
        }

        let placeholderImage = Style.gravatarPlaceholderImage
        let gravatar = url.flatMap { Gravatar($0) }
        gravatarImageView.downloadGravatar(gravatar, placeholder: placeholderImage, animate: true)

        gravatarURL = url
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
        gravatarImageView.image = Style.gravatarPlaceholderImage
    }

    // MARK: - Overriden Methods
    override func refreshSeparators() {
        separatorsView.bottomVisible = true
        separatorsView.bottomInsets = UIEdgeInsets.zero
    }


    // MARK: - Private Alias
    fileprivate typealias Style = WPStyleGuide.Notifications

    // MARK: - Private
    fileprivate var gravatarURL: URL?

    // MARK: - IBOutlets
    @IBOutlet fileprivate weak var gravatarImageView: UIImageView!
    @IBOutlet fileprivate weak var headerTitleLabel: UILabel!
    @IBOutlet fileprivate weak var headerDetailsLabel: UILabel!
}
