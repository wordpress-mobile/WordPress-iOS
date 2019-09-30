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
            configureAccesibility()
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

        backgroundColor = WPStyleGuide.Notifications.blockBackgroundColor

        nameLabel.font = WPStyleGuide.Notifications.blockBoldFont
        nameLabel.textColor = WPStyleGuide.Notifications.blockTextColor

        blogLabel.font = WPStyleGuide.Notifications.blockRegularFont
        blogLabel.textColor = .neutral(.shade50)
        blogLabel.adjustsFontSizeToFitWidth = false

        configureAccesibility()
    }


    // MARK: - IBActions
    @IBAction func followWasPressed(_ sender: AnyObject) {
        ReachabilityUtils.onAvailableInternetConnectionDo {
            configureAccesibility()

            if let listener = isFollowOn ? onUnfollowClick : onFollowClick {
                listener()
            }
            isFollowOn = !isFollowOn
        }
    }

    // MARK: - Private
    private func configureAccesibility() {
        isFollowOn ? configureAsSelected() : configureAsUnSelected()
    }

    private func configureAsUnSelected() {
        btnFollow.accessibilityLabel = Follow.title
        btnFollow.accessibilityHint = Follow.hint
    }

    private func configureAsSelected() {
        btnFollow.accessibilityLabel = Follow.selectedTitle
        btnFollow.accessibilityHint = Follow.selectedHint
    }

    fileprivate var gravatarURL: URL?

    // MARK: - IBOutlets
    @IBOutlet fileprivate var nameLabel: UILabel!
    @IBOutlet fileprivate var blogLabel: UILabel!
    @IBOutlet fileprivate var btnFollow: UIButton!
    @IBOutlet fileprivate var gravatarImageView: CircularImageView!
    @IBOutlet fileprivate var innerStackView: UIStackView!
}
