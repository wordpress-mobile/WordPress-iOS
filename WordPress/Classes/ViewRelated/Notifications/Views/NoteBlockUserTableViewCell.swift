import Foundation
import WordPressShared


class NoteBlockUserTableViewCell: NoteBlockTableViewCell
{
    typealias EventHandler = (() -> Void)

    // MARK: - Public Properties
    var onFollowClick    : EventHandler?
    var onUnfollowClick  : EventHandler?

    var isFollowEnabled: Bool {
        set {
            btnFollow.hidden = !newValue
        }
        get {
            return !btnFollow.hidden
        }
    }
    var isFollowOn: Bool {
        set {
            btnFollow.selected = newValue
        }
        get {
            return btnFollow.selected
        }
    }

    var name: String? {
        set {
            nameLabel.text  = newValue
        }
        get {
            return nameLabel.text
        }
    }
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

    // MARK: - View Methods
    override func awakeFromNib() {
        super.awakeFromNib()

        WPStyleGuide.configureFollowButton(btnFollow)
        btnFollow.titleLabel?.font = WPStyleGuide.Notifications.blockRegularFont

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

    // MARK: - IBActions
    @IBAction func followWasPressed(sender: AnyObject) {
        if let listener = isFollowOn ? onUnfollowClick : onFollowClick {
            listener()
        }
        isFollowOn = !isFollowOn
    }

    // MARK: - Private
    private let gravatarImageSizePad = CGSize(width: 54.0, height: 54.0)
    private var gravatarURL: NSURL?

    // MARK: - IBOutlets
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var blogLabel: UILabel!
    @IBOutlet private weak var btnFollow: UIButton!
    @IBOutlet private weak var gravatarImageView: CircularImageView!
}
