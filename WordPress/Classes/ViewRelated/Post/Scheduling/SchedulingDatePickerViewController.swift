import Foundation
import Gridicons
import UIKit

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

class SchedulingDatePickerViewController: UIViewController, DatePickerSheet, DateCoordinatorHandler {

    var coordinator: DateCoordinator? = nil

    let chosenValueRow = ChosenValueRow(frame: .zero)

    lazy var datePickerView: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.preferredDatePickerStyle = .inline
        datePicker.calendar = Calendar.current
        if let timeZone = coordinator?.timeZone {
            datePicker.timeZone = timeZone
        }
        datePicker.date = coordinator?.date ?? Date()
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        datePicker.addTarget(self, action: #selector(datePickerValueChanged(sender:)), for: .valueChanged)

        return datePicker
    }()

    @objc private func datePickerValueChanged(sender: UIDatePicker) {
        let date = sender.date
        coordinator?.date = date
        chosenValueRow.detailLabel.text = coordinator?.dateFormatter.string(from: date)
    }

    private lazy var closeButton: UIBarButtonItem = {
        let item = UIBarButtonItem(image: .gridicon(.cross),
                                   style: .plain,
                                   target: self,
                                   action: #selector(closeButtonPressed))
        item.accessibilityLabel = NSLocalizedString("Close", comment: "Accessibility label for the date picker's close button.")
        return item
    }()

    private lazy var publishButton = UIBarButtonItem(title: NSLocalizedString("Publish immediately", comment: "Immediately publish button title"), style: .plain, target: self, action: #selector(SchedulingDatePickerViewController.publishImmediately))

    override func viewDidLoad() {
        super.viewDidLoad()

        chosenValueRow.titleLabel.text = NSLocalizedString("Choose a date", comment: "Label for Publish date picker")

        let doneButton = UIBarButtonItem(title: NSLocalizedString("Done", comment: "Label for Done button"), style: .done, target: self, action: #selector(done))

        navigationItem.setRightBarButton(doneButton, animated: false)

        setup(topView: chosenValueRow, pickerView: datePickerView)
        view.tintColor = .editorPrimary

        setupForAccessibility()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        preferredContentSize = calculatePreferredSize()
    }

    private func calculatePreferredSize() -> CGSize {
        let targetSize = CGSize(width: view.bounds.width,
          height: UIView.layoutFittingCompressedSize.height)
        return view.systemLayoutSizeFitting(targetSize)
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

    @objc func done() {
        coordinator?.updated(coordinator?.date)
        navigationController?.dismiss(animated: true, completion: nil)
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

private extension SchedulingDatePickerViewController {
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
