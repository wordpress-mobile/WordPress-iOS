import Foundation
import Gridicons

protocol DateCoordinatorHandler: AnyObject {
    var coordinator: DateCoordinator? { get set }
}

class DateCoordinator {

    var date: Date?
    let timeZone: TimeZone
    let dateFormatter: DateFormatter
    let dateTimeFormatter: DateFormatter
    let updated: (Date?) -> Void

    init(date: Date?, timeZone: TimeZone, dateFormatter: DateFormatter, dateTimeFormatter: DateFormatter, updated: @escaping (Date?) -> Void) {
        self.date = date
        self.timeZone = timeZone
        self.dateFormatter = dateFormatter
        self.dateTimeFormatter = dateTimeFormatter
        self.updated = updated
    }
}

// MARK: - Date Picker

class SchedulingCalendarViewController: UIViewController, DatePickerSheet, DateCoordinatorHandler {

    var coordinator: DateCoordinator? = nil

    let chosenValueRow = ChosenValueRow(frame: .zero)

    lazy var calendarMonthView: CalendarMonthView = {
        var calendar = Calendar.current
        if let timeZone = coordinator?.timeZone {
            calendar.timeZone = timeZone
        }
        let calendarMonthView = CalendarMonthView(calendar: calendar)
        calendarMonthView.translatesAutoresizingMaskIntoConstraints = false

        let selectedDate = coordinator?.date ?? Date()
        calendarMonthView.selectedDate = selectedDate
        calendarMonthView.updated = { [weak self] date in
            var newDate = date

            // Since the date from the calendar will not include hours and minutes, replace with the original date (either the current, or previously entered date)
            var calendar = Calendar.current
            if let timeZone = self?.coordinator?.timeZone {
                calendar.timeZone = timeZone
            }
            let selectedComponents = calendar.dateComponents([.hour, .minute], from: selectedDate)
            newDate = calendar.date(bySettingHour: selectedComponents.hour ?? 0, minute: selectedComponents.minute ?? 0, second: 0, of: newDate) ?? newDate

            self?.coordinator?.date = newDate
            self?.chosenValueRow.detailLabel.text = self?.coordinator?.dateFormatter.string(from: date)
        }

        return calendarMonthView
    }()

    private lazy var closeButton: UIBarButtonItem = {
        let item = UIBarButtonItem(image: .gridicon(.cross),
                                   style: .plain,
                                   target: self,
                                   action: #selector(closeButtonPressed))
        item.accessibilityLabel = NSLocalizedString("Close", comment: "Accessibility label for the date picker's close button.")
        return item
    }()
    private lazy var publishButton = UIBarButtonItem(title: NSLocalizedString("Publish immediately", comment: "Immediately publish button title"), style: .plain, target: self, action: #selector(SchedulingCalendarViewController.publishImmediately))

    override func viewDidLoad() {
        super.viewDidLoad()

        chosenValueRow.titleLabel.text = NSLocalizedString("Choose a date", comment: "Label for Publish date picker")

        let nextButton = UIBarButtonItem(title: NSLocalizedString("Next", comment: "Next screen button title"), style: .plain, target: self, action: #selector(nextButtonPressed))
        navigationItem.setRightBarButton(nextButton, animated: false)

        setup(topView: chosenValueRow, pickerView: calendarMonthView)

        calendarMonthView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        calendarMonthView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        calendarMonthView.setContentHuggingPriority(.defaultHigh, for: .vertical)

        setupForAccessibility()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        calculatePreferredSize()
    }

    private func calculatePreferredSize() {
        let targetSize = CGSize(width: view.bounds.width,
          height: UIView.layoutFittingCompressedSize.height)
        preferredContentSize = view.systemLayoutSizeFitting(targetSize)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        (segue.destination as? DateCoordinatorHandler)?.coordinator = coordinator
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        resetNavigationButtons()
    }

    @objc func closeButtonPressed() {
        dismiss(animated: true, completion: nil)
    }

    override func accessibilityPerformEscape() -> Bool {
        dismiss(animated: true, completion: nil)
        return true
    }

    @objc func publishImmediately() {
        coordinator?.updated(nil)
        navigationController?.dismiss(animated: true, completion: nil)
    }

    @objc func nextButtonPressed() {
        let vc = TimePickerViewController()
        vc.coordinator = coordinator
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func resetNavigationButtons() {
        let includeCloseButton = traitCollection.verticalSizeClass == .compact ||
            (isVoiceOverOrSwitchControlRunning && navigationController?.modalPresentationStyle != .popover)

        if includeCloseButton {
            navigationItem.leftBarButtonItems = [closeButton, publishButton]
        } else {
            navigationItem.leftBarButtonItems = [publishButton]
        }
    }
}

// MARK: Accessibility

private extension SchedulingCalendarViewController {
    func setupForAccessibility() {
        let notificationNames = [
            UIAccessibility.voiceOverStatusDidChangeNotification,
            UIAccessibility.switchControlStatusDidChangeNotification
        ]
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(resetNavigationButtons),
                                               names: notificationNames,
                                               object: nil)
    }

    var isVoiceOverOrSwitchControlRunning: Bool {
        UIAccessibility.isVoiceOverRunning || UIAccessibility.isSwitchControlRunning
    }
}

// MARK: - Time Picker

class TimePickerViewController: UIViewController, DatePickerSheet, DateCoordinatorHandler {

    var coordinator: DateCoordinator? = nil

    let chosenValueRow = ChosenValueRow(frame: .zero)

    private lazy var datePicker: UIDatePicker = {
        let datePicker = UIDatePicker()

        if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }

        datePicker.datePickerMode = .time
        datePicker.timeZone = coordinator?.timeZone
        datePicker.addTarget(self, action: #selector(timePickerChanged(_:)), for: .valueChanged)
        if let date = coordinator?.date {
            datePicker.date = date
        }
        return datePicker
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        chosenValueRow.titleLabel.text = NSLocalizedString("Choose a time", comment: "Label for Publish time picker")
        chosenValueRow.detailLabel.text = coordinator?.dateTimeFormatter.string(from: datePicker.date)
        let doneButton = UIBarButtonItem(title: NSLocalizedString("Done", comment: "Label for Done button"), style: .done, target: self, action: #selector(done))

        setup(topView: chosenValueRow, pickerView: datePicker)

        navigationItem.setRightBarButton(doneButton, animated: false)
    }

    // MARK: Change Selectors
    @objc func timePickerChanged(_ sender: Any) {
        chosenValueRow.detailLabel.text = coordinator?.dateTimeFormatter.string(from: datePicker.date)
        coordinator?.date = datePicker.date
    }

    @objc func done() {
        coordinator?.updated(coordinator?.date)
        navigationController?.dismiss(animated: true, completion: nil)
    }
}

// MARK: DatePickerSheet Protocol
protocol DatePickerSheet {
    func configureStackView(topView: UIView, pickerView: UIView) -> UIView
}

extension DatePickerSheet {

    /// Constructs a view with `topView` on top and `pickerView` on bottom
    /// - Parameter topView: A view to be shown above `pickerView`
    /// - Parameter pickerView: A view to be shown on the bottom
    func configureStackView(topView: UIView, pickerView: UIView) -> UIView {
        pickerView.translatesAutoresizingMaskIntoConstraints = false

        let pickerWrapperView = UIView()
        pickerWrapperView.addSubview(pickerView)

        let sideConstraints: [NSLayoutConstraint] = [
            pickerView.leftAnchor.constraint(equalTo: pickerWrapperView.leftAnchor),
            pickerView.rightAnchor.constraint(equalTo: pickerWrapperView.rightAnchor)
        ]

        // Allow these to break on larger screen sizes and just center the content
        sideConstraints.forEach() { constraint in
            constraint.priority = .defaultHigh
        }

        NSLayoutConstraint.activate([
            pickerView.centerXAnchor.constraint(equalTo: pickerWrapperView.safeCenterXAnchor),
            pickerView.topAnchor.constraint(equalTo: pickerWrapperView.topAnchor),
            pickerView.bottomAnchor.constraint(equalTo: pickerWrapperView.bottomAnchor)
        ])

        NSLayoutConstraint.activate(sideConstraints)

        let stackView = UIStackView(arrangedSubviews: [
            topView,
            pickerWrapperView
        ])
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false

        return stackView
    }
}

extension DatePickerSheet where Self: UIViewController {

    /// Adds `topView` and `pickerView` to view hierarchy + standard styling for the view controller's view
    /// - Parameter topView: A view to show above `pickerView` (see `ChosenValueRow`)
    /// - Parameter pickerView: A view to show below the top view
    func setup(topView: UIView, pickerView: UIView) {
        WPStyleGuide.configureColors(view: view, tableView: nil)

        let stackView = configureStackView(topView: topView, pickerView: pickerView)

        view.addSubview(stackView)
        view.pinSubviewToSafeArea(stackView)
    }
}
