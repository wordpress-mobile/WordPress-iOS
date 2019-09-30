import UIKit
import Gridicons
import WordPressUI

class ActivityDetailViewController: UIViewController {

    var formattableActivity: FormattableActivity? {
        didSet {
            setupActivity()
            setupRouter()
        }
    }
    var site: JetpackSiteRef?

    weak var rewindPresenter: ActivityRewindPresenter?

    @IBOutlet private var imageView: CircularImageView!

    @IBOutlet private var roleLabel: UILabel!
    @IBOutlet private var nameLabel: UILabel!

    @IBOutlet private var timeLabel: UILabel!
    @IBOutlet private var dateLabel: UILabel!

    @IBOutlet weak var textView: UITextView! {
        didSet {
            textView.delegate = self
        }
    }

    //TODO: remove!
    @IBOutlet private var textLabel: UILabel!
    @IBOutlet private var summaryLabel: UILabel!

    @IBOutlet private var headerStackView: UIStackView!
    @IBOutlet private var rewindStackView: UIStackView!
    @IBOutlet private var contentStackView: UIStackView!
    @IBOutlet private var containerView: UIView!

    @IBOutlet private var bottomConstaint: NSLayoutConstraint!

    @IBOutlet private var rewindButton: UIButton!

    private var activity: Activity?

    var router: ActivityContentRouter?

    override func viewDidLoad() {
        setupLabelStyles()
        setupViews()
        setupText()
        setupAccesibility()
        WPAnalytics.track(.activityLogDetailViewed)
    }

    @IBAction func rewindButtonTapped(sender: UIButton) {
        rewindPresenter?.presentRewindFor(activity: activity!)
    }

    private func setupLabelStyles() {
        nameLabel.textColor = .text
        nameLabel.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .footnote).pointSize,
                                           weight: .semibold)
        textLabel.textColor = .text
        summaryLabel.textColor = .textSubtle

        roleLabel.textColor = .textSubtle
        dateLabel.textColor = .textSubtle
        timeLabel.textColor = .textSubtle

        rewindButton.setTitleColor(.primary, for: .normal)
        rewindButton.setTitleColor(.primaryDark, for: .highlighted)
    }

    private func setupViews() {
        guard let activity = activity else {
            return
        }

        view.backgroundColor = .listBackground
        containerView.backgroundColor = .listForeground

        textLabel.isHidden = true
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0

        if activity.isRewindable {
            rewindStackView.isHidden = false
            bottomConstaint.constant = 0
        }

        if let avatar = activity.actor?.avatarURL, let avatarURL = URL(string: avatar) {
            imageView.backgroundColor = .neutral(.shade20)
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
        guard let activity = activity, let site = site else {
            return
        }

        title = NSLocalizedString("Event", comment: "Title for the activity detail view")
        nameLabel.text = activity.actor?.displayName
        roleLabel.text = activity.actor?.role.localizedCapitalized

        textView.attributedText = formattableActivity?.formattedContent(using: ActivityContentStyles())
        summaryLabel.text = activity.summary

        rewindButton.setTitle(NSLocalizedString("Rewind", comment: "Title for button allowing user to rewind their Jetpack site"),
                                                for: .normal)

        let dateFormatter = ActivityDateFormatting.longDateFormatterWithoutTime(for: site)
        dateLabel.text = dateFormatter.string(from: activity.published)

        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
        timeFormatter.timeZone = dateFormatter.timeZone

        timeLabel.text = timeFormatter.string(from: activity.published)
    }

    private func setupAccesibility() {
        guard let activity = activity else {
            return
        }

        contentStackView.isAccessibilityElement = true
        contentStackView.accessibilityTraits = UIAccessibilityTraits.staticText
        contentStackView.accessibilityLabel = "\(activity.text), \(activity.summary)"
        textLabel.isAccessibilityElement = false
        summaryLabel.isAccessibilityElement = false

        if traitCollection.preferredContentSizeCategory.isAccessibilityCategory {
            headerStackView.axis = .vertical

            dateLabel.textAlignment = .center
            timeLabel.textAlignment = .center
        } else {
            headerStackView.axis = .horizontal

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
        }
    }

    func setupRouter() {
        guard let activity = formattableActivity else {
            router = nil
            return
        }
        let coordinator = DefaultContentCoordinator(controller: self, context: ContextManager.sharedInstance().mainContext)
        router = ActivityContentRouter(
            activity: activity,
            coordinator: coordinator)
    }

    func setupActivity() {
        activity = formattableActivity?.activity
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            setupLabelStyles()
            setupAccesibility()
        }
    }

    private enum Constants {
        static let gridiconSize: CGSize = CGSize(width: 24, height: 24)
    }
}

// MARK: - UITextViewDelegate

extension ActivityDetailViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        router?.routeTo(URL)
        return false
    }
}
