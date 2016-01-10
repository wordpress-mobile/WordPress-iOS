import UIKit
import WordPressShared

class MeViewController: UITableViewController, UIViewControllerRestoration {
    static let restorationIdentifier = "WPMeRestorationID"
    var tableViewModel = ImmuTable(sections: []) {
        didSet {
            if isViewLoaded() {
                tableView.reloadData()
            }
        }
    }

    static func viewControllerWithRestorationIdentifierPath(identifierComponents: [AnyObject], coder: NSCoder) -> UIViewController? {
        return self.init()
    }

    // MARK: - Table View Controller

    override init(style: UITableViewStyle) {
        super.init(style: style)
        navigationItem.title = NSLocalizedString("Me", comment: "Me page title")
        restorationIdentifier = self.dynamicType.restorationIdentifier
        restorationClass = self.dynamicType
        clearsSelectionOnViewWillAppear = false
    }

    required convenience init() {
        self.init(style: .Grouped)
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "refreshModelWithNotification:", name: WPAccountDefaultWordPressComAccountChangedNotification, object: nil)
        notificationCenter.addObserver(self, selector: "refreshModelWithNotification:", name: WPAccountDefaultWordPressComAccountDetailsUpdatedNotification, object: nil)
        notificationCenter.addObserver(self, selector: "refreshModelWithNotification:", name: HelpshiftUnreadCountUpdatedNotification, object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        ImmuTable.registerRows([
            NavigationItemRow.self,
            BadgeNavigationItemRow.self,
            ButtonRow.self,
            DestructiveButtonRow.self
            ], tableView: self.tableView)

        reloadViewModel()
        // FIXME: @koke 2015-12-17
        // See https://github.com/wordpress-mobile/WordPress-iOS/issues/4416
        // The view controller should observe changes to account details
        // regardless of who asked for them.
        // For now I'm just porting this to Swift as it is.
        refreshAccountDetails()

        WPStyleGuide.resetReadableMarginsForTableView(tableView)
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        HelpshiftUtils.refreshUnreadNotificationCount()
        animateDeselectionInteractively()
    }

    func reloadViewModel() {
        let account = defaultAccount()
        let loggedIn = account != nil
        let badgeCount = HelpshiftUtils.isHelpshiftEnabled() ? HelpshiftUtils.unreadNotificationCount() : 0

        // Warning: If you set the header view after the table model, the
        // table's top margin will be wrong.
        //
        // My guess is the table view adjusts the height of the first section
        // based on if there's a header or not.
        tableView.tableHeaderView = headerView(account)
        tableViewModel = tableViewModel(loggedIn, helpshiftBadgeCount: badgeCount)
    }

    func headerView(account: WPAccount?) -> MeHeaderView? {
        guard let account = account else { return nil }

        let header = cachedHeaderView
        header.setDisplayName(account.displayName)
        header.setUsername(account.username)
        header.setGravatarEmail(account.email)
        return header
    }

    func tableViewModel(loggedIn: Bool, helpshiftBadgeCount: Int) -> ImmuTable {
        let myProfile = NavigationItemRow(
            title: NSLocalizedString("My Profile", comment: "Link to My Profile section"),
            action: pushMyProfile())

        let accountSettings = NavigationItemRow(
            title: NSLocalizedString("Account Settings", comment: "Link to Account Settings section"),
            action: pushAccountSettings())

        let notificationSettings = NavigationItemRow(
            title: NSLocalizedString("Notification Settings", comment: "Link to Notification Settings section"),
            action: pushNotificationSettings())

        let helpAndSupport = BadgeNavigationItemRow(
            title: NSLocalizedString("Help & Support", comment: "Link to Help section"),
            badgeCount: helpshiftBadgeCount,
            action: pushHelp())

        let about = NavigationItemRow(
            title: NSLocalizedString("About", comment: "Link to About section (contains info about the app)"),
            action: pushAbout())

        let logIn = ButtonRow(
            title: NSLocalizedString("Connect to WordPress.com", comment: "Label for connecting to WordPress.com account"),
            action: presentLogin())

        let logOut = DestructiveButtonRow(
            title: NSLocalizedString("Disconnect from WordPress.com", comment: "Label for disconnecting from WordPress.com account"),
            action: confirmLogout())

        let wordPressComAccount = NSLocalizedString("WordPress.com Account", comment: "WordPress.com sign-in/sign-out section header title")

        if loggedIn {
            if Feature.enabled(.MyProfile) {
                return ImmuTable(
                    sections: [
                        ImmuTableSection(rows: [
                            myProfile,
                            accountSettings,
                            notificationSettings
                            ]),
                        ImmuTableSection(rows: [
                            helpAndSupport,
                            about
                            ]),
                        ImmuTableSection(
                            headerText: wordPressComAccount,
                            rows: [
                                logOut
                            ])
                    ])
            } else {
                return ImmuTable(
                    sections: [
                        ImmuTableSection(rows: [
                            accountSettings,
                            notificationSettings
                            ]),
                        ImmuTableSection(rows: [
                            helpAndSupport,
                            about
                            ]),
                        ImmuTableSection(
                            headerText: wordPressComAccount,
                            rows: [
                                logOut
                            ])
                    ])
            }
        } else { // Logged out
            return ImmuTable(
                sections: [
                    ImmuTableSection(rows: [
                        accountSettings,
                        ]),
                    ImmuTableSection(rows: [
                        helpAndSupport,
                        about
                        ]),
                    ImmuTableSection(
                        headerText: wordPressComAccount,
                        rows: [
                            logIn
                        ])
                ])
        }
    }
    // MARK: Table View Data Source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return tableViewModel.sections.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableViewModel.sections[section].rows.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let row = tableViewModel.rowAtIndexPath(indexPath)
        let cell = tableView.dequeueReusableCellWithIdentifier(row.reusableIdentifier, forIndexPath: indexPath)

        row.configureCell(cell)

        return cell
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return tableViewModel.sections[section].headerText
    }

    // MARK: Table View Delegate

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let row = tableViewModel.rowAtIndexPath(indexPath)
        row.action?(row)
    }

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = WPTableViewSectionHeaderFooterView(reuseIdentifier: nil)
        view.title = self.tableView(tableView, titleForHeaderInSection: section)
        return view
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let title = self.tableView(tableView, titleForHeaderInSection: section)
        return WPTableViewSectionHeaderFooterView.heightForHeader(title, width: tableView.frame.width)
    }

    // MARK: - Actions

    func pushMyProfile() -> ImmuTableActionType {
        return { [unowned self] row in
            WPAppAnalytics.track(.OpenedMyProfile)
            let controller = MyProfileViewController()
            controller.account = self.defaultAccount()
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }

    func pushAccountSettings() -> ImmuTableActionType {
        return { [unowned self] row in
            WPAppAnalytics.track(.OpenedAccountSettings)
            let controller = SettingsViewController()
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }

    func pushNotificationSettings() -> ImmuTableActionType {
        return { [unowned self] row in
            let controller = NotificationSettingsViewController()
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }

    func pushHelp() -> ImmuTableActionType {
        return { [unowned self] row in
            let controller = SupportViewController()
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }

    func pushAbout() -> ImmuTableActionType {
        return { [unowned self] row in
            let controller = AboutViewController()
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }

    func presentLogin() -> ImmuTableActionType {
        return { [unowned self] row in
            let controller = LoginViewController()
            controller.onlyDotComAllowed = true
            controller.cancellable = true
            controller.dismissBlock = { [unowned self] _ in
                self.dismissViewControllerAnimated(true, completion: nil)
            }

            let navigation = UINavigationController(rootViewController: controller)
            self.presentViewController(navigation, animated: true, completion: nil)
        }
    }

    func confirmLogout() -> ImmuTableActionType {
        return { [unowned self] row in
            let format = NSLocalizedString("Disconnecting your account will remove all of @%@’s WordPress.com data from this device.", comment: "Label for disconnecting WordPress.com account. The %@ is a placeholder for the user's screen name.")
            let title = String(format: format, self.defaultAccount()!.username)
            let alert = UIAlertController(title: title, message: nil, preferredStyle: .Alert)

            let cancel = UIAlertAction(
                title: NSLocalizedString("Cancel", comment: ""),
                style: .Cancel,
                handler: nil)
            let disconnect = UIAlertAction(
                title: NSLocalizedString("Disconnect", comment: "Button for confirming disconnecting WordPress.com account"),
                style: .Destructive,
                handler: { [unowned self] _ in
                self.logOut()
            })

            alert.addAction(cancel)
            alert.addAction(disconnect)

            self.presentViewController(alert, animated: true, completion: nil)
            self.tableView.deselectSelectedRowWithAnimation(true)
        }
    }

    // MARK: - Notification observers

    func refreshModelWithNotification(notification: NSNotification) {
        // Regenerate the header view if the account has changed
        cachedHeaderView = MeHeaderView()

        reloadViewModel()
    }

    // MARK: - Helpers

    // FIXME: (@koke 2015-12-17) Not cool. Let's stop passing managed objects
    // and initializing stuff with safer values like userID
    func defaultAccount() -> WPAccount? {
        let context = ContextManager.sharedInstance().mainContext
        let service = AccountService(managedObjectContext: context)
        let account = service.defaultWordPressComAccount()
        // Again, ! isn't cool, but let's keep it for now until we refactor the VC
        // initialization parameters.
        return account
    }

    func refreshAccountDetails() {
        guard let account = defaultAccount() else { return }
        let context = ContextManager.sharedInstance().mainContext
        let service = AccountService(managedObjectContext: context)
        service.updateUserDetailsForAccount(account, success: { [weak self] in
            self?.reloadViewModel()
            }, failure: { _ in })
    }

    func logOut() {
        let context = ContextManager.sharedInstance().mainContext
        let service = AccountService(managedObjectContext: context)
        service.removeDefaultWordPressComAccount()
    }

    lazy var cachedHeaderView = MeHeaderView()
}
