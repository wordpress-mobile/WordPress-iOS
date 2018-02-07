import Foundation
import Gridicons
import WordPressUIKit.WPTableViewCell

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
        contentLabel.text = activity.text

        iconBackgroundImageView.backgroundColor = Style.getColorByActivityStatus(activity)
        if let iconImage = Style.getIconForActivity(activity) {
            iconImageView.image = iconImage
            iconImageView.isHidden = false
        } else {
            iconImageView.isHidden = true
        }
        if activity.isDiscarded {
            contentView.backgroundColor = Style.backgroundDiscardedColor()
            rewindIcon.isHidden = true
        } else {
            contentView.backgroundColor = Style.backgroundColor()
            rewindIcon.isHidden = !activity.rewindable
        }
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
    @IBOutlet fileprivate var rewindIcon: UIImageView!
}
