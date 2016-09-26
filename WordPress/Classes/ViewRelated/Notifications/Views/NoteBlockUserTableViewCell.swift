import Foundation
import WordPressShared


// MARK: - NoteBlockUserTableViewCell
//
class NoteBlockUserTableViewCell: NoteBlockTableViewCell
{
    // MARK: - Properties

    /// Name Label
    ///
    @IBOutlet private weak var nameLabel: UILabel!

    /// Blog Label
    ///
    @IBOutlet private weak var blogLabel: UILabel!


    /// Gravatar Image
    ///
    @IBOutlet private weak var gravatarImageView: CircularImageView!

    /// User's Name
    ///
    var name: String? {
        set {
            nameLabel.text  = newValue
        }
        get {
            return nameLabel.text
        }
    }

    /// User's Blog Title
    ///
    var blogTitle: String? {
        set {
            blogLabel.text  = newValue
        }
        get {
            return blogLabel.text
        }
    }


    // MARK: - Public Methods

    func downloadGravatarWithURL(url: NSURL?) {
        if url == gravatarURL {
            return
        }

        let placeholderImage = WPStyleGuide.Notifications.gravatarPlaceholderImage
        let gravatar = url.flatMap { Gravatar($0) }
        gravatarImageView.downloadGravatar(gravatar, placeholder: placeholderImage, animate: true)

        gravatarURL = url
    }


    // MARK: - Overriden Methods

    override func awakeFromNib() {
        super.awakeFromNib()

        backgroundColor = WPStyleGuide.Notifications.blockBackgroundColor
        accessoryType = .None
        contentView.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]

        nameLabel.font = WPStyleGuide.Notifications.blockBoldFont
        nameLabel.textColor = WPStyleGuide.Notifications.blockTextColor

        blogLabel.font = WPStyleGuide.Notifications.blockRegularFont
        blogLabel.textColor = WPStyleGuide.Notifications.blockSubtitleColor
        blogLabel.adjustsFontSizeToFitWidth = false

        // iPad: Use a bigger image size!
        if UIDevice.isPad() {
            gravatarImageView.updateConstraint(.Height, constant: gravatarImageSizePad.width)
            gravatarImageView.updateConstraint(.Width, constant: gravatarImageSizePad.height)
        }
    }


    // MARK: - Private
    private let gravatarImageSizePad = CGSize(width: 54.0, height: 54.0)
    private var gravatarURL: NSURL?
}
