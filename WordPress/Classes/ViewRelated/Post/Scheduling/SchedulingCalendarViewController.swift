import Foundation
import Gridicons

protocol DateCoordinatorHandler: class {
    var coordinator: DateCoordinator? { get set }
}

struct DateCoordinator {
    var date: Date?
    var updated: (Date?) -> Void

    mutating func setDate(_ newDate: Date) {
        date = newDate
    }
}

class SchedulingCalendarViewController: DatePickerSheet, DateCoordinatorHandler {

    private let calendarMonthView = CalendarMonthView(frame: .zero)

    private let closeButton = UIBarButtonItem(image: Gridicon.iconOfType(.cross), style: .plain, target: self, action: #selector(closeButtonPressed))
    private let publishButton = UIBarButtonItem(title: NSLocalizedString("Publish immediately", comment: "Immediately publish button title"), style: .plain, target: self, action: #selector(publishImmediately))

    override func makePickerView() -> UIView {
        calendarMonthView.translatesAutoresizingMaskIntoConstraints = false

        let selectedDate = coordinator?.date ?? Date()
        calendarMonthView.selectedDate = selectedDate
        calendarMonthView.updated = { [weak self] date in
            var newDate = date

            // If we have an existing time value, we want to set it to the calendar's selected date (which starts at midnight)
            if let existingDate = self?.coordinator?.date {
                let components = Calendar.current.dateComponents([.hour, .minute], from: existingDate)
                newDate = Calendar.current.date(bySettingHour: components.hour ?? 0, minute: components.minute ?? 0, second: components.second ?? 0, of: newDate) ?? newDate
            }
            self?.coordinator?.setDate(newDate)
            self?.chosenValueRow.detailLabel.text = date.longString()
        }

        return calendarMonthView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        chosenValueRow.titleLabel.text = NSLocalizedString("Choose a date", comment: "Label for Publish date picker")

        let nextButton = UIBarButtonItem(title: NSLocalizedString("Next", comment: "Next screen button title"), style: .plain, target: self, action: #selector(nextButtonPressed))
        navigationItem.setRightBarButton(nextButton, animated: false)

        calendarMonthView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        calendarMonthView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        calendarMonthView.setContentHuggingPriority(.defaultHigh, for: .vertical)
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

        navigationItem.setLeftBarButton(publishButton, animated: false)

        if traitCollection.verticalSizeClass == .compact {
            navigationItem.leftBarButtonItems = [closeButton, publishButton]
        } else {
            navigationItem.leftBarButtonItems = [publishButton]
        }
    }

    @objc func closeButtonPressed() {
        dismiss(animated: true, completion: nil)
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
}

class TimePickerViewController: DatePickerSheet, DateCoordinatorHandler {

    weak var datePicker: UIDatePicker!

    override func makePickerView() -> UIView {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .time
        datePicker.addTarget(self, action: #selector(timePickerChanged(_:)), for: .valueChanged)
        if let date = coordinator?.date {
            datePicker.date = date
        }
        self.datePicker = datePicker
        return datePicker
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        chosenValueRow.titleLabel.text = NSLocalizedString("Choose a time", comment: "Label for Publish time picker")
        chosenValueRow.detailLabel.text = datePicker.date.longStringWithTime()
        let doneButton = UIBarButtonItem(title: NSLocalizedString("Done", comment: "Label for Done button"), style: .done, target: self, action: #selector(done))
        navigationItem.setRightBarButton(doneButton, animated: false)
    }

    // MARK: Change Selectors
    @objc func timePickerChanged(_ sender: Any) {
        chosenValueRow.detailLabel.text = datePicker.date.longStringWithTime()
        coordinator?.setDate(datePicker.date)
    }

    @objc func done() {
        coordinator?.updated(coordinator?.date)
        navigationController?.dismiss(animated: true, completion: nil)
    }
}

/// A base class used by the date picker classes
/// Could be genericized further
class DatePickerSheet: UIViewController {
    var coordinator: DateCoordinator? = nil

    let chosenValueRow = ChosenValueRow(frame: .zero)
    weak var pickerView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }

    private func setup() {
        WPStyleGuide.configureColors(view: view, tableView: nil)

        let pickerView = makePickerView()
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
            chosenValueRow,
            pickerWrapperView
        ])
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false

        self.pickerView = pickerView

        view.addSubview(stackView)
        view.pinSubviewToSafeArea(stackView)

    }

    // Does nothing, should be overriden by the subclass
    func makePickerView() -> UIView {
        return UIView()
    }

}
