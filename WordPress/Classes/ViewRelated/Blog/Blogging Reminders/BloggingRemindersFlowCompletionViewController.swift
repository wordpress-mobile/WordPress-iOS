import UIKit


class BloggingRemindersFlowCompletionViewController: UIViewController {

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
        label.font = WPStyleGuide.serifFontForTextStyle(.title1, fontWeight: .semibold)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.text = TextContent.completionTitle
        return label
    }()

    private let promptLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .text
        return label
    }()

    private let hintLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.text = TextContent.completionUpdateHint
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        return label
    }()

    private let doneButton: UIButton = {
        let button = FancyButton()
        button.isPrimary = true
        button.setTitle(TextContent.doneButtonTitle, for: .normal)
        button.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
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

    // MARK: - Initializers

    let calendar: Calendar
    let selectedDays: [BloggingRemindersScheduler.Weekday]
    let tracker: BloggingRemindersTracker

    init(selectedDays: [BloggingRemindersScheduler.Weekday], tracker: BloggingRemindersTracker, calendar: Calendar? = nil) {
        self.selectedDays = selectedDays
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
        view.backgroundColor = .basicBackground
        view.addSubview(dismissButton)

        configureStackView()
        configureConstraints()
        configurePromptLabel()

        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        tracker.screenShown(.allSet)

        super.viewDidAppear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // If a parent VC is being dismissed, and this is the last view shown in its navigation controller, we'll assume
        // the flow was completed.
        if isBeingDismissedDirectlyOrByAncestor() && navigationController?.viewControllers.last == self {
            tracker.flowCompleted()
        }

    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        calculatePreferredContentSize()
    }

    func calculatePreferredContentSize() {
        let size = CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        preferredContentSize = view.systemLayoutSizeFitting(size)
    }

    // MARK: - View Configuration

    private func configureStackView() {
        view.addSubview(stackView)

        stackView.addArrangedSubviews([
            imageView,
            titleLabel,
            promptLabel,
            hintLabel,
            doneButton
        ])
        stackView.setCustomSpacing(Metrics.afterHintSpacing, after: hintLabel)
    }

    private func configureConstraints() {
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Metrics.edgeMargins.left),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Metrics.edgeMargins.right),
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: Metrics.edgeMargins.top),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeBottomAnchor, constant: -Metrics.edgeMargins.bottom),

            doneButton.heightAnchor.constraint(equalToConstant: Metrics.doneButtonHeight),
            doneButton.widthAnchor.constraint(equalTo: stackView.widthAnchor),

            dismissButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Metrics.edgeMargins.right),
            dismissButton.topAnchor.constraint(equalTo: view.topAnchor, constant: Metrics.edgeMargins.right)
        ])
    }

    // Populates the prompt label with formatted text detailing the reminders set by the user.
    //
    private func configurePromptLabel() {
        guard selectedDays.isEmpty == false else {
            promptLabel.text = TextContent.noRemindersPrompt
            return
        }

        // We want the days sorted by their localized index because under some locale configurations
        // Sunday is the first day of the week, whereas in some other localizations Monday comes first.
        let sortedDays = selectedDays.sorted { (first, second) -> Bool in
            let firstIndex = self.calendar.localizedWeekdayIndex(unlocalizedWeekdayIndex: first.rawValue)
            let secondIndex = self.calendar.localizedWeekdayIndex(unlocalizedWeekdayIndex: second.rawValue)

            return firstIndex < secondIndex
        }

        let markedUpDays: [String] = sortedDays.compactMap({ [weak self] day in
            guard let self = self else {
                return nil
            }

            return "<strong>\(self.calendar.weekdaySymbols[day.rawValue])</strong>"
        })

        let promptText: String

        if selectedDays.count == 1 {
            promptText = String(format: TextContent.completionPromptSingular, markedUpDays.first ?? "")
        } else {
            let formatter = ListFormatter()
            let formattedDays = formatter.string(from: markedUpDays) ?? ""
            promptText = String(format: TextContent.completionPromptPlural, "<strong>\(selectedDays.count)</strong>", formattedDays)
        }

        let style = NSMutableParagraphStyle()
        style.lineSpacing = Metrics.promptTextLineSpacing
        style.alignment = .center

        promptLabel.attributedText = NSAttributedString.attributedStringWithHTML(promptText,
                                                                                 attributes: [ .BodyAttribute: [ .font: UIFont.preferredFont(forTextStyle: .body),
                                                                                                                 .paragraphStyle: style,
                                                                                                                 .foregroundColor: UIColor.text ] ])
    }

    // MARK: - Actions

    @objc func doneButtonTapped() {
        tracker.buttonPressed(button: .continue, screen: .allSet)

        dismiss(animated: true, completion: nil)
    }

    @objc private func dismissTapped() {
        tracker.buttonPressed(button: .dismiss, screen: .allSet)

        dismiss(animated: true, completion: nil)
    }
}

// MARK: - DrawerPresentable

extension BloggingRemindersFlowCompletionViewController: DrawerPresentable {
    var collapsedHeight: DrawerHeight {
        return .intrinsicHeight
    }
}

extension BloggingRemindersFlowCompletionViewController: ChildDrawerPositionable {
    var preferredDrawerPosition: DrawerPosition {
        return .collapsed
    }
}

// MARK: - Constants

private enum TextContent {
    static let completionTitle = NSLocalizedString("All set!", comment: "Title of the completion screen of the Blogging Reminders Settings screen.")

    // Ideally we should use stringsdict to translate plurals, but GlotPress currently doesn't support this.
    static let completionPromptSingular = NSLocalizedString("You'll get a reminder to blog <strong>once</strong> a week on %@.",
                                                          comment: "Blogging Reminders description confirming a user's choices. The placeholder will be replaced at runtime with a day of the week. The HTML markup is used to bold the word 'once'.")

    static let completionPromptPlural = NSLocalizedString("You'll get reminders to blog %@ times a week on %@.",
                                                          comment: "Blogging Reminders description confirming a user's choices. The first placeholder will be populated with a count of the number of times a week they'll be reminded. The second will be a formatted list of days. For example: 'You'll get reminders to blog 2 times a week on Monday and Tuesday.")

    static let noRemindersPrompt = NSLocalizedString("You have no reminders set.", comment: "Text shown to the user when setting up blogging reminders, if they complete the flow and have chosen not to add any reminders.")

    static let completionUpdateHint = NSLocalizedString("You can update this any time via My Site > Site Settings",
                                                        comment: "Prompt shown on the completion screen of the Blogging Reminders Settings screen.")

    static let doneButtonTitle = NSLocalizedString("Done", comment: "Title for a Done button.")
}

private enum Images {
    static let bellImageName = "reminders-bell"
}

private enum Metrics {
    static let edgeMargins = UIEdgeInsets(top: 46, left: 20, bottom: 20, right: 20)
    static let stackSpacing: CGFloat = 20.0
    static let doneButtonHeight: CGFloat = 44.0
    static let afterHintSpacing: CGFloat = 24.0
    static let promptTextLineSpacing: CGFloat = 1.5
}
