import Foundation
import WordPressShared
import WordPressUI
import AsyncImageKit
import Gravatar

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
            headerTitleLabel.text = newValue
        }
        get {
            return headerTitleLabel.text
        }
    }

    @objc var attributedHeaderTitle: NSAttributedString? {
        set {
            headerTitleLabel.attributedText = newValue
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
            headerDetailsLabel.attributedText = newValue
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

        guard let url else {
            authorAvatarImageView.image = .gravatarPlaceholderImage
            return
        }
        if let gravatar = AvatarURL(url: url) {
            authorAvatarImageView.downloadGravatar(gravatar, placeholder: .gravatarPlaceholderImage, animate: true)
        } else {
            authorAvatarImageView.wp.setImage(with: url, size: ImageSize(scaling: SiteIconViewModel.Size.regular.size, in: self))
        }
    }

    // MARK: - View Methods

    override func awakeFromNib() {
        super.awakeFromNib()

        accessoryType = .disclosureIndicator
        backgroundColor = Style.blockBackgroundColor

        // No label fonts here: the attributed header title and details carry their own fonts, which
        // depend on the window the cell is displayed in.
        headerTitleLabel.textColor = Style.headerTitleColor
        headerDetailsLabel.textColor = Style.headerDetailsColor
        authorAvatarImageView.image = .gravatarPlaceholderImage
    }

    // MARK: - Overridden Methods

    override func prepareForReuse() {
        super.prepareForReuse()
        authorAvatarURL = nil
        authorAvatarImageView.cancelImageDownload()
        authorAvatarImageView.image = nil
    }

    override func refreshSeparators() {
        separatorsView.bottomVisible = true
        separatorsView.bottomInsets = fullSeparatorInsets
    }
}
