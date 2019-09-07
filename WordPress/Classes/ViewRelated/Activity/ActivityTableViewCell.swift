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

    func configureCell(_ formattableActivity: FormattableActivity) {
        activity = formattableActivity.activity
        guard let activity = activity else {
            return
        }

        summaryLabel.text = activity.summary
        contentLabel.text = activity.text

        summaryLabel.textColor = .textSubtle
        contentLabel.textColor = .text

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

open class RewindStatusTableViewCell: ActivityTableViewCell {

    @IBOutlet private var progressView: UIProgressView!

    private(set) var title = ""
    private(set) var summary = ""
    private(set) var progress: Float = 0.0

    open func configureCell(title: String,
                            summary: String,
                            progress: Float) {
        self.title = title
        self.summary = summary
        self.progress = progress

        contentLabel.text = title
        summaryLabel.text = summary

        iconBackgroundImageView.backgroundColor = .primary
        iconImageView.image = Gridicon.iconOfType(.noticeOutline).imageWithTintColor(.white)
        iconImageView.isHidden = false
        rewindIconContainer.isHidden = true

        progressView.setProgress(progress, animated: true)
    }
}
