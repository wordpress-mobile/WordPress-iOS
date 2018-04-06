import UIKit

class SupportTableViewController: UITableViewController {

    // MARK: - Properties

    var sourceTag: SupportSourceTag?
    private var tableHandler: ImmuTableViewHandler!
    private let userDefaults = UserDefaults.standard

    // MARK: - Init

    override init(style: UITableViewStyle) {
        super.init(style: style)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required convenience init() {
        self.init(style: .grouped)
    }

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
        setupTable()
    }

    // MARK: - Button Actions

    @IBAction func dismissPressed(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }

}

// MARK: - Private Extension

private extension SupportTableViewController {
    func setupNavBar() {
        title = LocalizedText.viewTitle

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: LocalizedText.closeButton,
                                                           style: WPStyleGuide.barButtonStyleForBordered(),
                                                           target: self,
                                                           action: #selector(SupportTableViewController.dismissPressed(_:)))
    }

    func setupTable() {
        ImmuTable.registerRows([SwitchRow.self,
                                NavigationItemRow.self,
                                TextRow.self,
                                HelpRow.self],
                               tableView: tableView)
        tableHandler = ImmuTableViewHandler(takeOver: self)
        tableHandler.viewModel = tableViewModel()
        WPStyleGuide.configureColors(for: view, andTableView: tableView)
        // remove empty cells
        tableView.tableFooterView = UIView()
    }

    // MARK: - Table Model

    func tableViewModel() -> ImmuTable {

        // Help Section
        let helpCenterRow = HelpRow(title: LocalizedText.wpHelpCenter, action: helpCenterSelected())
        let contactRow = HelpRow(title: LocalizedText.contactUs, action: contactUsSelected())
        let ticketsRow = HelpRow(title: LocalizedText.myTickets, action: myTicketsSelected())

        let helpSection = ImmuTableSection(
            headerText: nil,
            rows: [helpCenterRow, contactRow, ticketsRow],
            footerText: LocalizedText.helpFooter)

        // Information Section
        let versionRow = TextRow(title: LocalizedText.version, value: Bundle.main.shortVersionString())
        let switchRow = SwitchRow(title: LocalizedText.extraDebug,
                                  value: userDefaults.bool(forKey: UserDefaultsKeys.extraDebug),
                                  onChange: extraDebugToggled())
        let logsRow = NavigationItemRow(title: LocalizedText.activityLogs, action: activityLogsSelected())

        let informationSection = ImmuTableSection(
            headerText: nil,
            rows: [versionRow, switchRow, logsRow],
            footerText: LocalizedText.informationFooter)

        // Create and return table
        return ImmuTable(sections: [helpSection, informationSection])
    }

    // MARK: - Row Handlers

    func helpCenterSelected() -> ImmuTableAction {
        return { [unowned self] row in
            self.showAlert()
        }
    }

    func contactUsSelected() -> ImmuTableAction {
        return { [unowned self] row in
            self.showAlert()
        }
    }

    func myTicketsSelected() -> ImmuTableAction {
        return { [unowned self] row in
            self.showAlert()
        }
    }

    func extraDebugToggled() -> (_ newValue: Bool) -> Void {
        return { [unowned self] newValue in
            self.userDefaults.set(newValue, forKey: UserDefaultsKeys.extraDebug)
            self.userDefaults.synchronize()
            WPLogger.configureLoggerLevelWithExtraDebug()
        }
    }

    func activityLogsSelected() -> ImmuTableAction {
        return { [unowned self] row in
            let activityLogViewController = ActivityLogViewController()
            self.navigationController?.pushViewController(activityLogViewController, animated: true)
        }
    }

    func showAlert() {
        tableView.deselectSelectedRowWithAnimation(true)
        let message = "This is a work in progress. If you need to create a ticket, disable the zendeskMobile feature flag."
        let alertController = UIAlertController(title: nil,
                                                message: message,
                                                preferredStyle: .alert)
        alertController.addDefaultActionWithTitle("OK")
        present(alertController, animated: true, completion: nil)
    }

    // MARK: - ImmuTableRow Struct

    struct HelpRow: ImmuTableRow {
        static let cell = ImmuTableCell.class(WPTableViewCellValue1.self)

        let title: String
        let action: ImmuTableAction?

        init(title: String, action: @escaping ImmuTableAction) {
            self.title = title
            self.action = action
        }

        func configureCell(_ cell: UITableViewCell) {
            cell.textLabel?.text = title
            WPStyleGuide.configureTableViewCell(cell)
            cell.textLabel?.textColor = WPStyleGuide.wordPressBlue()
        }
    }

    // MARK: - Localized Text

    struct LocalizedText {
        static let viewTitle = NSLocalizedString("Support", comment: "View title for Support page.")
        static let closeButton = NSLocalizedString("Close", comment: "Dismiss the current view")
        static let wpHelpCenter = NSLocalizedString("WordPress Help Center", comment: "Option in Support view to launch the Help Center.")
        static let contactUs = NSLocalizedString("Contact Us", comment: "Option in Support view to contact the support team.")
        static let myTickets = NSLocalizedString("My Tickets", comment: "Option in Support view to access previous help tickets.")
        static let helpFooter = NSLocalizedString("Visit the Help Center to get answers to common questions, or contact us for more help.", comment: "Support screen footer text displayed when Zendesk is enabled.")
        static let version = NSLocalizedString("Version", comment: "Label in Support view displaying the app version.")
        static let extraDebug = NSLocalizedString("Extra Debug", comment: "Option in Support view to enable/disable adding extra information to support ticket.")
        static let activityLogs = NSLocalizedString("Activity Logs", comment: "Option in Support view to see activity logs.")
        static let informationFooter = NSLocalizedString("The Extra Debug feature includes additional information in activity logs, and can help us troubleshoot issues with the app.", comment: "Support screen footer text explaining the Extra Debug feature.")
    }

    // MARK: - User Defaults Keys

    struct UserDefaultsKeys {
        static let extraDebug = "extra_debug"
    }

}
