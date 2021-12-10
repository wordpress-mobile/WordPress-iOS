import UIKit
import Gridicons
import WordPressUI

class ActivityDetailViewController: UIViewController, StoryboardLoadable {

    // MARK: - StoryboardLoadable Protocol

    static var defaultStoryboardName = defaultControllerID

    // MARK: - Properties

    var formattableActivity: FormattableActivity? {
        didSet {
            setupActivity()
            setupRouter()
        }
    }
    var site: JetpackSiteRef?

    var rewindStatus: RewindStatus?

    weak var presenter: ActivityPresenter?

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
    @IBOutlet private var backupStackView: UIStackView!
    @IBOutlet private var contentStackView: UIStackView!
    @IBOutlet private var containerView: UIView!

    @IBOutlet weak var warningButton: MultilineButton!

    @IBOutlet private var bottomConstaint: NSLayoutConstraint!

    @IBOutlet private var rewindButton: UIButton!
    @IBOutlet private var backupButton: UIButton!

    private var activity: Activity?

    var router: ActivityContentRouter?

    override func viewDidLoad() {
        setupLabelStyles()
        setupViews()
        setupText()
        setupAccesibility()
        hideRestoreIfNeeded()
        showWarningIfNeeded()
        WPAnalytics.track(.activityLogDetailViewed, withProperties: ["source": presentedFrom()])
    }

    @IBAction func rewindButtonTapped(sender: UIButton) {
        guard let activity = activity else {
            return
        }
        presenter?.presentRestoreFor(activity: activity, from: "\(presentedFrom())/detail")
    }

    @IBAction func backupButtonTapped(sender: UIButton) {
        guard let activity = activity else {
            return
        }
        presenter?.presentBackupFor(activity: activity, from: "\(presentedFrom())/detail")
    }

    @IBAction func warningTapped(_ sender: Any) {
        guard let url = URL(string: Constants.supportUrl) else {
            return
        }

        let navController = UINavigationController(rootViewController: WebViewControllerFactory.controller(url: url, source: "activity_detail_warning"))

        present(navController, animated: true)
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

        backupButton.setTitleColor(.primary, for: .normal)
        backupButton.setTitleColor(.primaryDark, for: .highlighted)
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
            bottomConstaint.constant = 0
            rewindStackView.isHidden = false
            backupStackView.isHidden = false
        }

        if let avatar = activity.actor?.avatarURL, let avatarURL = URL(string: avatar) {
            imageView.backgroundColor = .neutral(.shade20)
            imageView.downloadImage(from: avatarURL, placeholderImage: .gridicon(.user, size: Constants.gridiconSize))
        } else if let iconType = WPStyleGuide.ActivityStyleGuide.getGridiconTypeForActivity(activity) {
            imageView.contentMode = .center
            imageView.backgroundColor = WPStyleGuide.ActivityStyleGuide.getColorByActivityStatus(activity)
            imageView.image = .gridicon(iconType, size: Constants.gridiconSize)
        } else {
            imageView.isHidden = true
        }

        rewindButton.naturalContentHorizontalAlignment = .leading
        rewindButton.setImage(.gridicon(.history, size: Constants.gridiconSize), for: .normal)

        backupButton.naturalContentHorizontalAlignment = .leading
        backupButton.setImage(.gridicon(.cloudDownload, size: Constants.gridiconSize), for: .normal)

        let attributedTitle = WPStyleGuide.Jetpack.highlightString(RewindStatus.Strings.multisiteNotAvailableSubstring,
                                                                   inString: RewindStatus.Strings.multisiteNotAvailable)

        warningButton.setAttributedTitle(attributedTitle, for: .normal)
        warningButton.setTitleColor(.systemGray, for: .normal)
        warningButton.titleLabel?.numberOfLines = 0
        warningButton.titleLabel?.lineBreakMode = .byWordWrapping
        warningButton.naturalContentHorizontalAlignment = .leading
        warningButton.backgroundColor = view.backgroundColor
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

        rewindButton.setTitle(NSLocalizedString("Restore", comment: "Title for button allowing user to restore their Jetpack site"),
                                                for: .normal)
        backupButton.setTitle(NSLocalizedString("Download backup", comment: "Title for button allowing user to backup their Jetpack site"),
                                                for: .normal)

        let dateFormatter = ActivityDateFormatting.longDateFormatter(for: site, withTime: false)
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

    private func hideRestoreIfNeeded() {
        guard let isRestoreActive = rewindStatus?.isActive() else {
            return
        }

        rewindStackView.isHidden = !isRestoreActive
    }

    private func showWarningIfNeeded() {
        guard let isMultiSite = rewindStatus?.isMultisite() else {
            return
        }

        warningButton.isHidden = !isMultiSite
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

    private func presentedFrom() -> String {
        if presenter is JetpackActivityLogViewController {
            return "activity_log"
        } else if presenter is BackupListViewController {
            return "backup"
        } else {
            return "unknown"
        }
    }

    private enum Constants {
        static let gridiconSize: CGSize = CGSize(width: 24, height: 24)
        static let supportUrl = "https://jetpack.com/support/backup/"
    }
}

// MARK: - UITextViewDelegate

extension ActivityDetailViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        router?.routeTo(URL)
        return false
    }
}
