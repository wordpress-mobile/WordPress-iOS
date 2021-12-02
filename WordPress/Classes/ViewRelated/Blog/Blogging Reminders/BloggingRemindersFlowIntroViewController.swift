import UIKit

class BloggingRemindersFlowIntroViewController: UIViewController {

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
        let imageView = UIImageView(image: UIImage(named: Images.celebrationImageName))
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
        label.text = TextContent.introTitle
        return label
    }()

    private let promptLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.font = .preferredFont(forTextStyle: .body)
        label.numberOfLines = 5
        label.textAlignment = .center
        return label
    }()

    private let getStartedButton: UIButton = {
        let button = FancyButton()
        button.isPrimary = true
        button.setTitle(TextContent.introButtonTitle, for: .normal)
        button.addTarget(self, action: #selector(getStartedTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Initializers

    private let blog: Blog
    private let tracker: BloggingRemindersTracker
    private let source: BloggingRemindersTracker.FlowStartSource
    private weak var delegate: BloggingRemindersFlowDelegate?

    private var introDescription: String {
        switch source {
        case .publishFlow:
            return TextContent.postPublishingintroDescription
        case .blogSettings,
             .notificationSettings,
             .statsInsights:
            return TextContent.siteSettingsIntroDescription
        }
    }

    init(for blog: Blog,
         tracker: BloggingRemindersTracker,
         source: BloggingRemindersTracker.FlowStartSource,
         delegate: BloggingRemindersFlowDelegate? = nil) {
        self.blog = blog
        self.tracker = tracker
        self.source = source
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        // This VC is designed to be instantiated programmatically.  If we ever need to initialize this VC
        // from a coder, we can implement support for it - but I don't think it's necessary right now.
        // - diegoreymendez
        fatalError("Use init(tracker:) instead")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .basicBackground

        configureStackView()
        configureConstraints()
        promptLabel.text = introDescription
    }

    override func viewDidAppear(_ animated: Bool) {
        tracker.screenShown(.main)

        super.viewDidAppear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // If a parent VC is being dismissed, and this is the last view shown in its navigation controller, we'll assume
        // the flow was interrupted.
        if isBeingDismissedDirectlyOrByAncestor() && navigationController?.viewControllers.last == self {
            tracker.flowDismissed(source: .main)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        calculatePreferredContentSize()
    }

    private func calculatePreferredContentSize() {
        let size = CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        preferredContentSize = view.systemLayoutSizeFitting(size)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        view.setNeedsLayout()
    }

    // MARK: - View Configuration

    private func configureStackView() {
        view.addSubview(stackView)
        stackView.addArrangedSubviews([
            imageView,
            titleLabel,
            promptLabel,
            getStartedButton
        ])
        stackView.setCustomSpacing(Metrics.afterPromptSpacing, after: promptLabel)
    }

    private func configureConstraints() {
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Metrics.edgeMargins.left),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Metrics.edgeMargins.right),
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: Metrics.edgeMargins.top),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeBottomAnchor, constant: -Metrics.edgeMargins.bottom),

            getStartedButton.heightAnchor.constraint(greaterThanOrEqualToConstant: Metrics.getStartedButtonHeight),
            getStartedButton.widthAnchor.constraint(equalTo: stackView.widthAnchor),
        ])
    }

    @objc private func getStartedTapped() {
        tracker.buttonPressed(button: .continue, screen: .main)

        do {
            let flowSettingsViewController = try BloggingRemindersFlowSettingsViewController(for: blog, tracker: tracker, delegate: delegate)

            navigationController?.pushViewController(flowSettingsViewController, animated: true)
        } catch {
            DDLogError("Could not instantiate the blogging reminders settings VC: \(error.localizedDescription)")
            dismiss(animated: true, completion: nil)
        }
    }
}

extension BloggingRemindersFlowIntroViewController: BloggingRemindersActions {

    @objc private func dismissTapped() {
        dismiss(from: .dismiss, screen: .main, tracker: tracker)
    }
}

// MARK: - DrawerPresentable

extension BloggingRemindersFlowIntroViewController: DrawerPresentable {
    var collapsedHeight: DrawerHeight {
        return .intrinsicHeight
    }
}

// MARK: - ChildDrawerPositionable

extension BloggingRemindersFlowIntroViewController: ChildDrawerPositionable {
    var preferredDrawerPosition: DrawerPosition {
        return .collapsed
    }
}

// MARK: - Constants

private enum TextContent {
    static let introTitle = NSLocalizedString("Set your blogging reminders",
                                              comment: "Title of the Blogging Reminders Settings screen.")

    static let postPublishingintroDescription = NSLocalizedString("Your post is publishing... in the meantime, set up your blogging reminders on days you want to post.",
                                                    comment: "Description on the first screen of the Blogging Reminders Settings flow called aftet post publishing.")

    static let siteSettingsIntroDescription = NSLocalizedString("Set up your blogging reminders on days you want to post.",
                                                            comment: "Description on the first screen of the Blogging Reminders Settings flow called from site settings.")

    static let introButtonTitle = NSLocalizedString("Set reminders",
                                                    comment: "Title of the set goals button in the Blogging Reminders Settings flow.")
}

private enum Images {
    static let celebrationImageName = "reminders-celebration"
}

private enum Metrics {
    static let edgeMargins = UIEdgeInsets(top: 46, left: 20, bottom: 20, right: 20)
    static let stackSpacing: CGFloat = 20.0
    static let afterPromptSpacing: CGFloat = 24.0
    static let getStartedButtonHeight: CGFloat = 44.0
}
