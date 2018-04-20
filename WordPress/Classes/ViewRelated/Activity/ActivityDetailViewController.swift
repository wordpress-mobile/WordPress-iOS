import UIKit
import Gridicons
import WordPressUI

class ActivityDetailViewController: UIViewController {

    var activity: Activity?
    weak var rewindPresenter: ActivityRewindPresenter?

    @IBOutlet private var imageView: CircularImageView!

    @IBOutlet private var roleLabel: UILabel!
    @IBOutlet private var nameLabel: UILabel!

    @IBOutlet private var timeLabel: UILabel!
    @IBOutlet private var dateLabel: UILabel!

    @IBOutlet private var textLabel: UILabel!
    @IBOutlet private var summaryLabel: UILabel!

    @IBOutlet private var rewindStackView: UIStackView!
    @IBOutlet private var bottomConstaint: NSLayoutConstraint!

    @IBOutlet private var rewindButton: UIButton!

    override func viewDidLoad() {
        setupViews()
        setupText()
    }

    @IBAction func rewindButtonTapped(sender: UIButton) {
        rewindPresenter?.presentRewindFor(activity: activity!)
    }

    private func setupViews() {
        guard let activity = activity else {
            return
        }

        if activity.isRewindable {
            rewindStackView.isHidden = false
            bottomConstaint.constant = 0
        }

        nameLabel.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .footnote).pointSize,
                                           weight: .semibold)

        textLabel.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize,
                                           weight: .semibold)

        if view.effectiveUserInterfaceLayoutDirection == .leftToRight {
            // swiftlint:disable:next inverse_text_alignment
            dateLabel.textAlignment = .right
            // swiftlint:disable:next inverse_text_alignment
            timeLabel.textAlignment = .right
        } else {
            // swiftlint:disable:next natural_text_alignment
            dateLabel.textAlignment = .left
            // swiftlint:disable:next natural_text_alignment
            timeLabel.textAlignment = .left
        }

        if let avatar = activity.actor?.avatarURL, let avatarURL = URL(string: avatar) {
            imageView.backgroundColor = WPStyleGuide.greyLighten10()
            imageView.downloadImage(from: avatarURL, placeholderImage: Gridicon.iconOfType(.user, withSize: Constants.gridiconSize))
        } else if let iconType = WPStyleGuide.ActivityStyleGuide.getGridiconTypeForActivity(activity) {
            imageView.contentMode = .center
            imageView.backgroundColor = WPStyleGuide.ActivityStyleGuide.getColorByActivityStatus(activity)
            let image = Gridicon.iconOfType(iconType, withSize: Constants.gridiconSize)
            imageView.image = image
        } else {
            imageView.isHidden = true
        }

        rewindButton.naturalContentHorizontalAlignment = .leading
        rewindButton.setImage(Gridicon.iconOfType(.history, withSize: Constants.gridiconSize), for: .normal)
    }

    private func setupText() {
        guard let activity = activity else {
            return
        }

        title = NSLocalizedString("Event", comment: "Title for the activity detail view")
        nameLabel.text = activity.actor?.displayName
        roleLabel.text = activity.actor?.role.localizedCapitalized

        dateLabel.text = activity.publishedDateUTCWithoutTime

        textLabel.text = activity.text
        summaryLabel.text = activity.summary

        rewindButton.setTitle(NSLocalizedString("Rewind", comment: "Title for button allowing user to rewind their Jetpack site"),
                                                for: .normal)

        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
        timeFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        timeLabel.text = timeFormatter.string(from: activity.published)
    }

    private enum Constants {
        static let gridiconSize: CGSize = CGSize(width: 24, height: 24)
    }

}
