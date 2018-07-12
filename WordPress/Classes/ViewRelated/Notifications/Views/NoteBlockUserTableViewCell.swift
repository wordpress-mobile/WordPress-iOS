import Foundation
import WordPressShared


class NoteBlockUserTableViewCell: NoteBlockTableViewCell {
    typealias EventHandler = (() -> Void)

    // MARK: - Public Properties
    @objc var onFollowClick: EventHandler?
    @objc var onUnfollowClick: EventHandler?

    @objc var isFollowEnabled: Bool {
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
    @objc var isFollowOn: Bool {
        set {
            btnFollow.isSelected = newValue
        }
        get {
            return btnFollow.isSelected
        }
    }

    @objc var name: String? {
        set {
            nameLabel.text  = newValue
        }
        get {
            return nameLabel.text
        }
    }
    @objc var blogTitle: String? {
        set {
            blogLabel.text  = newValue
        }
        get {
            return blogLabel.text
        }
    }

    // MARK: - Public Methods
    @objc func downloadGravatarWithURL(_ url: URL?) {
        if url == gravatarURL {
            return
        }

        let gravatar = url.flatMap { Gravatar($0) }
        gravatarImageView.downloadGravatar(gravatar, placeholder: .gravatarPlaceholderImage, animate: true)

        gravatarURL = url
    }

    // MARK: - View Methods
    override func awakeFromNib() {
        super.awakeFromNib()

        WPStyleGuide.Notifications.configureFollowButton(btnFollow)
        btnFollow.titleLabel?.font = WPStyleGuide.Notifications.blockRegularFont
        btnFollow.accessibilityLabel = Follow.title
        btnFollow.accessibilityHint = Follow.hint

        backgroundColor = WPStyleGuide.Notifications.blockBackgroundColor

        nameLabel.font = WPStyleGuide.Notifications.blockBoldFont
        nameLabel.textColor = WPStyleGuide.Notifications.blockTextColor

        blogLabel.font = WPStyleGuide.Notifications.blockRegularFont
        blogLabel.textColor = WPStyleGuide.greyDarken20()
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
