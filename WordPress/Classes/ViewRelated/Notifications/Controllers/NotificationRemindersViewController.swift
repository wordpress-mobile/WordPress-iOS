import UIKit
import UserNotifications

struct ReminderRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(WPTableViewCellSubtitle.self)

    let title: String
    let value: String
    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = value
        cell.selectionStyle = .none

        WPStyleGuide.configureTableViewCell(cell)
    }
}

/// Presents a list of any pending notification reminders, with the ability
/// to cancel individual or all reminders.
///
class NotificationRemindersViewController: UITableViewController {
    private let helper = NotificationRemindersHelper()

    private lazy var handler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self)
    }()

    private lazy var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    /// Notification reminder requests displayed in the table.
    private var requests: [UNNotificationRequest] = []

    init() {
        super.init(style: .grouped)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = NSLocalizedString("Notification Reminders", comment: "Title for screen showing pending reminders set for notifications")
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                           target: self,
                                                           action: #selector(cancel))

        ImmuTable.registerRows([ReminderRow.self, DestructiveButtonRow.self], tableView: tableView)

        WPStyleGuide.configureColors(for: nil, andTableView: tableView)

        reloadModel()
    }

    @objc private func cancel() {
        dismiss(animated: true, completion: nil)
    }

    // MARK: Model and table loading

    private func reloadModel() {
        let helper = NotificationRemindersHelper()
        helper.getPendingReminders({ requests in
            DispatchQueue.main.async { [weak self] in
                self?.requests = requests
                self?.reloadTable()
            }
        })
    }

    private func reloadTable() {
        let headerText = NSLocalizedString("Swipe to cancel a reminder", comment: "Instruction to user to swipe a table row to cancel the associated reminder")
        let rows: [ReminderRow] = requests.map(row(for:))
        let remindersSection = ImmuTableSection(headerText: headerText, rows: rows)

        let title = NSLocalizedString("Cancel All Reminders", comment: "Title of button to cancel all reminders set by the user")
        let cancelRow = DestructiveButtonRow(title: title, action: { [weak self] _ in
            // TODO: Show confirmation
            self?.helper.cancelAllReminders()
            self?.reloadModel()
            }, accessibilityIdentifier: "cancel reminders row")
        let cancelAllSection = ImmuTableSection(rows: [cancelRow])

        let hasReminders = requests.count > 0
        let sections = hasReminders ? [remindersSection, cancelAllSection] : []

        handler.viewModel = ImmuTable(sections: sections)
    }

    private func row(for request: UNNotificationRequest) -> ReminderRow {
        let title = helper.reminderTitle(for: request)

        let value: String
        if let date = helper.reminderTriggerDate(for: request) {
            let formatString = NSLocalizedString("Reminder at %@", comment: "Label informing the user of the date and time a reminder is set for.")
            value = String(format: formatString, formatter.string(from: date))
        } else {
            value = ""
        }

        return ReminderRow(title: title, value: value)
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let title = NSLocalizedString("Cancel Reminder", comment: "Button to cancel a reminder that the user has set")
        let request = requests[indexPath.row]

        return [UITableViewRowAction(style: .destructive,
                                     title: title,
                                     handler: { [weak self] (action, indexpath) in
            self?.helper.cancelReminder(request)
            self?.reloadModel()
        })]
    }
}
