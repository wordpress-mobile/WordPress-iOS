import UIKit

protocol BloggingRemindersFlowDelegate: AnyObject {
    func didSetUpBloggingReminders()
}

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
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.numberOfLines = 2
        label.textAlignment = .center

        return label
    }()

    private lazy var frequencyView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .basicBackground
        view.addSubview(frequencyLabel)
        return view
    }()

    private lazy var topDivider: UIView = {
        makeDivider()
    }()

    private lazy var bottomDivider: UIView = {
        makeDivider()
    }()

    private lazy var timeSelectionButton: TimeSelectionButton = {
        let button = TimeSelectionButton(selectedTime: scheduledTime.toLocalTime())
        button.isUserInteractionEnabled = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(navigateToTimePicker), for: .touchUpInside)
        return button
    }()

    @objc private func navigateToTimePicker() {
        pushTimeSelectionViewController()
    }

    private lazy var timeSelectionView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .basicBackground
        view.addSubview(timeSelectionStackView)
        return view
    }()

    private lazy var timeSelectionStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.addArrangedSubviews([topDivider, timeSelectionButton, bottomDivider])
        return stackView
    }()

    private lazy var trophy: UIView = {
        let trophy = UIImageView(image: .gridicon(.trophy, size: Metrics.tipsTrophyImageSize))
        trophy.translatesAutoresizingMaskIntoConstraints = false
        trophy.tintColor = .secondaryLabel
        return trophy
    }()

    private lazy var tipLabel: UILabel = {
        let tipLabel = UILabel()
        tipLabel.translatesAutoresizingMaskIntoConstraints = false
        tipLabel.adjustsFontForContentSizeCategory = true
        tipLabel.textColor = .secondaryLabel
        tipLabel.font = WPStyleGuide.fontForTextStyle(.callout, fontWeight: .semibold)
        tipLabel.text = TextContent.tipPanelTitle
        return tipLabel
    }()

    private lazy var tipDescriptionLabel: UILabel = {
        let tipDescriptionLabel = UILabel()
        tipDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        tipDescriptionLabel.adjustsFontForContentSizeCategory = true
        tipDescriptionLabel.textColor = .secondaryLabel
        tipDescriptionLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        tipDescriptionLabel.text = TextContent.tipPanelDescription
        tipDescriptionLabel.numberOfLines = 0
        return tipDescriptionLabel
    }()

    private lazy var bottomTipPanel: UIView = {
        let view = UIView()
        view.backgroundColor = .quaternaryBackground
        view.layer.cornerRadius = Metrics.tipPanelCornerRadius
        view.addSubview(tipStackView)

        return view
    }()

    private lazy var tipStackView: UIStackView = {
        let tipStackView = UIStackView(arrangedSubviews: [trophy, tipLabelsStackView])
        tipStackView.spacing = Metrics.tipPanelHorizontalStackSpacing
        tipStackView.translatesAutoresizingMaskIntoConstraints = false
        tipStackView.axis = .horizontal
        tipStackView.alignment = .top
        return tipStackView
    }()

    private lazy var tipLabelsStackView: UIStackView = {
        let tipLabelsStackView = UIStackView(arrangedSubviews: [tipLabel, tipDescriptionLabel])
        tipLabelsStackView.translatesAutoresizingMaskIntoConstraints = false
        tipLabelsStackView.axis = .vertical
        tipLabelsStackView.alignment = .leading
        tipLabelsStackView.addArrangedSubviews([tipLabel, tipDescriptionLabel])
        return tipLabelsStackView
    }()

    private lazy var timeSelectionToTipSpacer: UIView = {
        makeSpacer()
    }()

    private lazy var tipToConfirmationButtonSpacer: UIView = {
        makeSpacer()
    }()

    private lazy var confirmationButtonBottomSpacer: UIView = {
        makeSpacer()
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
    private var scheduledTime: Date
    private weak var delegate: BloggingRemindersFlowDelegate?

    init(
        for blog: Blog,
        tracker: BloggingRemindersTracker,
        calendar: Calendar? = nil,
        delegate: BloggingRemindersFlowDelegate? = nil) throws {

        self.blog = blog
        self.tracker = tracker
        self.calendar = calendar ?? {
            var calendar = Calendar.current
            calendar.locale = Locale.autoupdatingCurrent

            return calendar
        }()
        self.delegate = delegate

        scheduler = try BloggingRemindersScheduler()

        switch self.scheduler.schedule(for: blog) {
        case .none:
            previousWeekdays = []
        case .weekdays(let scheduledWeekdays):
            previousWeekdays = scheduledWeekdays
        }

        weekdays = previousWeekdays

        scheduledTime = scheduler.scheduledTime(for: blog)

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
        populateCalendarDays()
        refreshNextButton()
        refreshFrequencyLabel()

        showFullUI(shouldShowFullUI)
    }

    override func viewDidAppear(_ animated: Bool) {
        tracker.screenShown(.dayPicker)

        super.viewDidAppear(animated)
        calculatePreferredContentSize()
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

        bottomTipPanel.isHidden = traitCollection.preferredContentSizeCategory.isAccessibilityCategory || !shouldShowFullUI
        imageView.isHidden = traitCollection.preferredContentSizeCategory.isAccessibilityCategory || !shouldShowFullUI
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        showFullUI(shouldShowFullUI)
        calculatePreferredContentSize()
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

        scheduler.schedule(schedule, for: blog, time: scheduledTime) { [weak self] result in
            guard let self = self else {
                return
            }

            switch result {
            case .success:
                self.tracker.scheduled(schedule, time: self.scheduledTime)

                DispatchQueue.main.async { [weak self] in
                    self?.delegate?.didSetUpBloggingReminders()
                    self?.pushCompletionViewController()
                }
            case .failure(let error):
                switch error {
                case BloggingRemindersScheduler.Error.needsPermissionForPushNotifications where showPushPrompt == true:
                    DispatchQueue.main.async { [weak self] in
                        self?.pushPushPromptViewController()
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
}

// MARK: - Navigation
private extension BloggingRemindersFlowSettingsViewController {

    func pushTimeSelectionViewController() {
        let viewController = TimeSelectionViewController(scheduledTime: scheduler.scheduledTime(for: blog),
                                                         tracker: tracker) { [weak self] date in
            self?.scheduledTime = date
            self?.timeSelectionButton.setSelectedTime(date.toLocalTime())
            self?.refreshNextButton()
            self?.refreshFrequencyLabel()
        }
        viewController.preferredWidth = self.view.frame.width
        navigationController?.pushViewController(viewController, animated: true)
    }

    func pushCompletionViewController() {
        let viewController = BloggingRemindersFlowCompletionViewController(blog: blog, tracker: tracker, calendar: calendar)
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func pushPushPromptViewController() {
        let viewController = BloggingRemindersPushPromptViewController(tracker: tracker) { [weak self] in
            self?.scheduleReminders(showPushPrompt: false)
        }
        navigationController?.pushViewController(viewController, animated: true)
    }
}

// MARK: - Private Helpers
private extension BloggingRemindersFlowSettingsViewController {

    /// creates an instance of a UIView with a grey background, intended to be used as a divider
    func makeDivider() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.divider
        return view
    }

    /// instantiates a UIView with transparent background, intented to be used as a spacer in a UIStackView
    func makeSpacer() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }

    /// Determines if the calendar image and the tip should be displayed, depending on the screen vertical size
    var shouldShowFullUI: Bool {
        (WPDeviceIdentification.isiPhone() && UIScreen.main.bounds.height >= Metrics.minimumHeightForFullUI) ||
            (WPDeviceIdentification.isiPad() && UIDevice.current.orientation.isPortrait)
    }

    /// Hides/shows the optional UI Elements (dismiss button, calendar icon, tip)
    /// - Parameter isVisible: true if we need to show the elements (Full UI), false otherwise
    func showFullUI(_ isVisible: Bool) {
        bottomTipPanel.isHidden = !isVisible
        imageView.isHidden = !isVisible
    }

    /// Updates the title of the cconfirmation button depending on the action (new schedule or updated schedule)
    func refreshNextButton() {
        if previousWeekdays.isEmpty {
            button.setTitle(TextContent.nextButtonTitle, for: .normal)
            button.isEnabled = !weekdays.isEmpty
        } else if (weekdays == previousWeekdays) && (scheduledTime == scheduler.scheduledTime(for: blog)) {
            button.setTitle(TextContent.nextButtonTitle, for: .normal)
            button.isEnabled = true
        } else {
            button.setTitle(TextContent.updateButtonTitle, for: .normal)
            button.isEnabled = true
        }
    }

    /// Updates the label that contains the number of scheduled days as users change them
    func refreshFrequencyLabel() {
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

        let frequencyDescription = scheduleFormatter.shortScheduleDescription(for: .weekdays(weekdays))
        let attributedText = NSMutableAttributedString(attributedString: frequencyDescription)
        attributedText.addAttributes(defaultAttributes, range: NSRange(location: 0, length: attributedText.length))

        frequencyLabel.attributedText = attributedText
        frequencyLabel.sizeToFit()
    }

    func calculatePreferredContentSize() {
        let size = CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        preferredContentSize = view.systemLayoutSizeFitting(size)
    }

    func configureStackView() {
        view.addSubview(stackView)

        stackView.addArrangedSubviews([
            imageView,
            titleLabel,
            promptLabel,
            daysOuterStackView,
            frequencyView,
            timeSelectionView,
            timeSelectionToTipSpacer,
            bottomTipPanel,
            tipToConfirmationButtonSpacer,
            button,
            confirmationButtonBottomSpacer
        ])

        stackView.setCustomSpacing(Metrics.afterTitleLabelSpacing, after: titleLabel)
        stackView.setCustomSpacing(Metrics.afterPromptLabelSpacing, after: promptLabel)
    }

    func configureConstraints() {
        frequencyView.pinSubviewToAllEdges(frequencyLabel)
        timeSelectionView.pinSubviewToAllEdges(timeSelectionStackView)
        bottomTipPanel.pinSubviewToAllEdges(tipStackView, insets: Metrics.tipPanelMargins)

        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        tipDescriptionLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        timeSelectionView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        button.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Metrics.edgeMargins.left),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Metrics.edgeMargins.right),
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: Metrics.edgeMargins.top),
            stackView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor, constant: WPDeviceIdentification.isiPad() ? .zero : -Metrics.edgeMargins.bottom),

            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),

            button.heightAnchor.constraint(equalToConstant: Metrics.buttonHeight),
            button.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            bottomTipPanel.widthAnchor.constraint(equalTo: stackView.widthAnchor),

            topDivider.heightAnchor.constraint(equalToConstant: .hairlineBorderWidth),
            bottomDivider.heightAnchor.constraint(equalToConstant: .hairlineBorderWidth),
            timeSelectionView.heightAnchor.constraint(equalToConstant: Metrics.buttonHeight),
            timeSelectionView.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            frequencyView.heightAnchor.constraint(equalToConstant: Metrics.frequencyLabelHeight),
            tipLabel.heightAnchor.constraint(equalTo: trophy.heightAnchor),
            timeSelectionToTipSpacer.heightAnchor.constraint(equalTo: tipToConfirmationButtonSpacer.heightAnchor),
            timeSelectionToTipSpacer.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            tipToConfirmationButtonSpacer.widthAnchor.constraint(equalTo: stackView.widthAnchor)
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

    /// Adds the calendar days to the UI according to the device locale
    func populateCalendarDays() {
        daysOuterStackView.addArrangedSubviews([daysTopInnerStackView, daysBottomInnerStackView])

        let topRow = 0 ..< Metrics.topRowDayCount
        let bottomRow = Metrics.topRowDayCount ..< calendar.shortWeekdaySymbols.count

        daysTopInnerStackView.addArrangedSubviews(topRow.compactMap({ createCalendarDayToggleButton(localizedWeekdayDayIndex: $0) }))
        daysBottomInnerStackView.addArrangedSubviews(bottomRow.compactMap({ createCalendarDayToggleButton(localizedWeekdayDayIndex: $0) }))
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

// MARK: - Constants
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
    static let tipDescriptionHeight: CGFloat = 34.0
    static let frequencyLabelHeight: CGFloat = 30

    static let topRowDayCount = 4

    // the smallest logical iPhone height (iPhone 12 mini) to display the full UI, which includes calendar icon and tip.
    static let minimumHeightForFullUI: CGFloat = 812
}
