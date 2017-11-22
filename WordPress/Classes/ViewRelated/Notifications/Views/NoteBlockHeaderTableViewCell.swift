import Foundation
import WordPressShared.WPStyleGuide

class NoteBlockHeaderTableViewCell: NoteBlockTableViewCell {
    // MARK: - Public Properties
    var headerTitle: String? {
        set {
            headerTitleLabel.text  = newValue
        }
        get {
            return headerTitleLabel.text
        }
    }

    var attributedHeaderTitle: NSAttributedString? {
        set {
            headerTitleLabel.attributedText  = newValue
        }
        get {
            return headerTitleLabel.attributedText
        }
    }

    var headerDetails: String? {
        set {
            headerDetailsLabel.text = newValue
        }
        get {
            return headerDetailsLabel.text
        }
    }


    // MARK: - Public Methods
    @objc func downloadGravatar(with url: URL?) {
        guard url != gravatarURL else {
            return
        }

        if let url = url, let gravatar = Gravatar(url) {
            gravatarImageView.downloadGravatar(gravatar, placeholder: Style.gravatarPlaceholderImage, animate: true)
        } else {
            gravatarImageView.downloadImage(url, placeholderImage: Style.gravatarPlaceholderImage)
        }

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
