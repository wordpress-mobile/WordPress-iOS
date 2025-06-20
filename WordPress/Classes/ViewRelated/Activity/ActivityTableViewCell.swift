import UIKit
import Gridicons
import WordPressShared
import WordPressUI

open class ActivityTableViewCell: UITableViewCell, NibReusable {

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
        guard let activity else {
            return
        }

        configureFonts()

        dateLabel.isHidden = !displaysDate
        bulletLabel.isHidden = !displaysDate

        summaryLabel.text = activity.summary
        dateLabel.text = activity.published.toMediumString()
        bulletLabel.text = "\u{2022}"
        contentLabel.text = activity.text.isEmpty ? "–" : activity.text

        summaryLabel.textColor = .secondaryLabel
        dateLabel.textColor = .secondaryLabel
        bulletLabel.textColor = .secondaryLabel
        contentLabel.textColor = .label

        iconBackgroundImageView.backgroundColor = activity.statusColor
        if let iconImage = activity.icon {
            iconImageView.image = iconImage.imageFlippedForRightToLeftLayoutDirection()
            iconImageView.isHidden = false
        } else {
            iconImageView.isHidden = true
        }

        contentView.backgroundColor = Style.backgroundColor()
        actionButtonContainer.isHidden = !activity.isRewindable || displaysDate
        actionButton.setImage(actionGridicon, for: .normal)
        actionButton.tintColor = .secondaryLabel
        actionButton.accessibilityIdentifier = "activity-cell-action-button"

        separatorInset = UIEdgeInsets(top: 0, left: 60, bottom: 0, right: 0)
    }

    private func configureFonts() {
        contentLabel.adjustsFontForContentSizeCategory = true
        contentLabel.font = WPStyleGuide.fontForTextStyle(.callout, fontWeight: .medium)

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
