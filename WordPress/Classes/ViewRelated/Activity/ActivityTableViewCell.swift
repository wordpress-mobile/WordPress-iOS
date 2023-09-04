import Foundation
import Gridicons
import WordPressShared.WPTableViewCell

open class ActivityTableViewCell: WPTableViewCell, NibReusable {

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

    func configureCell(_ formattableActivity: FormattableActivity, displaysDate: Bool = false) {
        activity = formattableActivity.activity
        guard let activity = activity else {
            return
        }

        configureFonts()

        dateLabel.isHidden = !displaysDate
        bulletLabel.isHidden = !displaysDate

        summaryLabel.text = activity.summary
        dateLabel.text = activity.published.toMediumString()
        bulletLabel.text = "\u{2022}"
        contentLabel.text = activity.text

        summaryLabel.textColor = .textSubtle
        dateLabel.textColor = .textSubtle
        bulletLabel.textColor = .textSubtle
        contentLabel.textColor = .text

        iconBackgroundImageView.backgroundColor = Style.getColorByActivityStatus(activity)
        if let iconImage = Style.getIconForActivity(activity) {
            iconImageView.image = iconImage.imageFlippedForRightToLeftLayoutDirection()
            iconImageView.isHidden = false
        } else {
            iconImageView.isHidden = true
        }

        contentView.backgroundColor = Style.backgroundColor()
        actionButtonContainer.isHidden  = !activity.isRewindable || displaysDate
        actionButton.setImage(actionGridicon, for: .normal)
        actionButton.tintColor = .listIcon
        actionButton.accessibilityIdentifier = "activity-cell-action-button"
    }

    private func configureFonts() {
        contentLabel.adjustsFontForContentSizeCategory = true
        contentLabel.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .semibold)

        [summaryLabel, bulletLabel, dateLabel].forEach {
            $0.adjustsFontForContentSizeCategory = true
            $0.font = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .regular)
        }
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
    @IBOutlet fileprivate var bulletLabel: UILabel!
    @IBOutlet fileprivate var dateLabel: UILabel!
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
        configureFonts()

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

    private func configureFonts() {
        contentLabel.adjustsFontForContentSizeCategory = true
        contentLabel.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .semibold)

        summaryLabel.adjustsFontForContentSizeCategory = true
        summaryLabel.font = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .regular)
    }
}
