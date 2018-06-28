import Foundation
import Gridicons
import WordPressShared.WPTableViewCell

open class ActivityTableViewCell: WPTableViewCell {

    // MARK: - Overwritten Methods

    open override func awakeFromNib() {
        super.awakeFromNib()
        assert(iconBackgroundImageView != nil)
        assert(contentLabel != nil)
        assert(summaryLabel != nil)
        assert(rewindIcon != nil)
        rewindIcon.image = rewindGridicon
    }

    // MARK: - Public Methods

    open func configureCell(_ activity: Activity) {
        self.activity = activity
        summaryLabel.text = activity.summary
        if FeatureFlag.extractNotifications.enabled {
            contentLabel.attributedText = activity.formattedContent(ofKind: .text, using: SubjectContentStyles())
        } else {
            contentLabel.text = activity.text
        }

        iconBackgroundImageView.backgroundColor = Style.getColorByActivityStatus(activity)
        if let iconImage = Style.getIconForActivity(activity) {
            iconImageView.image = iconImage.imageFlippedForRightToLeftLayoutDirection()
            iconImageView.isHidden = false
        } else {
            iconImageView.isHidden = true
        }

        contentView.backgroundColor = Style.backgroundColor()
        rewindIconContainer.isHidden  = !activity.isRewindable

    }

    typealias Style = WPStyleGuide.ActivityStyleGuide

    // MARK: - Private Properties

    fileprivate var activity: Activity?
    fileprivate var rewindGridicon = Gridicon.iconOfType(.history)

    // MARK: - IBOutlets

    @IBOutlet fileprivate var iconBackgroundImageView: CircularImageView!
    @IBOutlet fileprivate var iconImageView: UIImageView!
    @IBOutlet fileprivate var contentLabel: UILabel!
    @IBOutlet fileprivate var summaryLabel: UILabel!
    @IBOutlet fileprivate var rewindIconContainer: UIView!
    @IBOutlet fileprivate var rewindIcon: UIImageView!
}
