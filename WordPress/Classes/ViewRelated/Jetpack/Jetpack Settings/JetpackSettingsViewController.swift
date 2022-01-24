import Foundation
import CocoaLumberjack
import WordPressShared


/// The purpose of this class is to render and modify the Jetpack Settings associated to a site.
///
open class JetpackSettingsViewController: UITableViewController {

    // MARK: - Private Properties

    fileprivate var blog: Blog!
    fileprivate var service: BlogJetpackSettingsService!
    fileprivate lazy var handler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self)
    }()

    // MARK: - Computed Properties

    fileprivate var settings: BlogSettings {
        return blog.settings!
    }

    // MARK: - Static Properties

    fileprivate static let footerHeight = CGFloat(34.0)
    fileprivate static let learnMoreUrl = "https://jetpack.com/support/sso/"
    fileprivate static let wordPressLoginSection = 3

    // MARK: - Initializer

    @objc public convenience init(blog: Blog) {
        self.init(style: .grouped)
        self.blog = blog
        self.service = BlogJetpackSettingsService(managedObjectContext: settings.managedObjectContext!)
    }

    // MARK: - View Lifecycle

    open override func viewDidLoad() {
        super.viewDidLoad()
        WPAnalytics.trackEvent(.jetpackSettingsViewed)
        title = NSLocalizedString("Settings", comment: "Title for the Jetpack Security Settings Screen")
        ImmuTable.registerRows([SwitchRow.self], tableView: tableView)
        ImmuTable.registerRows([NavigationItemRow.self], tableView: tableView)
        WPStyleGuide.configureColors(view: view, tableView: tableView)
        reloadViewModel()
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

    // MARK: - Model

    fileprivate func reloadViewModel() {
        handler.viewModel = tableViewModel()
    }

    func tableViewModel() -> ImmuTable {
        var monitorRows = [ImmuTableRow]()
        monitorRows.append(
            SwitchRow(title: NSLocalizedString("Monitor your site's uptime",
                                               comment: "Jetpack Monitor Settings: Monitor site's uptime"),
                      value: self.settings.jetpackMonitorEnabled,
                      onChange: self.jetpackMonitorEnabledValueChanged())
        )

        if self.settings.jetpackMonitorEnabled {
            monitorRows.append(
                SwitchRow(title: NSLocalizedString("Send notifications by email",
                                                   comment: "Jetpack Monitor Settings: Send notifications by email"),
                          value: self.settings.jetpackMonitorEmailNotifications,
                          onChange: self.sendNotificationsByEmailValueChanged())
            )
            monitorRows.append(
                SwitchRow(title: NSLocalizedString("Send push notifications",
                                                   comment: "Jetpack Monitor Settings: Send push notifications"),
                          value: self.settings.jetpackMonitorPushNotifications,
                          onChange: self.sendPushNotificationsValueChanged())
            )
        }

        var bruteForceAttackRows = [ImmuTableRow]()
        bruteForceAttackRows.append(
            SwitchRow(title: NSLocalizedString("Block malicious login attempts",
                                               comment: "Jetpack Settings: Block malicious login attempts"),
                      value: self.settings.jetpackBlockMaliciousLoginAttempts,
                      onChange: self.blockMaliciousLoginAttemptsValueChanged())
        )

        if self.settings.jetpackBlockMaliciousLoginAttempts {
            bruteForceAttackRows.append(
                NavigationItemRow(title: NSLocalizedString("Allowlisted IP addresses",
                                                           comment: "Jetpack Settings: Allowlisted IP addresses"),
                                  action: self.pressedAllowlistedIPAddresses())
            )
        }

        var wordPressLoginRows = [ImmuTableRow]()
        wordPressLoginRows.append(
            SwitchRow(title: NSLocalizedString("Allow WordPress.com login",
                                               comment: "Jetpack Settings: Allow WordPress.com login"),
                      value: self.settings.jetpackSSOEnabled,
                      onChange: self.ssoEnabledChanged())
        )

        if self.settings.jetpackSSOEnabled {
            wordPressLoginRows.append(
                SwitchRow(title: NSLocalizedString("Match accounts using email",
                                                   comment: "Jetpack Settings: Match accounts using email"),
                          value: self.settings.jetpackSSOMatchAccountsByEmail,
                          onChange: self.matchAccountsUsingEmailChanged())
            )
            wordPressLoginRows.append(
                SwitchRow(title: NSLocalizedString("Require two-step authentication",
                                                   comment: "Jetpack Settings: Require two-step authentication"),
                          value: self.settings.jetpackSSORequireTwoStepAuthentication,
                          onChange: self.requireTwoStepAuthenticationChanged())
            )
        }

        var manageConnectionRows = [ImmuTableRow]()
        manageConnectionRows.append(
            NavigationItemRow(title: NSLocalizedString("Manage Connection",
                                comment: "Jetpack Settings: Manage Connection"),
                              action: self.pressedManageConnection())
        )

        return ImmuTable(sections: [
            ImmuTableSection(
                headerText: "",
                rows: monitorRows,
                footerText: nil),
            ImmuTableSection(
                headerText: NSLocalizedString("Brute Force Attack Protection",
                                              comment: "Jetpack Settings: Brute Force Attack Protection Section"),
                rows: bruteForceAttackRows,
                footerText: nil),
            ImmuTableSection(
                headerText: "",
                rows: manageConnectionRows,
                footerText: nil),
            ImmuTableSection(
                headerText: NSLocalizedString("WordPress.com login",
                                              comment: "Jetpack Settings: WordPress.com Login settings"),
                rows: wordPressLoginRows,
                footerText: nil)
            ])
    }

    // MARK: Learn More footer

    open override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == JetpackSettingsViewController.wordPressLoginSection {
            return JetpackSettingsViewController.footerHeight
        }
        return 0.0
    }

    open override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == JetpackSettingsViewController.wordPressLoginSection {
            let footer = UITableViewHeaderFooterView(frame: CGRect(x: 0.0,
                                                                   y: 0.0,
                                                                   width: tableView.frame.width,
                                                                   height: JetpackSettingsViewController.footerHeight))
            footer.textLabel?.text = NSLocalizedString("Learn more...",
                                                       comment: "Jetpack Settings: WordPress.com Login WordPress login footer text")
            footer.textLabel?.font = UIFont.preferredFont(forTextStyle: .footnote)
            footer.textLabel?.isUserInteractionEnabled = true

            let tap = UITapGestureRecognizer(target: self, action: #selector(handleLearnMoreTap(_:)))
            footer.addGestureRecognizer(tap)
            return footer
        }
        return nil
    }

    // MARK: - Row Handlers

    fileprivate func jetpackMonitorEnabledValueChanged() -> (_ newValue: Bool) -> Void {
        return { [unowned self] newValue in
            WPAnalytics.trackSettingsChange("jetpack_settings", fieldName: "monitor_enabled", value: newValue as Any)
            self.settings.jetpackMonitorEnabled = newValue
            self.reloadViewModel()
            self.service.updateJetpackSettingsForBlog(self.blog,
                                                      success: {},
                                                      failure: { [weak self] (_) in
                                                          self?.refreshSettingsAfterSavingError()
                                                      })
        }
    }

    fileprivate func sendNotificationsByEmailValueChanged() -> (_ newValue: Bool) -> Void {
        return { [unowned self] newValue in
            WPAnalytics.trackSettingsChange("jetpack_settings", fieldName: "send_notification_by_email", value: newValue as Any)
            self.settings.jetpackMonitorEmailNotifications = newValue
            self.service.updateJetpackMonitorSettingsForBlog(self.blog,
                                                             success: {},
                                                             failure: { [weak self] (_) in
                                                                 self?.refreshSettingsAfterSavingError()
                                                             })
        }
    }

    fileprivate func sendPushNotificationsValueChanged() -> (_ newValue: Bool) -> Void {
        return { [unowned self] newValue in
            WPAnalytics.trackSettingsChange("jetpack_settings", fieldName: "send_push_notifications", value: newValue as Any)
            self.settings.jetpackMonitorPushNotifications = newValue
            self.service.updateJetpackMonitorSettingsForBlog(self.blog,
                                                             success: {},
                                                             failure: { [weak self] (_) in
                                                                 self?.refreshSettingsAfterSavingError()
                                                             })
        }
    }

    fileprivate func blockMaliciousLoginAttemptsValueChanged() -> (_ newValue: Bool) -> Void {
        return { [unowned self] newValue in
            WPAnalytics.trackSettingsChange("jetpack_settings", fieldName: "block_malicious_logins", value: newValue as Any)
            self.settings.jetpackBlockMaliciousLoginAttempts = newValue
            self.reloadViewModel()
            self.service.updateJetpackSettingsForBlog(self.blog,
                                                      success: {},
                                                      failure: { [weak self] (_) in
                                                          self?.refreshSettingsAfterSavingError()
                                                      })
        }
    }

    func pressedAllowlistedIPAddresses() -> ImmuTableAction {
        return { [unowned self] row in
            let allowListedIPs = self.settings.jetpackLoginAllowListedIPAddresses
            let settingsViewController = SettingsListEditorViewController(collection: allowListedIPs)

            settingsViewController.title = NSLocalizedString("Allowlisted IP Addresses",
                                                             comment: "Allowlisted IP Addresses Title")
            settingsViewController.insertTitle = NSLocalizedString("New IP or IP Range",
                                                                   comment: "IP Address or Range Insertion Title")
            settingsViewController.editTitle = NSLocalizedString("Edit IP or IP Range",
                                                                 comment: "IP Address or Range Edition Title")
            settingsViewController.footerText = NSLocalizedString("You may allowlist an IP address or series of addresses preventing them from ever being blocked by Jetpack. IPv4 and IPv6 are acceptable. To specify a range, enter the low value and high value separated by a dash. Example: 12.12.12.1-12.12.12.100.",
                                                                  comment: "Text rendered at the bottom of the Allowlisted IP Addresses editor, should match Calypso.")

            settingsViewController.onChange = { [weak self] (updated: Set<String>) in
                self?.settings.jetpackLoginAllowListedIPAddresses = updated
                guard let blog = self?.blog else {
                    return
                }
                self?.service.updateJetpackSettingsForBlog(blog,
                                                           success: { [weak self] in
                                                               // viewWillAppear will trigger a refresh, maybe before
                                                               // the new IPs are saved, so lets refresh again here
                                                               self?.refreshSettings()
                                                            WPAnalytics.track(.jetpackAllowlistedIpsChanged)
                                                           },
                                                           failure: { [weak self] (_) in
                                                               self?.refreshSettingsAfterSavingError()
                                                           })
            }
            self.navigationController?.pushViewController(settingsViewController, animated: true)
            WPAnalytics.track(.jetpackAllowlistedIpsViewed)
        }
    }

    fileprivate func ssoEnabledChanged() -> (_ newValue: Bool) -> Void {
        return { [unowned self] newValue in
            WPAnalytics.trackSettingsChange("jetpack_settings", fieldName: "wpcom_login_allowed", value: newValue as Any)
            self.settings.jetpackSSOEnabled = newValue
            self.reloadViewModel()
            self.service.updateJetpackSettingsForBlog(self.blog,
                                                      success: {},
                                                      failure: { [weak self] (_) in
                                                          self?.refreshSettingsAfterSavingError()
                                                      })
        }
    }

    fileprivate func matchAccountsUsingEmailChanged() -> (_ newValue: Bool) -> Void {
        return { [unowned self] newValue in
            WPAnalytics.trackSettingsChange("jetpack_settings", fieldName: "match_accounts_using_email", value: newValue as Any)
            self.settings.jetpackSSOMatchAccountsByEmail = newValue
            self.service.updateJetpackSettingsForBlog(self.blog,
                                                      success: {},
                                                      failure: { [weak self] (_) in
                                                          self?.refreshSettingsAfterSavingError()
                                                      })
        }
    }

    fileprivate func requireTwoStepAuthenticationChanged() -> (_ newValue: Bool) -> Void {
        return { [unowned self] newValue in
            WPAnalytics.trackSettingsChange("jetpack_settings", fieldName: "require_two_step_auth", value: newValue as Any)
            self.settings.jetpackSSORequireTwoStepAuthentication = newValue
            self.service.updateJetpackSettingsForBlog(self.blog,
                                                      success: {},
                                                      failure: { [weak self] (_) in
                                                          self?.refreshSettingsAfterSavingError()
                                                      })
        }
    }

    fileprivate func pressedManageConnection() -> ImmuTableAction {
        return { [unowned self] row in
            WPAnalytics.trackEvent(.jetpackManageConnectionViewed)
            let jetpackConnectionVC = JetpackConnectionViewController(blog: blog)
            jetpackConnectionVC.delegate = self
            self.navigationController?.pushViewController(jetpackConnectionVC, animated: true)
        }
    }

    // MARK: - Footer handler

    @objc fileprivate func handleLearnMoreTap(_ sender: UITapGestureRecognizer) {
        guard let url =  URL(string: JetpackSettingsViewController.learnMoreUrl) else {
            return
        }
        let webViewController = WebViewControllerFactory.controller(url: url, source: "jetpack_settings_learn_more")

        if presentingViewController != nil {
            navigationController?.pushViewController(webViewController, animated: true)
        } else {
            let navController = UINavigationController(rootViewController: webViewController)
            present(navController, animated: true)
        }
    }

    // MARK: - Persistance

    fileprivate func refreshSettings() {
        service.syncJetpackSettingsForBlog(blog,
                                           success: { [weak self] in
                                               self?.reloadViewModel()
                                               DDLogInfo("Reloaded Jetpack Settings")
                                           },
                                           failure: { (error: Error?) in
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

}

extension JetpackSettingsViewController: JetpackConnectionDelegate {
    func jetpackDisconnectedForBlog(_ blog: Blog) {
        if blog == self.blog {
            navigationController?.popToRootViewController(animated: true)
        }
    }
}
