import Foundation
import Gridicons
import WordPressShared.WPTableViewCell

open class ActivityTableViewCell: WPTableViewCell {

    var actionButtonHandler: ((UIButton) -> Void)?

    // MARK: - Overwritten Methods

    open override func awakeFromNib() {
        super.awakeFromNib()
        assert(iconBackgroundImageView != nil)
        assert(contentLabel != nil)
        assert(summaryLabel != nil)
        assert(actionButton != nil)
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
        actionButtonContainer.isHidden  = !activity.isRewindable

        actionButton.setImage(actionGridicon, for: .normal)
        actionButton.tintColor = .listIcon
        actionButton.accessibilityIdentifier = "activity-cell-action-button"
    }

    @IBAction func didTapActionButton(_ sender: UIButton) {
        actionButtonHandler?(sender)
    }

    typealias Style = WPStyleGuide.ActivityStyleGuide

    // MARK: - Private Properties

    fileprivate var activity: Activity?
    fileprivate var actionGridicon: UIImage {
        return UIImage.gridicon(.ellipsis)
    }

    // MARK: - IBOutlets

    @IBOutlet fileprivate var iconBackgroundImageView: CircularImageView!
    @IBOutlet fileprivate var iconImageView: UIImageView!
    @IBOutlet fileprivate var contentLabel: UILabel!
    @IBOutlet fileprivate var summaryLabel: UILabel!
    @IBOutlet fileprivate var actionButtonContainer: UIView!
    @IBOutlet fileprivate var actionButton: UIButton!
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
        iconImageView.image = UIImage.gridicon(.noticeOutline).imageWithTintColor(.white)
        iconImageView.isHidden = false
        actionButtonContainer.isHidden = true

        progressView.progressTintColor = .primary
        progressView.trackTintColor = UIColor(light: (.primary(.shade5)), dark: (.primary(.shade80)))
        progressView.setProgress(progress, animated: true)
    }
}
