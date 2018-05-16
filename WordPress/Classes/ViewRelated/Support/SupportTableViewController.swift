import UIKit
import WordPressAuthenticator

class SupportTableViewController: UITableViewController {

    // MARK: - Properties

    var sourceTag: WordPressSupportSourceTag?

    // If set, the Zendesk views will be shown from this view instead of in the navigation controller.
    // Specifically for Me > Help & Support on the iPad.
    var showHelpFromViewController: UIViewController?

    private var tableHandler: ImmuTableViewHandler!
    private let userDefaults = UserDefaults.standard

    // MARK: - Init

    override init(style: UITableViewStyle) {
        super.init(style: style)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshNotificationIndicator(_:)), name: .ZendeskPushNotificationReceivedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshNotificationIndicator(_:)), name: .ZendeskPushNotificationClearedNotification, object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required convenience init() {
        self.init(style: .grouped)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavBar()
        setupTable()
        ZendeskUtils.delegate = self
    }

    @objc func showFromTabBar() {
        let navigationController = UINavigationController.init(rootViewController: self)

        if WPDeviceIdentification.isiPad() {
            navigationController.modalTransitionStyle = .crossDissolve
            navigationController.modalPresentationStyle = .formSheet
        }

        let tabBarController = WPTabBarController.sharedInstance()
        if let presentedVC = tabBarController?.presentedViewController {
            presentedVC.present(navigationController, animated: true, completion: nil)
        } else {
            tabBarController?.present(navigationController, animated: true, completion: nil)
        }
    }

    // MARK: - Button Actions

    @IBAction func dismissPressed(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Helpers

    // Specifically for WPError, which is ObjC & has the sourceTag as a String.
    @objc func updateSourceTag(with description: String) {
        ZendeskUtils.updateSourceTag(with: description)
    }

}

// MARK: - Private Extension

private extension SupportTableViewController {

    func setupNavBar() {
        title = LocalizedText.viewTitle

        if  splitViewController == nil {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: LocalizedText.closeButton,
                                                               style: WPStyleGuide.barButtonStyleForBordered(),
                                                               target: self,
                                                               action: #selector(SupportTableViewController.dismissPressed(_:)))
        }
    }

    func setupTable() {
        ImmuTable.registerRows([SwitchRow.self,
                                NavigationItemRow.self,
                                TextRow.self,
                                HelpRow.self],
                               tableView: tableView)
        tableHandler = ImmuTableViewHandler(takeOver: self)
        reloadViewModel()
        WPStyleGuide.configureColors(for: view, andTableView: tableView)
        // remove empty cells
        tableView.tableFooterView = UIView()
    }

    // MARK: - Table Model

    func tableViewModel() -> ImmuTable {

        // Help Section
        var helpSectionRows = [HelpRow]()
        helpSectionRows.append(HelpRow(title: LocalizedText.wpHelpCenter, action: helpCenterSelected()))

        if ZendeskUtils.zendeskEnabled {
            helpSectionRows.append(HelpRow(title: LocalizedText.contactUs, action: contactUsSelected()))
            helpSectionRows.append(HelpRow(title: LocalizedText.myTickets, action: myTicketsSelected(), showIndicator: ZendeskUtils.showSupportNotificationIndicator))
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

    @objc func refreshNotificationIndicator(_ notification: Foundation.Notification) {
        reloadViewModel()
    }

    func reloadViewModel() {
        tableHandler.viewModel = tableViewModel()
    }

    // MARK: - Row Handlers

    func helpCenterSelected() -> ImmuTableAction {
        return { [unowned self] row in
            self.tableView.deselectSelectedRowWithAnimation(true)
            if ZendeskUtils.zendeskEnabled {
                guard let controllerToShowFrom = self.controllerToShowFrom() else {
                    return
                }
                ZendeskUtils.sharedInstance.showHelpCenterIfPossible(from: controllerToShowFrom, with: self.sourceTag)
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
                guard let controllerToShowFrom = self.controllerToShowFrom() else {
                    return
                }
                ZendeskUtils.sharedInstance.showNewRequestIfPossible(from: controllerToShowFrom, with: self.sourceTag)
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
            ZendeskUtils.pushNotificationRead()
            self.tableView.deselectSelectedRowWithAnimation(true)

            guard let controllerToShowFrom = self.controllerToShowFrom() else {
                return
            }
            ZendeskUtils.sharedInstance.showTicketListIfPossible(from: controllerToShowFrom, with: self.sourceTag)
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
        static let cell = ImmuTableCell.class(WPTableViewCellIndicator.self)

        let title: String
        let showIndicator: Bool
        let action: ImmuTableAction?

        init(title: String, action: @escaping ImmuTableAction, showIndicator: Bool = false) {
            self.title = title
            self.showIndicator = showIndicator
            self.action = action
        }

        func configureCell(_ cell: UITableViewCell) {
            let cell = cell as! WPTableViewCellIndicator
            cell.textLabel?.text = title
            WPStyleGuide.configureTableViewCell(cell)
            cell.textLabel?.textColor = WPStyleGuide.wordPressBlue()
            cell.showIndicator = showIndicator
        }
    }

    // MARK: - Helpers

    func controllerToShowFrom() -> UIViewController? {
        return showHelpFromViewController ?? navigationController ?? nil
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
        static let alertMessage = NSLocalizedString("To continue please enter your email address and name.", comment: "XXX")
        static let alertDone = NSLocalizedString("Done", comment: "Submit button on prompt for user information.")
        static let alertCancel = NSLocalizedString("Cancel", comment: "Cancel prompt for user information.")
        static let emailPlaceholder = NSLocalizedString("Email", comment: "Email address text field placeholder")
        static let namePlaceholder = NSLocalizedString("Name", comment: "Name text field placeholder")
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

// MARK: - Private Extension for Alert handling

private extension SupportTableViewController {

    func promptUserForInformation() {

        let alertController = UIAlertController(title: nil,
                                                message: LocalizedText.alertMessage,
                                                preferredStyle: .alert)

        // Cancel Action
        alertController.addCancelActionWithTitle(LocalizedText.alertCancel)

        // Done Action
        let doneAction = alertController.addDefaultActionWithTitle(LocalizedText.alertDone) { [weak alertController] (_) in
            guard let email = alertController?.textFields?.first?.text else {
                    return
            }
            let name = alertController?.textFields?.last?.text ?? self.generateDisplayName(from: email)
            ZendeskUtils.sharedInstance.createIdentityFor(email: email, name: name)
        }

        // Disable Done until a valid Email is entered.
        doneAction.isEnabled = false

        // Email Text Field
        alertController.addTextField(configurationHandler: { [weak self] textField in
            textField.clearButtonMode = .always
            textField.placeholder = LocalizedText.emailPlaceholder

            textField.addTarget(self,
                                action: #selector(self?.emailTextFieldDidChange),
                                for: UIControlEvents.editingChanged)
        })

        // Name Text Field
        alertController.addTextField { textField in
            textField.clearButtonMode = .always
            textField.placeholder = LocalizedText.namePlaceholder
        }

        // Show alert
        self.present(alertController, animated: true, completion: nil)

    }

    @objc func emailTextFieldDidChange(_ textField: UITextField) {
        guard let alertController = presentedViewController as? UIAlertController,
            let email = alertController.textFields?.first?.text,
            let doneAction = alertController.actions.last else {
                return
        }

        doneAction.isEnabled = EmailFormatValidator.validate(string: email)

        updateNameFieldForEmail(email)
    }

    func updateNameFieldForEmail(_ email: String) {
        guard let alertController = presentedViewController as? UIAlertController,
            let nameField = alertController.textFields?.last else {
                return
        }

        nameField.text = generateDisplayName(from: email)
    }

    func generateDisplayName(from rawEmail: String) -> String {

        // Generate Name, using the same format as Signup.

        // step 1: lower case
        let email = rawEmail.lowercased()
        // step 2: remove the @ and everything after
        let localPart = email.split(separator: "@")[0]
        // step 3: remove all non-alpha characters
        let localCleaned = localPart.replacingOccurrences(of: "[^A-Za-z/.]", with: "", options: .regularExpression)
        // step 4: turn periods into spaces
        let nameLowercased = localCleaned.replacingOccurrences(of: ".", with: " ")
        // step 5: capitalize
        let autoDisplayName = nameLowercased.capitalized

        return autoDisplayName
    }

}

// MARK: - ZendeskUtilsDelegate

extension SupportTableViewController: ZendeskUtilsDelegate {
    func userNotLoggedIn() {
        promptUserForInformation()
    }
}
