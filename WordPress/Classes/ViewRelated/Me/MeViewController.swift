import UIKit
import WordPressShared
import WPMediaPicker

class MeViewController: UITableViewController, UIViewControllerRestoration, WPMediaPickerViewControllerDelegate {
    static let restorationIdentifier = "WPMeRestorationID"
    var handler: ImmuTableViewHandler!

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
        notificationCenter.addObserver(self, selector: #selector(MeViewController.refreshModelWithNotification(_:)), name: HelpshiftUnreadCountUpdatedNotification, object: nil)
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

        handler = ImmuTableViewHandler(takeOver: self)

        let context = ContextManager.sharedInstance().mainContext
        let service = AccountService(managedObjectContext: context)
        _ = service.defaultAccountChanged
            .takeUntil(rx_deallocated)
            .subscribeNext({ [unowned self] _ in
                self.reloadViewModel()
                })

        refreshAccountDetails()

        WPStyleGuide.resetReadableMarginsForTableView(tableView)
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        HelpshiftUtils.refreshUnreadNotificationCount()
        animateDeselectionInteractively()
    }

    private func reloadViewModel() {
        let account = defaultAccount()
        let loggedIn = account != nil
        let badgeCount = HelpshiftUtils.isHelpshiftEnabled() ? HelpshiftUtils.unreadNotificationCount() : 0

        // Warning: If you set the header view after the table model, the
        // table's top margin will be wrong.
        //
        // My guess is the table view adjusts the height of the first section
        // based on if there's a header or not.
        tableView.tableHeaderView = account.map { headerViewForAccount($0) }
        handler.viewModel = tableViewModel(loggedIn, helpshiftBadgeCount: badgeCount)
    }
    
    private func headerViewForAccount(account: WPAccount) -> MeHeaderView {
        headerView.displayName = account.displayName
        headerView.username = account.username
        headerView.gravatarEmail = account.email

        return headerView
    }

    private func tableViewModel(loggedIn: Bool, helpshiftBadgeCount: Int) -> ImmuTable {
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

    // MARK: - Actions

    private func pushMyProfile() -> ImmuTableAction {
        return { [unowned self] row in
            guard let account = self.defaultAccount() else {
                let error = "Tried to push My Profile without a default account. This shouldn't happen"
                assertionFailure(error)
                DDLogSwift.logError(error)
                return
            }

            WPAppAnalytics.track(.OpenedMyProfile)
            let controller = MyProfileViewController(account: account)
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }

    private func pushAccountSettings() -> ImmuTableAction {
        return { [unowned self] row in
            WPAppAnalytics.track(.OpenedAccountSettings)
            let controller = AccountSettingsViewController(account: self.defaultAccount())
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }

    private func pushNotificationSettings() -> ImmuTableAction {
        return { [unowned self] row in
            let controller = NotificationSettingsViewController()
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }

    private func pushHelp() -> ImmuTableAction {
        return { [unowned self] row in
            let controller = SupportViewController()
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }

    private func pushAbout() -> ImmuTableAction {
        return { [unowned self] row in
            let controller = AboutViewController()
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    private func presentLogin() -> ImmuTableAction {
        return { [unowned self] row in
            let controller = LoginViewController()
            controller.onlyDotComAllowed = true
            controller.cancellable = true
            controller.dismissBlock = { [unowned self] _ in
                self.dismissViewControllerAnimated(true, completion: nil)
            }

            let navigation = RotationAwareNavigationViewController(rootViewController: controller)
            self.presentViewController(navigation, animated: true, completion: nil)
        }
    }

    private func confirmLogout() -> ImmuTableAction {
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
    
    private func presentGravatarPicker() {
        let pickerViewController = WPMediaPickerViewController()
        pickerViewController.delegate = self
        pickerViewController.showMostRecentFirst = true
        pickerViewController.allowMultipleSelection = false
        pickerViewController.filter = .Image
        
        presentViewController(pickerViewController, animated: true, completion: nil)
    }

    // MARK: - Notification observers

    func refreshModelWithNotification(notification: NSNotification) {
        reloadViewModel()
    }

    // MARK: - WPMediaPickerViewControllerDelegate
    
    func mediaPickerController(picker: WPMediaPickerViewController, didFinishPickingAssets assets: [AnyObject]) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func mediaPickerControllerDidCancel(picker: WPMediaPickerViewController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    // MARK: - Helpers

    // FIXME: (@koke 2015-12-17) Not cool. Let's stop passing managed objects
    // and initializing stuff with safer values like userID
    private func defaultAccount() -> WPAccount? {
        let context = ContextManager.sharedInstance().mainContext
        let service = AccountService(managedObjectContext: context)
        let account = service.defaultWordPressComAccount()
        // Again, ! isn't cool, but let's keep it for now until we refactor the VC
        // initialization parameters.
        return account
    }

    private func refreshAccountDetails() {
        guard let account = defaultAccount() else { return }
        let context = ContextManager.sharedInstance().mainContext
        let service = AccountService(managedObjectContext: context)
        service.updateUserDetailsForAccount(account, success: { _ in }, failure: { _ in })
    }

    private func logOut() {
        let context = ContextManager.sharedInstance().mainContext
        let service = AccountService(managedObjectContext: context)
        service.removeDefaultWordPressComAccount()
    }

    // MARK: - Private Properties
    
    private lazy var headerView : MeHeaderView = {
        let headerView = MeHeaderView()
        headerView.onPress = { [weak self] in
            self?.presentGravatarPicker()
        }
        return headerView
    }()
}
