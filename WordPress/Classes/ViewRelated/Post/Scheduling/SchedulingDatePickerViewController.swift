import Foundation
import Gridicons
import UIKit

struct SchedulingDatePickerConfiguration {
    var date: Date?
    var timeZone: TimeZone
    var dateFormatter: DateFormatter
    var dateTimeFormatter: DateFormatter
    var updated: (Date?) -> Void
}

final class SchedulingDatePickerViewController: UIViewController {
    var configuration: SchedulingDatePickerConfiguration?

    private lazy var datePickerView: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.preferredDatePickerStyle = .inline
        datePicker.calendar = Calendar.current
        if let timeZone = configuration?.timeZone {
            datePicker.timeZone = timeZone
        }
        datePicker.date = configuration?.date ?? Date()
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        datePicker.addTarget(self, action: #selector(datePickerValueChanged(sender:)), for: .valueChanged)
        datePicker.tintColor = UIColor.primary
        return datePicker
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Strings.title

        datePickerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(datePickerView)
        NSLayoutConstraint.activate([
            datePickerView.topAnchor.constraint(equalTo: view.topAnchor),
            datePickerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            datePickerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        view.backgroundColor = .systemBackground

        updateNavigationItems()
    }

    @objc private func buttonNowTapped() {
        setDate(nil)
        navigationController?.popViewController(animated: true)
    }

    @objc private func datePickerValueChanged(sender: UIDatePicker) {
        setDate(sender.date)
    }

    private func setDate(_ date: Date?) {
        configuration?.date = date
        configuration?.updated(date)
        updateNavigationItems()
    }

    private func updateNavigationItems() {
        if configuration?.date != nil {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: Strings.now, style: .plain, target: self, action: #selector(buttonNowTapped))
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }
}

extension SchedulingDatePickerViewController {
    static func make(viewModel: PublishSettingsViewModel, onDateUpdated: @escaping (Date?) -> Void) -> SchedulingDatePickerViewController {
        let viewController = SchedulingDatePickerViewController()
        viewController.configuration = SchedulingDatePickerConfiguration(
            date: viewModel.date,
            timeZone: viewModel.timeZone,
            dateFormatter: viewModel.dateFormatter,
            dateTimeFormatter: viewModel.dateTimeFormatter,
            updated: onDateUpdated
        )
        return viewController
    }
}

private enum Strings {
    static let title = NSLocalizedString("publishDatePicker.title", value: "Publish Date", comment: "Post publish date picker")
    static let now = NSLocalizedString("publishDatePicker.now", value: "Now", comment: "The Now button that clears the date selection")
}
