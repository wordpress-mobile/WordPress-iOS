import Foundation
import WordPressShared.WPTableViewCell

open class ActivityTableViewCell: WPTableViewCell {

    // MARK: - Overwritten Methods

    open override func awakeFromNib() {
        super.awakeFromNib()
        assert(gravatarImageView != nil)
        assert(summaryLabel != nil)
        assert(statusImageView != nil)
        assert(timestampLabel != nil)
        assert(borderView != nil)
    }

    // MARK: - Public Methods

    open func configureCell(_ activity: Activity) {
        self.activity = activity
        timestampLabel?.attributedText = NSAttributedString(string: activity.published.mediumStringWithUTCTime(),
                                                            attributes: Style.timestampStyle())
        if activity.isFullBackup {
            gravatarImageView.isHidden = true
            summaryLabel.attributedText = NSAttributedString(string: activity.summary,
                                                             attributes: Style.summaryBoldStyle())
        } else {
            gravatarImageView.isHidden = false
            if let actor = activity.actor,
                let url = URL(string: actor.avatarURL) {
                downloadGravatarWithURL(url)
            } else if let actor = activity.actor,
                       actor.isJetpack {
                gravatarImageView.image = jetpackGravatar
            } else {
                gravatarImageView.image = placeholderImage
            }
            summaryLabel.attributedText = NSAttributedString(string: activity.summary,
                                                             attributes: Style.summaryRegularStyle())
        }

        if let statusImage = Style.getIconForActivity(activity) {
            statusImageView.image = statusImage
            statusImageView.isHidden = false
        } else {
            statusImageView.isHidden = true
        }
        if activity.isDiscarded {
            contentView.backgroundColor = Style.backgroundDiscardedColor()
            borderView.backgroundColor = Style.backgroundDiscardedColor()
        } else {
            contentView.backgroundColor = Style.backgroundColor()
            if activity.rewindable {
                borderView.backgroundColor = Style.backgroundRewindableColor()
            } else {
                borderView.backgroundColor = Style.backgroundColor()
            }
        }
    }

    // MARK: - Private Methods

    fileprivate func downloadGravatarWithURL(_ url: URL?) {
        if url == gravatarURL {
            return
        }

        let gravatar = url.flatMap { Gravatar($0) }
        gravatarImageView.downloadGravatar(gravatar, placeholder: placeholderImage, animate: true)

        gravatarURL = url
    }

    typealias Style = WPStyleGuide.ActivityStyleGuide

    // MARK: - Private Properties

    fileprivate var activity: Activity?
    fileprivate var gravatarURL: URL?

    fileprivate var placeholderImage: UIImage {
        return Style.gravatarPlaceholderImage()
    }
    fileprivate var jetpackGravatar = UIImage(named: "icon-jetpack-gray")

    // MARK: - IBOutlets

    @IBOutlet fileprivate var gravatarImageView: CircularImageView!
    @IBOutlet fileprivate var summaryLabel: UILabel!
    @IBOutlet fileprivate var statusImageView: UIImageView!
    @IBOutlet fileprivate var timestampLabel: UILabel!
    @IBOutlet fileprivate var borderView: UIView!
}
