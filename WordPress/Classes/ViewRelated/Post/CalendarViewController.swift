import Foundation

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

class CalendarViewController: DatePickerSheet, DateCoordinatorHandler {

    @IBOutlet weak var calendarMonthView: CalendarMonthView!

    private static var dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .long
        return df
    }()

    override func configureView() -> UIView {
        let calendarMonthView = CalendarMonthView(frame: .zero)
        calendarMonthView.translatesAutoresizingMaskIntoConstraints = false

        let selectedDate = coordinator?.date ?? Date()
        calendarMonthView.selectedDate = selectedDate
        calendarMonthView.updated = { [weak self] date in
            var newDate = date

            // If we have an existing time value, we want to add it to the calendar's selected date (which starts at midnight)
            if let existingDate = self?.coordinator?.date {
                let components = Calendar.current.dateComponents([.hour, .minute], from: existingDate)
                newDate = Calendar.current.date(byAdding: components, to: newDate, wrappingComponents: false) ?? newDate
            }
            self?.coordinator?.setDate(newDate)
            self?.chosenValueRow.detailLabel?.text = CalendarViewController.dateFormatter.string(from: date)
        }

        return calendarMonthView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        chosenValueRow.titleLabel?.text = NSLocalizedString("Choose a date", comment: "Label for Publish date picker")

        let publishButton = UIBarButtonItem(title: NSLocalizedString("Publish immediately", comment: "Immediately publish button title"), style: .plain, target: self, action: #selector(publishImmediately))
        navigationItem.setLeftBarButton(publishButton, animated: false)

        let nextButton = UIBarButtonItem(title: NSLocalizedString("Next", comment: "Next screen button title"), style: .plain, target: self, action: #selector(nextButtonPressed))
        navigationItem.setRightBarButton(nextButton, animated: false)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        (segue.destination as? DateCoordinatorHandler)?.coordinator = coordinator
    }

    @IBAction func publishImmediately() {
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

    static var dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .long
        df.timeStyle = .short
        return df
    }()

    @IBOutlet weak var datePicker: UIDatePicker!

    override func configureView() -> UIView {
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
        chosenValueRow.titleLabel?.text = NSLocalizedString("Choose a time", comment: "Label for Publish time picker")
        chosenValueRow.detailLabel?.text = TimePickerViewController.dateFormatter.string(from: datePicker.date)
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(done))
        navigationItem.setRightBarButton(doneButton, animated: false)
    }

    @IBAction func timePickerChanged(_ sender: Any) {
        chosenValueRow.detailLabel?.text = TimePickerViewController.dateFormatter.string(from: datePicker.date)
        coordinator?.setDate(datePicker.date)
    }

    @IBAction func done() {
        coordinator?.updated(coordinator?.date)
        navigationController?.dismiss(animated: true, completion: nil)
    }
}

/// A base class used by the date picker classes
/// Could be genericized further
class DatePickerSheet: UIViewController {
    var coordinator: DateCoordinator? = nil

    weak var chosenValueRow: ChosenValueRow!
    weak var pickerView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()

        WPStyleGuide.configureColors(view: view, tableView: nil)

        let chosenValueRow = configureValueRow()
        let pickerView = configureView()

        let stackView = UIStackView(arrangedSubviews: [
            chosenValueRow,
            pickerView
        ])
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false

        self.chosenValueRow = chosenValueRow
        self.pickerView = pickerView

        view.addSubview(stackView)
        view.pinSubviewToAllEdges(stackView)
    }

    // Does nothing, should be overriden by the subclass
    func configureView() -> UIView {
        return UIView()
    }

    private func configureValueRow() -> ChosenValueRow {
        let chosenRow = ChosenValueRow(frame: .zero)
        return chosenRow
    }

}
