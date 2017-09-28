import Foundation
import WordPressShared


class NoteBlockUserTableViewCell: NoteBlockTableViewCell {
    typealias EventHandler = (() -> Void)

    // MARK: - Public Properties
    var onFollowClick: EventHandler?
    var onUnfollowClick: EventHandler?

    var isFollowEnabled: Bool {
        set {
            if newValue {
                innerStackView.addArrangedSubview(btnFollow)
            } else {
                btnFollow.removeFromSuperview()
            }
        }
        get {
            return btnFollow.superview != nil
        }
    }
    var isFollowOn: Bool {
        set {
            btnFollow.isSelected = newValue
        }
        get {
            return btnFollow.isSelected
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
    func downloadGravatarWithURL(_ url: URL?) {
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

        WPStyleGuide.Notifications.configureFollowButton(btnFollow)
        btnFollow.titleLabel?.font = WPStyleGuide.Notifications.blockRegularFont

        backgroundColor = WPStyleGuide.Notifications.blockBackgroundColor

        nameLabel.font = WPStyleGuide.Notifications.blockBoldFont
        nameLabel.textColor = WPStyleGuide.Notifications.blockTextColor

        blogLabel.font = WPStyleGuide.Notifications.blockRegularFont
        blogLabel.textColor = WPStyleGuide.allTAllShadeGrey()
        blogLabel.adjustsFontSizeToFitWidth = false
    }


    // MARK: - IBActions
    @IBAction func followWasPressed(_ sender: AnyObject) {
        ReachabilityUtils.onAvailableInternetConnectionDo {
            if let listener = isFollowOn ? onUnfollowClick : onFollowClick {
                listener()
            }
            isFollowOn = !isFollowOn
        }
    }

    // MARK: - Private
    fileprivate var gravatarURL: URL?

    // MARK: - IBOutlets
    @IBOutlet fileprivate var nameLabel: UILabel!
    @IBOutlet fileprivate var blogLabel: UILabel!
    @IBOutlet fileprivate var btnFollow: UIButton!
    @IBOutlet fileprivate var gravatarImageView: CircularImageView!
    @IBOutlet fileprivate var innerStackView: UIStackView!
}
