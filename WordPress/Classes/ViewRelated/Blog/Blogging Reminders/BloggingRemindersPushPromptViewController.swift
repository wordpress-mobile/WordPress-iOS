import UIKit


class BloggingRemindersPushPromptViewController: UIViewController {

    // MARK: - Subviews

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = Metrics.stackSpacing
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        return stackView
    }()

    private let imageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: Images.bellImageName))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .systemYellow
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.font = WPStyleGuide.serifFontForTextStyle(.title1, fontWeight: .semibold)
        label.numberOfLines = 2
        label.textAlignment = .center
        label.text = TextContent.title
        return label
    }()

    private let promptLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.font = .preferredFont(forTextStyle: .body)
        label.text = TextContent.prompt
        label.numberOfLines = 4
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        return label
    }()

    private let hintLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.font = .preferredFont(forTextStyle: .body)
        label.text = TextContent.hint
        label.numberOfLines = 4
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        return label
    }()

    private let turnOnNotificationsButton: UIButton = {
        let button = FancyButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isPrimary = true
        button.setTitle(TextContent.turnOnButtonTitle, for: .normal)
        button.addTarget(self, action: #selector(turnOnButtonTapped), for: .touchUpInside)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        return button
    }()

    private let dismissButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(.gridicon(.cross), for: .normal)
        button.tintColor = .secondaryLabel
        button.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Properties

    /// Indicates whether push notifications have been disabled or not.
    ///
    private var pushNotificationsAuthorized: UNAuthorizationStatus = .notDetermined {
        didSet {
            navigateIfNecessary()
        }
    }

    /// Analytics tracker
    ///
    private let tracker: BloggingRemindersTracker

    /// The closure that will be called once push notifications have been authorized.
    ///
    private let onAuthorized: () -> ()

    // MARK: - Initializers

    init(
        tracker: BloggingRemindersTracker,
        onAuthorized: @escaping () -> ()) {

        self.tracker = tracker
        self.onAuthorized = onAuthorized

        super.init(nibName: nil, bundle: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(applicationBecameActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    required init?(coder: NSCoder) {
        // This VC is designed to be initialized programmatically.
        fatalError("Use init(tracker:) instead")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .basicBackground
        view.addSubview(dismissButton)

        configureStackView()

        view.addSubview(turnOnNotificationsButton)
        configureConstraints()

        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        tracker.screenShown(.enableNotifications)

        super.viewDidAppear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // If a parent VC is being dismissed, and this is the last view shown in its navigation controller, we'll assume
        // the flow was completed.
        if isBeingDismissedDirectlyOrByAncestor() && navigationController?.viewControllers.last == self {
            tracker.flowDismissed(source: .enableNotifications)
        }

    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        calculatePreferredContentSize()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        hintLabel.isHidden = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
    }

    private func calculatePreferredContentSize() {
        let size = CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        preferredContentSize = view.systemLayoutSizeFitting(size)
    }

    @objc
    private func applicationBecameActive() {
        refreshPushAuthorizationStatus()
    }

    // MARK: - View Configuration

    private func configureStackView() {
        view.addSubview(stackView)

        stackView.addArrangedSubviews([
            imageView,
            titleLabel,
            promptLabel,
            hintLabel
        ])
    }

    private func configureConstraints() {
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Metrics.edgeMargins.left),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Metrics.edgeMargins.right),
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: Metrics.edgeMargins.top),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: turnOnNotificationsButton.topAnchor, constant: Metrics.edgeMargins.bottom),

            turnOnNotificationsButton.heightAnchor.constraint(greaterThanOrEqualToConstant: Metrics.turnOnButtonHeight),
            turnOnNotificationsButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Metrics.edgeMargins.left),
            turnOnNotificationsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Metrics.edgeMargins.right),
            turnOnNotificationsButton.bottomAnchor.constraint(equalTo: view.safeBottomAnchor, constant: -Metrics.edgeMargins.bottom),

            dismissButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Metrics.dismissButtonMargin),
            dismissButton.topAnchor.constraint(equalTo: view.topAnchor, constant: Metrics.dismissButtonMargin)
        ])
    }

    // MARK: - Actions

    @objc private func turnOnButtonTapped() {
        tracker.buttonPressed(button: .notificationSettings, screen: .enableNotifications)

        if let targetURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(targetURL)
        } else {
            assertionFailure("Couldn't unwrap Settings URL")
        }
    }

    private func refreshPushAuthorizationStatus() {
        PushNotificationsManager.shared.loadAuthorizationStatus { status in
            self.pushNotificationsAuthorized = status
        }
    }

    func navigateIfNecessary() {
        // If push has been authorized, continue the flow
        if pushNotificationsAuthorized == .authorized {
            onAuthorized()
        }
    }
}

// MARK: - BloggingRemindersActions
extension BloggingRemindersPushPromptViewController: BloggingRemindersActions {

    @objc private func dismissTapped() {
        dismiss(from: .dismiss, screen: .enableNotifications, tracker: tracker)
    }
}

// MARK: - DrawerPresentable

extension BloggingRemindersPushPromptViewController: DrawerPresentable {
    var collapsedHeight: DrawerHeight {
        return .maxHeight
    }
}

extension BloggingRemindersPushPromptViewController: ChildDrawerPositionable {
    var preferredDrawerPosition: DrawerPosition {
        return .expanded
    }
}

// MARK: - Constants

private enum TextContent {
    static let title = NSLocalizedString("Turn on push notifications", comment: "Title of the screen in the Blogging Reminders flow which prompts users to enable push notifications.")

    static let prompt = NSLocalizedString("To use blogging reminders, you'll need to turn on push notifications.",
                                                    comment: "Prompt telling users that they need to enable push notifications on their device to use the blogging reminders feature.")

    static let hint = NSLocalizedString("Go to Settings → Notifications → WordPress, and toggle Allow Notifications.",
                                                    comment: "Instruction telling the user how to enable notifications in their device's system Settings app. The section names here should match those in Settings.")

    static let turnOnButtonTitle = NSLocalizedString("Turn on notifications", comment: "Title for a button which takes the user to the WordPress app's settings in the system Settings app.")
}

private enum Images {
    static let bellImageName = "reminders-bell"
}

private enum Metrics {
    static let dismissButtonMargin: CGFloat = 20.0
    static let edgeMargins = UIEdgeInsets(top: 80, left: 28, bottom: 80, right: 28)
    static let stackSpacing: CGFloat = 20.0
    static let turnOnButtonHeight: CGFloat = 44.0
}
