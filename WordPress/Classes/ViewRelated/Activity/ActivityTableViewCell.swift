import Foundation
import WordPressShared.WPTableViewCell

open class ActivityTableViewCell: WPTableViewCell {

    // MARK: - Overwritten Methods

    open override func awakeFromNib() {
        super.awakeFromNib()
        assert(gravatarImageView != nil)
        assert(summaryLabel != nil)
        assert(timestampLabel != nil)
    }

    // MARK: - Public Methods

    open func configureCell(_ activity: Activity) {
        self.activity = activity
        timestampLabel?.attributedText = NSAttributedString(string: activity.published.mediumStringWithTime(),
                                                            attributes: Style.timestampStyle())
        if activity.name == ActivityName.fullBackup {
            gravatarImageView.isHidden = true
            summaryLabel.attributedText = NSAttributedString(string: activity.summary,
                                                             attributes: Style.summaryBoldStyle())

        } else {
            gravatarImageView.isHidden = false
            if let actor = activity.actor,
                let url = URL(string: actor.avatarURL) {
                downloadGravatarWithURL(url)
            } else {
                gravatarImageView.image = placeholderImage
            }
            summaryLabel.attributedText = NSAttributedString(string: activity.summary,
                                                             attributes: Style.summaryRegularStyle())
        }
        if activity.rewindable {
            borderView.backgroundColor = Style.backgroundRewindableColor()
        } else {
            borderView.backgroundColor = Style.backgroundColor()
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

    typealias Style = WPStyleGuide.Activity

    // MARK: - Private Properties

    fileprivate var activity: Activity?
    fileprivate var gravatarURL: URL?

    fileprivate var placeholderImage: UIImage {
        return Style.gravatarPlaceholderImage()
    }

    // MARK: - IBOutlets

    @IBOutlet fileprivate var gravatarImageView: CircularImageView!
    @IBOutlet fileprivate var summaryLabel: UILabel!
    @IBOutlet fileprivate var timestampLabel: UILabel!
    @IBOutlet fileprivate var borderView: UIView!
}
