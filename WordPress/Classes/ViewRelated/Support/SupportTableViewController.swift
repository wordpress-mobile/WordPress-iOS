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

        createZendeskIdentity()
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

    func createZendeskIdentity() {

        let context = ContextManager.sharedInstance().mainContext
        let accountService = AccountService(managedObjectContext: context)

        guard let defaultAccount = accountService.defaultWordPressComAccount(),
        let api = defaultAccount.wordPressComRestApi else {
            return
        }

        let service = AccountSettingsService(userID: defaultAccount.userID.intValue, api: api)
        guard let accountSettings = service.settings else {
            return
        }

        ZendeskUtils.createIdentity(with: accountSettings)
    }

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

    func setupTicketInformation() {
        let appVersion = Bundle.main.shortVersionString() ?? "unknown"
        let deviceFreeSpace = getDeviceFreeSpace()
        let logFile = getLogFile()
        let blogsInfo = getBlogInfo()

        let ticketFields = ZendeskTicketFields(appVersion: appVersion,
                                               allBlogs: blogsInfo,
                                               deviceFreeSpace: deviceFreeSpace,
                                               networkInformation: "unknown",
                                               currentLog: logFile,
                                               tags: ["unknown"])

        ZendeskUtils.createRequest(ticketInformation: ticketFields)
    }

    // MARK: - Table Model

    func tableViewModel() -> ImmuTable {

        // Help Section
        var helpSectionRows = [HelpRow]()
        helpSectionRows.append(HelpRow(title: LocalizedText.wpHelpCenter, action: helpCenterSelected()))

        if ZendeskUtils.zendeskEnabled {
            helpSectionRows.append(HelpRow(title: LocalizedText.contactUs, action: contactUsSelected()))
            helpSectionRows.append(HelpRow(title: LocalizedText.myTickets, action: myTicketsSelected()))
        } else {
            helpSectionRows.append(HelpRow(title: LocalizedText.wpForums, action: contactUsSelected()))
        }

        let helpSection = ImmuTableSection(
            headerText: nil,
            rows: helpSectionRows,
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
            self.tableView.deselectSelectedRowWithAnimation(true)
            if ZendeskUtils.zendeskEnabled {
                guard let navController = self.navigationController else {
                    return
                }
                ZendeskUtils.showHelpCenter(from: navController)
            } else {
                guard let url = Constants.appSupportURL else {
                    return
                }
                UIApplication.shared.open(url)
            }
        }
    }

    func contactUsSelected() -> ImmuTableAction {
        return { [unowned self] row in
            self.tableView.deselectSelectedRowWithAnimation(true)
            if ZendeskUtils.zendeskEnabled {
                guard let navController = self.navigationController else {
                    return
                }
                ZendeskUtils.showNewRequest(from: navController)
                self.setupTicketInformation()
            } else {
                guard let url = Constants.forumsURL else {
                    return
                }
                UIApplication.shared.open(url)
            }
        }
    }

    func myTicketsSelected() -> ImmuTableAction {
        return { [unowned self] row in
            self.tableView.deselectSelectedRowWithAnimation(true)
            guard let navController = self.navigationController else {
                return
            }
            ZendeskUtils.showTicketList(from: navController)
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

    // MARK: - Data Helpers

    func getDeviceFreeSpace() -> String {

        var deviceFreeSpace = "unknown"

        if let resourceValues = try? URL(fileURLWithPath: "/").resourceValues(forKeys: [.volumeAvailableCapacityKey]),
            let capacity = resourceValues.volumeAvailableCapacity {
            // format string using human readable units. ex: 1.5 GB
            deviceFreeSpace = ByteCountFormatter.string(fromByteCount: Int64(capacity), countStyle: .binary)
        }

        return deviceFreeSpace
    }

    func getLogFile() -> String {

        var logFile = ""

        if let appDelegate = UIApplication.shared.delegate as? WordPressAppDelegate,
            let fileLogger = appDelegate.logger.fileLogger,
            let logFileInfo = fileLogger.logFileManager.sortedLogFileInfos.first,
            let logData = try? Data(contentsOf: URL(fileURLWithPath: logFileInfo.filePath)),
            let logText = String.init(data: logData, encoding: .utf8) {
            logFile = logText

        }

        return logFile
    }

    func getBlogInfo() -> String {

        var blogsInfo = "none"
        let blogSeperator = "\n----------\n"

        let blogService = BlogService(managedObjectContext: ContextManager.sharedInstance().mainContext)

        if let allBlogs = blogService.blogsForAllAccounts() as? [Blog], allBlogs.count > 0 {
            blogsInfo = (allBlogs.map { return $0.logDescription() }).joined(separator: blogSeperator)
        }

        return blogsInfo
    }

    // MARK: - Localized Text

    struct LocalizedText {
        static let viewTitle = NSLocalizedString("Support", comment: "View title for Support page.")
        static let closeButton = NSLocalizedString("Close", comment: "Dismiss the current view")
        static let wpHelpCenter = NSLocalizedString("WordPress Help Center", comment: "Option in Support view to launch the Help Center.")
        static let contactUs = NSLocalizedString("Contact Us", comment: "Option in Support view to contact the support team.")
        static let wpForums = NSLocalizedString("WordPress Forums", comment: "Option in Support view to view the Forums.")
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

    // MARK: - Constants

    struct Constants {
        static let appSupportURL = URL(string: "https://apps.wordpress.com/support")
        static let forumsURL = URL(string: "https://ios.forums.wordpress.org")
    }

}
