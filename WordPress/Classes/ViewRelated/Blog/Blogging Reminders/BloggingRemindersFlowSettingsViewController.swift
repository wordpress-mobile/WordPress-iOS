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

    private let imageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: Images.calendarImageName))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .systemRed
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.75
        label.font = WPStyleGuide.serifFontForTextStyle(.title1, fontWeight: .semibold)
        label.numberOfLines = 3
        label.textAlignment = .center
        label.text = TextContent.settingsPrompt
        return label
    }()

    private let promptLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.75
        label.font = .preferredFont(forTextStyle: .body)
        label.text = TextContent.settingsUpdatePrompt
        label.numberOfLines = 2
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.setContentHuggingPriority(.defaultLow, for: .vertical)
        return label
    }()

    private let button: UIButton = {
        let button = FancyButton()
        button.isPrimary = true
        button.addTarget(self, action: #selector(notifyMeButtonTapped), for: .touchUpInside)
        return button
    }()

    private let daysOuterStackView: UIStackView = {
        let daysOuterStack = UIStackView()
        daysOuterStack.axis = .vertical
        daysOuterStack.alignment = .center
        daysOuterStack.spacing = Metrics.innerStackSpacing
        daysOuterStack.distribution = .fillEqually
        return daysOuterStack
    }()

    private let daysTopInnerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = Metrics.innerStackSpacing
        return stackView
    }()

    private let daysBottomInnerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = Metrics.innerStackSpacing
        return stackView
    }()

    private lazy var frequencyLabel: UILabel = {
        let label = UILabel()

        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.numberOfLines = 2
        label.textAlignment = .center

        return label
    }()

    // adds dividers for the time selection
    private func makeDivider() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.divider
        return view
    }

    private lazy var topDivider: UIView = {
        makeDivider()
    }()

    private lazy var bottomDivider: UIView = {
        makeDivider()
    }()

    private lazy var timeSelectionButton: TimeSelectionButton = {
        /// - TODO: inject the correct time here
        let button = TimeSelectionButton(selectedTime: "3:00 PM")
        button.isUserInteractionEnabled = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(navigateToTimePicker), for: .touchUpInside)
        return button
    }()

    @objc private func navigateToTimePicker() {
        /// - TODO: add the actual navigation code here
        print("Navigation Goes Here")
    }


    private lazy var timeSelectionStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.addArrangedSubviews([topDivider, timeSelectionButton, bottomDivider])
        return stackView
    }()

    private lazy var bottomTipPanel: UIView = {
        let view = UIView()
        view.backgroundColor = .quaternaryBackground
        view.layer.cornerRadius = Metrics.tipPanelCornerRadius

        self.populateTipPanel(view)

        return view
    }()

    private func populateTipPanel(_ panel: UIView) {
        let innerStack = UIStackView()
        innerStack.spacing = Metrics.tipPanelHorizontalStackSpacing
        innerStack.translatesAutoresizingMaskIntoConstraints = false
        innerStack.axis = .horizontal
        innerStack.alignment = .top
        panel.addSubview(innerStack)
        panel.pinSubviewToAllEdges(innerStack, insets: Metrics.tipPanelMargins)

        let trophy = UIImageView(image: .gridicon(.trophy, size: Metrics.tipsTrophyImageSize))
        trophy.tintColor = .secondaryLabel

        let rightStack = UIStackView()
        rightStack.spacing = Metrics.tipPanelVerticalStackSpacing
        rightStack.axis = .vertical
        rightStack.alignment = .leading

        innerStack.addArrangedSubviews([trophy, rightStack])

        let tipLabel = UILabel()
        tipLabel.adjustsFontForContentSizeCategory = true
        tipLabel.textColor = .secondaryLabel
        tipLabel.font = WPStyleGuide.fontForTextStyle(.callout, fontWeight: .semibold)
        tipLabel.text = TextContent.tipPanelTitle

        let tipDescriptionLabel = UILabel()
        tipDescriptionLabel.adjustsFontForContentSizeCategory = true
        tipDescriptionLabel.textColor = .secondaryLabel
        tipDescriptionLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        tipDescriptionLabel.text = TextContent.tipPanelDescription
        tipDescriptionLabel.numberOfLines = 0

        rightStack.addArrangedSubviews([tipLabel, tipDescriptionLabel])
    }

    private let dismissButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(.gridicon(.cross), for: .normal)
        button.tintColor = .secondaryLabel
        button.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Properties

    private let calendar: Calendar
    private let scheduler: BloggingRemindersScheduler
    private let scheduleFormatter = BloggingRemindersScheduleFormatter()
    private var weekdays: [BloggingRemindersScheduler.Weekday] {
        didSet {
            refreshNextButton()
        }
    }

    /// The weekdays that have been saved / scheduled in a previous blogging reminders configuration.
    ///
    private let previousWeekdays: [BloggingRemindersScheduler.Weekday]

    // MARK: - Initializers

    private let blog: Blog
    private let tracker: BloggingRemindersTracker

    init(
        for blog: Blog,
        tracker: BloggingRemindersTracker,
        calendar: Calendar? = nil) throws {

        self.blog = blog
        self.tracker = tracker
        self.calendar = calendar ?? {
            var calendar = Calendar.current
            calendar.locale = Locale.autoupdatingCurrent

            return calendar
        }()

        scheduler = try BloggingRemindersScheduler()

        switch self.scheduler.schedule(for: blog) {
        case .none:
            previousWeekdays = []
        case .weekdays(let scheduledWeekdays):
            previousWeekdays = scheduledWeekdays
        }

        weekdays = previousWeekdays

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
        populateCalendarDays()
        refreshNextButton()
        refreshFrequencyLabel()
    }

    override func viewDidAppear(_ animated: Bool) {
        tracker.screenShown(.dayPicker)

        super.viewDidAppear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // If a parent VC is being dismissed, and this is the last view shown in its navigation controller, we'll assume
        // the flow was interrupted.
        if isBeingDismissedDirectlyOrByAncestor() && navigationController?.viewControllers.last == self {
            tracker.flowDismissed(source: .dayPicker)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        calculatePreferredContentSize()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        bottomTipPanel.isHidden = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        imageView.isHidden = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
    }

    private func calculatePreferredContentSize() {
        let size = CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        preferredContentSize = view.systemLayoutSizeFitting(size)
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
            frequencyLabel,
            timeSelectionStackView,
            fillerView,
            bottomTipPanel,
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

            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),

            button.heightAnchor.constraint(greaterThanOrEqualToConstant: Metrics.buttonHeight),
            button.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            bottomTipPanel.widthAnchor.constraint(equalTo: stackView.widthAnchor),

            dismissButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Metrics.edgeMargins.right),
            dismissButton.topAnchor.constraint(equalTo: view.topAnchor, constant: Metrics.edgeMargins.right),
            topDivider.heightAnchor.constraint(equalToConstant: Metrics.dividerHeight),
            bottomDivider.heightAnchor.constraint(equalToConstant: Metrics.dividerHeight),
            timeSelectionStackView.heightAnchor.constraint(equalToConstant: Metrics.buttonHeight),
            timeSelectionStackView.widthAnchor.constraint(equalTo: stackView.widthAnchor)
        ])
    }

    // MARK: - Calendar Days Buttons

    /// Creates the calendar day toggle buttons.  This is a convenience method to take care of the mapping of the day index, from Apple's calendar, to
    /// our `BloggingRemindersScheduler.Weekday`.  In theory this should never return `nil`, but we're allowing it to avoid possible crashes.
    ///
    /// - Parameters:
    ///     - weekday: the weekday the button is for.
    ///
    /// - Returns: the requested toggle button.
    ///
    private func createCalendarDayToggleButton(localizedWeekdayDayIndex: Int) -> CalendarDayToggleButton? {
        let weekdayIndex = calendar.unlocalizedWeekdayIndex(localizedWeekdayIndex: localizedWeekdayDayIndex)

        guard let weekday = BloggingRemindersScheduler.Weekday(rawValue: weekdayIndex) else {
            return nil
        }

        let isSelected = weekdays.contains(weekday)
        let button = CalendarDayToggleButton(
            weekday: weekday,
            dayName: calendar.shortWeekdaySymbols[weekdayIndex].uppercased(),
            isSelected: isSelected) { [weak self] button in

            guard let self = self else {
                return
            }

            if button.isSelected {
                self.weekdays.append(button.weekday)
            } else {
                self.weekdays.removeAll { weekday in
                    weekday == button.weekday
                }
            }

            self.refreshFrequencyLabel()
        }

        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.titleLabel?.adjustsFontSizeToFitWidth = true

        return button
    }

    private func populateCalendarDays() {
        daysOuterStackView.addArrangedSubviews([daysTopInnerStackView, daysBottomInnerStackView])

        let topRow = 0 ..< Metrics.topRowDayCount
        let bottomRow = Metrics.topRowDayCount ..< calendar.shortWeekdaySymbols.count

        daysTopInnerStackView.addArrangedSubviews(topRow.compactMap({ createCalendarDayToggleButton(localizedWeekdayDayIndex: $0) }))
        daysBottomInnerStackView.addArrangedSubviews(bottomRow.compactMap({ createCalendarDayToggleButton(localizedWeekdayDayIndex: $0) }))
    }

    private func refreshNextButton() {
        if previousWeekdays.isEmpty {
            button.setTitle(TextContent.nextButtonTitle, for: .normal)
            button.isEnabled = !weekdays.isEmpty
        } else if weekdays == previousWeekdays {
            button.setTitle(TextContent.nextButtonTitle, for: .normal)
            button.isEnabled = true
        } else {
            button.setTitle(TextContent.updateButtonTitle, for: .normal)
            button.isEnabled = true
        }
    }

    private func refreshFrequencyLabel() {
        guard weekdays.count > 0 else {
            frequencyLabel.isHidden = true
            timeSelectionStackView.isHidden = true
            return
        }

        frequencyLabel.isHidden = false
        timeSelectionStackView.isHidden = false

        let defaultAttributes: [NSAttributedString.Key: AnyObject] = [
            .foregroundColor: UIColor.text,
        ]

        let frequencyDescription = scheduleFormatter.shortIntervalDescription(for: .weekdays(weekdays))
        let attributedText = NSMutableAttributedString(attributedString: frequencyDescription)
        attributedText.addAttributes(defaultAttributes, range: NSRange(location: 0, length: attributedText.length))

        frequencyLabel.attributedText = attributedText
        frequencyLabel.sizeToFit()
    }

    // MARK: - Actions

    @objc private func notifyMeButtonTapped() {
        tracker.buttonPressed(button: .continue, screen: .dayPicker)

        scheduleReminders()
    }

    /// Schedules the reminders and shows a VC that requests PN authorization, if necessary.
    ///
    /// - Parameters:
    ///     - showPushPrompt: if `true` the PN authorization prompt VC will be shown.
    ///         When `false`, the VC won't be shown.  This is useful because this method
    ///         can also be called when the refrenced VC is already on-screen.
    ///
    private func scheduleReminders(showPushPrompt: Bool = true) {
        let schedule: BloggingRemindersScheduler.Schedule

        if weekdays.count > 0 {
            schedule = .weekdays(weekdays)
        } else {
            schedule = .none
        }

        scheduler.schedule(schedule, for: blog) { [weak self] result in
            guard let self = self else {
                return
            }

            switch result {
            case .success:
                self.tracker.scheduled(schedule)

                DispatchQueue.main.async { [weak self] in
                    self?.presentCompletionViewController()
                }
            case .failure(let error):
                switch error {
                case BloggingRemindersScheduler.Error.needsPermissionForPushNotifications where showPushPrompt == true:
                    DispatchQueue.main.async { [weak self] in
                        self?.presentPushPromptViewController()
                    }
                default:
                    // The scheduler should normally not fail unless it's because of having no push permissions.
                    // As a simple solution for now, we'll just avoid taking any action if the scheduler did fail.
                    DDLogError("Error scheduling blogging reminders: \(error)")
                    break
                }
            }
        }
    }

    // MARK: - Completion Paths

    private func presentCompletionViewController() {
        let viewController = BloggingRemindersFlowCompletionViewController(blog: blog, tracker: tracker, calendar: calendar)
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func presentPushPromptViewController() {
        let viewController = BloggingRemindersPushPromptViewController(tracker: tracker) { [weak self] in
            self?.scheduleReminders(showPushPrompt: false)
        }
        navigationController?.pushViewController(viewController, animated: true)
    }
}

// MARK: - BloggingRemindersActions
extension BloggingRemindersFlowSettingsViewController: BloggingRemindersActions {

    @objc private func dismissTapped() {
        dismiss(from: .dismiss, screen: .dayPicker, tracker: tracker)
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

    static let nextButtonTitle = NSLocalizedString("Notify me", comment: "Title of button to navigate to the next screen of the blogging reminders flow, setting up push notifications.")

    static let updateButtonTitle = NSLocalizedString("Update", comment: "(Verb) Title of button confirming updating settings for blogging reminders.")

    static let tipPanelTitle = NSLocalizedString("Tip", comment: "Title of a panel shown in the Blogging Reminders Settings screen, providing the user with a helpful tip.")

    static let tipPanelDescription = NSLocalizedString("Posting regularly can help keep your readers engaged, and attract new visitors to your site.", comment: "Informative tip shown to user in the Blogging Reminders Settings screen.")
}

private enum Images {
    static let calendarImageName = "reminders-calendar"
}

private enum Metrics {
    static let edgeMargins = UIEdgeInsets(top: 46, left: 20, bottom: 56, right: 20)
    static let tipPanelMargins = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)

    static let stackSpacing: CGFloat = 24.0
    static let innerStackSpacing: CGFloat = 8.0
    static let afterTitleLabelSpacing: CGFloat = 16.0
    static let afterPromptLabelSpacing: CGFloat = 40.0
    static let tipPanelHorizontalStackSpacing: CGFloat = 12.0
    static let tipPanelVerticalStackSpacing: CGFloat = 8.0

    static let buttonHeight: CGFloat = 44.0
    static let tipPanelCornerRadius: CGFloat = 12.0
    static let tipsTrophyImageSize = CGSize(width: 20, height: 20)

    static let topRowDayCount = 4

    static let dividerHeight: CGFloat = .hairlineBorderWidth
}
