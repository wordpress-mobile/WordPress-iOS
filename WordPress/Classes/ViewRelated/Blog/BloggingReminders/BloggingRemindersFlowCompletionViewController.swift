import UIKit
import WordPressUI

final class BloggingRemindersFlowCompletionViewController: UIViewController {

    // MARK: - Subviews

    private let scrollView = UIScrollView()

    private let imageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "reminders-bell"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .systemYellow
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = WPStyleGuide.serifFontForTextStyle(.title1, fontWeight: .semibold)
        label.numberOfLines = 2
        label.textAlignment = .center
        label.text = TextContent.completionTitle
        return label
    }()

    private let promptLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = .preferredFont(forTextStyle: .body)
        label.numberOfLines = 6
        label.textAlignment = .center
        label.textColor = .label
        return label
    }()

    private let hintLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = .preferredFont(forTextStyle: .footnote)
        label.text = TextContent.completionUpdateHint
        label.numberOfLines = 3
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var doneButton: UIButton = {
        var configuration = UIButton.Configuration.primary()
        configuration.title = TextContent.doneButtonTitle

        let button = UIButton(configuration: configuration, primaryAction: nil)
        button.setTitle(TextContent.doneButtonTitle, for: .normal)
        button.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        return button
    }()

    private let bottomBarView = BottomToolbarView()

    // MARK: - Initializers

    let blog: Blog
    let calendar: Calendar
    let tracker: BloggingRemindersTracker

    init(blog: Blog, tracker: BloggingRemindersTracker, calendar: Calendar? = nil) {
        self.blog = blog
        self.tracker = tracker

        self.calendar = calendar ?? {
            var calendar = Calendar.current
            calendar.locale = Locale.autoupdatingCurrent
            return calendar
        }()

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

        view.backgroundColor = .systemBackground

        setupView()
        setupBottomBar()

        configurePromptLabel()
        configureTitleLabel()

        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        tracker.screenShown(.allSet)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // If a parent VC is being dismissed, and this is the last view shown in its navigation controller, we'll assume
        // the flow was completed.
        if isBeingDismissedDirectlyOrByAncestor() && navigationController?.viewControllers.last == self {
            tracker.flowCompleted()
        }
    }

    // MARK: - View Configuration

    private func setupView() {
        let stackView = UIStackView(axis: .vertical, alignment: .center, spacing: 8, [
            imageView,
            titleLabel,
            promptLabel,
            hintLabel
        ])
        stackView.setCustomSpacing(16, after: titleLabel)

        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = false

        scrollView.addSubview(stackView)
        view.addSubview(scrollView)

        var insets = UIEdgeInsets(.all, 20)
        insets.top = 48

        stackView.pinEdges(insets: insets)
        stackView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -40).isActive = true

        scrollView.pinEdges()
    }

    private func setupBottomBar() {
        bottomBarView.contentView.addSubview(doneButton)
        doneButton.pinEdges()

        bottomBarView.configure(in: self, scrollView: scrollView)
    }

    // Populates the prompt label with formatted text detailing the reminders set by the user.
    //
    private func configurePromptLabel() {
        guard let scheduler = try? ReminderScheduleCoordinator() else {
            return
        }

        let schedule = scheduler.schedule(for: blog)
        let formatter = BloggingRemindersScheduleFormatter()

        let style = NSMutableParagraphStyle()
        style.lineSpacing = Metrics.promptTextLineSpacing
        style.alignment = .center

        // The line break mode seems to be necessary to make it possible for the label to adjust it's
        // size to stay under the allowed number of lines.
        // To understand why this is necessary: turn on the largest available font size under iOS
        // accessibility settings, and see that the label adjusts the font size to stay within the
        // available space and allowed max number of lines.
        style.lineBreakMode = .byTruncatingTail

        let defaultAttributes: [NSAttributedString.Key: AnyObject] = [
            .paragraphStyle: style,
            .foregroundColor: UIColor.label,
        ]

        let promptText = NSMutableAttributedString(attributedString: formatter.longScheduleDescription(for: schedule, time: scheduler.scheduledTime(for: blog).toLocalTime()))

        promptText.addAttributes(defaultAttributes, range: NSRange(location: 0, length: promptText.length))
        promptLabel.attributedText = promptText
    }

    private func configureTitleLabel() {
        guard let scheduler = try? ReminderScheduleCoordinator() else {
            return
        }

        if scheduler.schedule(for: blog) == .none {
            titleLabel.text = TextContent.remindersRemovedTitle
        } else {
            titleLabel.text = TextContent.completionTitle
        }
    }
}

    // MARK: - Actions
extension BloggingRemindersFlowCompletionViewController: BloggingRemindersActions {

    // MARK: - BloggingRemindersActions

    @objc func doneButtonTapped() {
        dismiss(from: .continue, screen: .allSet, tracker: tracker)
    }

    @objc private func dismissTapped() {
        dismiss(from: .dismiss, screen: .allSet, tracker: tracker)
    }
}

// MARK: - Constants

private enum TextContent {
    static let completionTitle = NSLocalizedString("All set!", comment: "Title of the completion screen of the Blogging Reminders Settings screen.")

    static let remindersRemovedTitle = NSLocalizedString("Reminders removed", comment: "Title of the completion screen of the Blogging Reminders Settings screen when the reminders are removed.")

    static let completionUpdateHint = NSLocalizedString("You can update this any time via My Site > Site Settings",
                                                        comment: "Prompt shown on the completion screen of the Blogging Reminders Settings screen.")

    static let doneButtonTitle = NSLocalizedString("Done", comment: "Title for a Done button.")
}

private enum Metrics {
    static let promptTextLineSpacing: CGFloat = 1.5
}
