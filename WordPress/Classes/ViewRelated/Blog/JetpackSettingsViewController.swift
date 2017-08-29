import Foundation
import CocoaLumberjack
import WordPressShared


/// The purpose of this class is to render and modify the Jetpack Settings associated to a site.
///
open class JetpackSecuritySettingsViewController: UITableViewController {

    // MARK: - Initializer

    public convenience init(blog: Blog) {
        self.init(style: .grouped)
        self.blog = blog
        self.service = BlogJetpackSettingsService(managedObjectContext: settings.managedObjectContext!)
    }

    // MARK: - View Lifecycle

    open override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
        setupTableView()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadSelectedRow()
        tableView.deselectSelectedRowWithAnimation(true)
        refreshSettings()
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    // MARK: - Setup Helpers

    fileprivate func setupNavBar() {
        title = NSLocalizedString("Security", comment: "Title for the Jetpack Security Settings Screen")
    }

    fileprivate func setupTableView() {
        WPStyleGuide.configureColors(for: view, andTableView: tableView)
        WPStyleGuide.configureAutomaticHeightRows(for: tableView)
    }

    // MARK: - Persistance

    fileprivate func refreshSettings() {
        service.syncJetpackSettingsForBlog(blog,
                                           success: { [weak self] in
                                               self?.tableView.reloadData()
                                               DDLogInfo("Reloaded Jetpack Settings")
                                           }, failure: { (error: Error?) in
                                               DDLogError("Error while syncing blog Jetpack Settings: \(String(describing: error))")
                                           })
    }

    fileprivate func refreshSettingsAfterSavingError() {
        let errorTitle = NSLocalizedString("Error updating Jetpack settings",
                                           comment: "Title of error dialog when updating jetpack settins fail.")
        let errorMessage = NSLocalizedString("Please contact support for assistance.",
                                             comment: "Message displayed on an error alert to prompt the user to contact support")
        WPError.showAlert(withTitle: errorTitle, message: errorMessage, withSupportButton: true)
        refreshSettings()
    }

    // MARK: - UITableViewDataSource Methods

    open override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rowAtIndexPath(indexPath)
        let cell = cellForRow(row, tableView: tableView)

        switch row.style {
        case .Switch:
            configureSwitchCell(cell as! SwitchTableViewCell, row: row)
        default:
            configureTextCell(cell as! WPTableViewCell, row: row)
        }

        return cell
    }

    open override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].headerText
    }

    open override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        WPStyleGuide.configureTableViewSectionHeader(view)
    }

    open override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == Section.Index.WordPressComLogin.rawValue {

            let footer = UITableViewHeaderFooterView.init(frame: CGRect(x: 0.0,
                                                                        y: 0.0,
                                                                        width: tableView.frame.width,
                                                                        height: JetpackSecuritySettingsViewController.footerHeight))
            footer.textLabel?.text = sections[section].footerText
            footer.textLabel?.font = UIFont.preferredFont(forTextStyle: .footnote)
            WPStyleGuide.configureTableViewSectionFooter(footer)
            footer.isUserInteractionEnabled = true

            let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleLearnMoreTap(_:)))
            footer.addGestureRecognizer(tap)

            return footer
        }
        return nil
    }

    open override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == Section.Index.WordPressComLogin.rawValue {
            return JetpackSecuritySettingsViewController.footerHeight
        }
        return 0.0
    }

    open override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        WPStyleGuide.configureTableViewSectionFooter(view)
    }

    // MARK: - UITableViewDelegate Methods

    open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        rowAtIndexPath(indexPath).handler?(tableView)
    }

    // MARK: - Cell Setup Helpers

    fileprivate func rowAtIndexPath(_ indexPath: IndexPath) -> Row {
        return sections[indexPath.section].rows[indexPath.row]
    }

    fileprivate func cellForRow(_ row: Row, tableView: UITableView) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: row.style.rawValue) {
            return cell
        }

        switch row.style {
        case .Value1:
            return WPTableViewCell(style: .value1, reuseIdentifier: row.style.rawValue)
        case .Switch:
            return SwitchTableViewCell(style: .default, reuseIdentifier: row.style.rawValue)
        }
    }

    fileprivate func configureTextCell(_ cell: WPTableViewCell, row: Row) {
        cell.textLabel?.text = row.title
        cell.accessoryType = .disclosureIndicator
        cell.isUserInteractionEnabled = row.enabled
        cell.textLabel?.isEnabled = row.enabled
        WPStyleGuide.configureTableViewCell(cell)
    }

    fileprivate func configureSwitchCell(_ cell: SwitchTableViewCell, row: Row) {
        cell.name = row.title
        cell.on = row.boolValue ?? true
        cell.onChange = { (newValue: Bool) in
            row.handler?(newValue as AnyObject?)
        }
        cell.isUserInteractionEnabled = row.enabled
        cell.textLabel?.isEnabled = row.enabled
        cell.flipSwitch.isEnabled = row.enabled
    }

    // MARK: - Row Handlers

    fileprivate func pressedJetpackMonitorEnabled(_ payload: AnyObject?) {
        guard let enabled = payload as? Bool else {
            return
        }

        settings.jetpackMonitorEnabled = enabled
        service.updateJetpackMonitorEnabledForBlog(blog,
                                                   value: enabled,
                                                   success: {
                                                       self.tableView.reloadSections(IndexSet(integer: Section.Index.Monitor.rawValue),
                                                                                     with: .none)
                                                   }, failure: { (_) in
                                                       self.refreshSettingsAfterSavingError()
                                                   })
    }

    fileprivate func pressedSendNotificationsByEmail(_ payload: AnyObject?) {
        guard let enabled = payload as? Bool else {
            return
        }

        settings.jetpackMonitorEmailNotifications = enabled
        service.updateJetpackMonitorSettinsForBlog(blog,
                                                   success: {},
                                                   failure: { (_) in
                                                       self.refreshSettingsAfterSavingError()
                                                   })
    }

    fileprivate func pressedSendPushNotifications(_ payload: AnyObject?) {
        guard let enabled = payload as? Bool else {
            return
        }

        settings.jetpackMonitorPushNotifications = enabled
        service.updateJetpackMonitorSettinsForBlog(blog,
                                                   success: {},
                                                   failure: { (_) in
                                                       self.refreshSettingsAfterSavingError()
                                                   })
    }

    fileprivate func pressedBlockMaliciousLoginAttempts(_ payload: AnyObject?) {
        guard let enabled = payload as? Bool else {
            return
        }

        settings.jetpackBlockMaliciousLoginAttempts = enabled
        service.updateBlockMaliciousLoginAttemptsForBlog(blog,
                                                         value: enabled,
                                                         success: {
                                                             self.tableView.reloadSections(IndexSet(integer: Section.Index.BruteForceAttack.rawValue),
                                                                                           with: .none)
                                                         }, failure: { (_) in
                                                             self.refreshSettingsAfterSavingError()
                                                         })
    }

    fileprivate func pressedWhitelistedIPAddresses(_ payload: AnyObject?) {
         let whiteListedIPs = settings.jetpackLoginWhiteListedIPAddresses
         let settingsViewController = SettingsListEditorViewController(collection: whiteListedIPs)

         settingsViewController.title = NSLocalizedString("Whitelisted IP Addresses",
                                                          comment: "Whitelisted IP Addresses Title")
         settingsViewController.insertTitle = NSLocalizedString("New IP or IP Range",
                                                                comment: "IP Address or Range Insertion Title")
         settingsViewController.editTitle = NSLocalizedString("Edit IP or IP Range",
                                                              comment: "IP Address or Range Edition Title")
         settingsViewController.footerText = NSLocalizedString("You may whitelist an IP address or series of addresses preventing them from ever being blocked by Jetpack. IPv4 and IPv6 are acceptable. To specify a range, enter the low value and high value separated by a dash. Example: 12.12.12.1-12.12.12.100.",
                                                               comment: "Text rendered at the bottom of the Whitelisted IP Addresses editor, should match Calypso.")

         settingsViewController.onChange = { [weak self] (updated: Set<String>) in
            self?.settings.jetpackLoginWhiteListedIPAddresses = updated
            guard let blog = self?.blog else {
                return
            }
            self?.service.updateWhiteListedIPAddressesForBlog(blog,
                                                              value: updated,
                                                              success: {
                                                              }, failure: { (error) in
                                                                  self?.refreshSettingsAfterSavingError()
                                                              })
        }
        navigationController?.pushViewController(settingsViewController, animated: true)
    }

    fileprivate func pressedAllowWordPressComLogin(_ payload: AnyObject?) {
        guard let enabled = payload as? Bool else {
            return
        }

        settings.jetpackSSOEnabled = enabled
        service.updateSSOEnabledForBlog(blog,
                                        value: enabled,
                                        success: {
                                            self.tableView.reloadSections(IndexSet(integer: Section.Index.WordPressComLogin.rawValue),
                                                                          with: .none)
                                        }, failure: { (error) in
                                            self.refreshSettingsAfterSavingError()
                                        })
    }

    fileprivate func pressedMatchAccountsUsingEmail(_ payload: AnyObject?) {
        guard let enabled = payload as? Bool else {
            return
        }

        settings.jetpackSSOMatchAccountsByEmail = enabled
        service.updateSSOMatchAccountsByEmailForBlog(blog,
                                                     value: enabled,
                                                     success: {},
                                                     failure: { (error) in
                                                         self.refreshSettingsAfterSavingError()
                                                     })
    }

    fileprivate func pressedRequireTwoStepAuthentication(_ payload: AnyObject?) {
        guard let enabled = payload as? Bool else {
            return
        }

        settings.jetpackSSORequireTwoStepAuthentication = enabled
        service.updateSSORequireTwoStepAuthenticationForBlog(blog,
                                                             value: enabled,
                                                             success: {},
                                                             failure: { (error) in
                                                                 self.refreshSettingsAfterSavingError()
                                                             })
    }

    // MARK: - Handle Tap on Footer

    func handleLearnMoreTap(_ sender: UITapGestureRecognizer) {
        guard let url =  URL(string: JetpackSecuritySettingsViewController.learnMoreUrl) else {
            return
        }
        guard let webViewController = WPWebViewController(url: url) else {
            return
        }

        if presentingViewController != nil {
            navigationController?.pushViewController(webViewController, animated: true)
        } else {
            let navController = UINavigationController(rootViewController: webViewController)
            present(navController, animated: true, completion: nil)
        }
    }

    // MARK: - Computed Properties

    fileprivate var sections: [Section] {
        return [monitorSection, bruteForceAttackSection, wordPressLoginSection]
    }

    fileprivate var monitorSection: Section {
        let rows = [
            Row(style: .Switch,
                title: NSLocalizedString("Monitor your site's uptime", comment: "Jetpack Monitor Settings: Monitor site's uptime"),
                enabled: true,
                boolValue: self.settings.jetpackMonitorEnabled,
                handler: { [weak self] in
                    self?.pressedJetpackMonitorEnabled($0)
                }),

            Row(style: .Switch,
                title: NSLocalizedString("Send notifications by email", comment: "Jetpack Monitor Settings: Send notifications by email"),
                enabled: self.settings.jetpackMonitorEnabled,
                boolValue: self.settings.jetpackMonitorEmailNotifications,
                handler: { [weak self] in
                    self?.pressedSendNotificationsByEmail($0)
                }),

            Row(style: .Switch,
                title: NSLocalizedString("Send push notifications", comment: "Jetpack Monitor Settings: Send push notifications"),
                enabled: self.settings.jetpackMonitorEnabled,
                boolValue: self.settings.jetpackMonitorPushNotifications,
                handler: { [weak self] in
                    self?.pressedSendPushNotifications($0)
                })
        ]

        return Section(rows: rows)
    }

    fileprivate var bruteForceAttackSection: Section {
        let headerText = NSLocalizedString("Brute Force Attack Protection", comment: "Jetpack Settings: Brute Force Attack Protection Section")
        let rows = [
            Row(style: .Switch,
                title: NSLocalizedString("Block malicious login attempts", comment: "Jetpack Settings: Block malicious login attempts"),
                enabled: true,
                boolValue: self.settings.jetpackBlockMaliciousLoginAttempts,
                handler: { [weak self] in
                    self?.pressedBlockMaliciousLoginAttempts($0)
                }),

            Row(style: .Value1,
                title: NSLocalizedString("Whitelisted IP addresses", comment: "Jetpack Settings: Whitelisted IP addresses"),
                enabled: self.settings.jetpackBlockMaliciousLoginAttempts,
                handler: self.pressedWhitelistedIPAddresses)
        ]

        return Section(headerText: headerText, rows: rows)
    }

    fileprivate var wordPressLoginSection: Section {
        let headerText = NSLocalizedString("WordPress.com login", comment: "Jetpack Settings: WordPress.com Login settings")
        let footerText = NSLocalizedString("Learn more...", comment: "Discussion Settings: Footer Text")
        let rows = [
            Row(style: .Switch,
                title: NSLocalizedString("Allow WordPress.com login", comment: "Jetpack Settings: Allow WordPress.com login"),
                enabled: true,
                boolValue: self.settings.jetpackSSOEnabled,
                handler: { [weak self] in
                    self?.pressedAllowWordPressComLogin($0)
                }),

            Row(style: .Switch,
                title: NSLocalizedString("Match accounts using email", comment: "Jetpack Settings: Match accounts using email"),
                enabled: self.settings.jetpackSSOEnabled,
                boolValue: self.settings.jetpackSSOMatchAccountsByEmail,
                handler: { [weak self] in
                    self?.pressedMatchAccountsUsingEmail($0)
                }),

            Row(style: .Switch,
                title: NSLocalizedString("Require two-step authentication", comment: "Jetpack Settings: Require two-step authentication"),
                enabled: self.settings.jetpackSSOEnabled,
                boolValue: self.settings.jetpackSSORequireTwoStepAuthentication,
                handler: { [weak self] in
                    self?.pressedRequireTwoStepAuthentication($0)
                })
        ]

        return Section(headerText: headerText, footerText: footerText, rows: rows)
    }

    // MARK: - Private Nested Classes

    fileprivate class Section {
        let headerText: String?
        let footerText: String?
        let rows: [Row]

        init(headerText: String? = nil, footerText: String? = nil, rows: [Row]) {
            self.headerText = headerText
            self.footerText = footerText
            self.rows = rows
        }

        enum Index: Int {
            case Monitor = 0
            case BruteForceAttack = 1
            case WordPressComLogin = 2
        }
    }

    fileprivate class Row {
        let style: Style
        let title: String
        var enabled: Bool
        var boolValue: Bool?
        let handler: Handler?

        init(style: Style, title: String, enabled: Bool, boolValue: Bool? = false, handler: Handler? = nil) {
            self.style = style
            self.title = title
            self.enabled = enabled
            self.boolValue = boolValue
            self.handler = handler
        }

        typealias Handler = ((AnyObject?) -> Void)

        enum Style: String {
            case Value1 = "Value1"
            case Switch = "SwitchCell"
        }
    }

    // MARK: - Private Properties

    fileprivate var blog: Blog!
    fileprivate var service: BlogJetpackSettingsService!

    // MARK: - Computed Properties

    fileprivate var settings: BlogSettings {
        return blog.settings!
    }

    fileprivate static let footerHeight = CGFloat(34.0)
    fileprivate static let learnMoreUrl = "https://jetpack.com/support/sso/"
}
