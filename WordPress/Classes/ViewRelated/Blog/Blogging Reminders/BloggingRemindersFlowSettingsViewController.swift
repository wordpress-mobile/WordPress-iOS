import UIKit


class BloggingRemindersFlowSettingsViewController: UIViewController {

    // MARK: - Subviews

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = Metrics.stackSpacing
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fill
        return stackView
    }()

    let imageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: Images.calendarImageName))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .systemRed
        return imageView
    }()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = WPStyleGuide.serifFontForTextStyle(.title1, fontWeight: .semibold)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.text = TextContent.settingsPrompt
        return label
    }()

    let promptLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.text = TextContent.settingsUpdatePrompt
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.setContentHuggingPriority(.defaultLow, for: .vertical)
        return label
    }()

    let button: UIButton = {
        let button = FancyButton()
        button.isPrimary = true
        button.setTitle(TextContent.nextButtonTitle, for: .normal)
        button.addTarget(self, action: #selector(notifyMeButtonTapped), for: .touchUpInside)
        return button
    }()

    let daysOuterStackView: UIStackView = {
        let daysOuterStack = UIStackView()
        daysOuterStack.axis = .vertical
        daysOuterStack.alignment = .center
        daysOuterStack.spacing = Metrics.innerStackSpacing
        return daysOuterStack
    }()

    let daysTopInnerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = Metrics.innerStackSpacing
        return stackView
    }()

    let daysBottomInnerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = Metrics.innerStackSpacing
        return stackView
    }()

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .basicBackground

        configureStackView()
        configureConstraints()
        populateCalendarDays()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        calculatePreferredContentSize()
    }

    private func calculatePreferredContentSize() {
        let size = CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        preferredContentSize = stackView.systemLayoutSizeFitting(size)
    }

    // MARK: - View Configuration

    private func configureStackView() {
        view.addSubview(stackView)

        // Used to expand the stackview vertically
        let fillerView = UIView()
        fillerView.translatesAutoresizingMaskIntoConstraints = false
        fillerView.setContentHuggingPriority(.defaultLow, for: .vertical)
        fillerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 0.0).isActive = true

        let bottomPadding = UIView()

        stackView.addArrangedSubviews([
            imageView,
            titleLabel,
            promptLabel,
            daysOuterStackView,
            fillerView,
            bottomPadding,
            button,
            UIView()
        ])

        stackView.setCustomSpacing(Metrics.afterTitleLabelSpacing, after: titleLabel)
        stackView.setCustomSpacing(Metrics.afterPromptLabelSpacing, after: promptLabel)
    }

    private func configureConstraints() {
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Metrics.edgeMargins.left),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Metrics.edgeMargins.right),
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: Metrics.edgeMargins.top),
            stackView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor, constant: -Metrics.edgeMargins.bottom),
            button.heightAnchor.constraint(equalToConstant: Metrics.buttonHeight),
            button.widthAnchor.constraint(equalTo: stackView.widthAnchor)
        ])
    }

    private func populateCalendarDays() {
        daysOuterStackView.addArrangedSubviews([daysTopInnerStackView, daysBottomInnerStackView])

        let topRow = days[0..<4]    // First 4 days
        let bottomRow = days[4..<days.count]    // Last 3 days
        daysTopInnerStackView.addArrangedSubviews(topRow.map({ CalendarDayToggleButton(weekday: $0) }))
        daysBottomInnerStackView.addArrangedSubviews(bottomRow.map({ CalendarDayToggleButton(weekday: $0) }))
    }

    /// Localized short weekday names, starting at the correct weekday for the current calendar
    private let days: [String] = {
        var calendar = Calendar.current
        calendar.locale = Locale.autoupdatingCurrent
        let firstWeekday = calendar.firstWeekday
        var symbols = calendar.shortWeekdaySymbols

        // Switch around the order of days so that the correct day is at the beginning
        let firstWeekdayToEnd = symbols[firstWeekday-1 ..< Calendar.current.shortWeekdaySymbols.count]
        let beginningToFirstWeekday = symbols[0 ..< firstWeekday - 1]

        return Array(firstWeekdayToEnd + beginningToFirstWeekday)
    }()

    // MARK: - Actions

    @objc private func notifyMeButtonTapped() {
        navigationController?.pushViewController(BloggingRemindersFlowCompletionViewController(), animated: true)
    }
}

extension BloggingRemindersFlowSettingsViewController: DrawerPresentable {
    var collapsedHeight: DrawerHeight {
        return .maxHeight
    }
}

extension BloggingRemindersFlowSettingsViewController: ChildDrawerPositionable {
    var preferredDrawerPosition: DrawerPosition {
        return .expanded
    }
}

private enum TextContent {
    static let settingsPrompt = NSLocalizedString("Select the days you want to blog on",
                                                  comment: "Prompt shown on the Blogging Reminders Settings screen.")

    static let settingsUpdatePrompt = NSLocalizedString("You can update this anytime",
                                                        comment: "Prompt shown on the Blogging Reminders Settings screen.")

    static let nextButtonTitle = NSLocalizedString("Next", comment: "Title of button to navigate to the next screen.")
}

private enum Images {
    static let calendarImageName = "reminders-calendar"
}

private enum Metrics {
    static let stackSpacing: CGFloat = 24.0
    static let edgeMargins = UIEdgeInsets(top: 46, left: 20, bottom: 56, right: 20)
    static let innerStackSpacing: CGFloat = 8.0
    static let afterTitleLabelSpacing: CGFloat = 16.0
    static let afterPromptLabelSpacing: CGFloat = 40.0
    static let buttonHeight: CGFloat = 44.0
}
