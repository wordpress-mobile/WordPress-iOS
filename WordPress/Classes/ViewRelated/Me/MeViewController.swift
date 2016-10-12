import UIKit
import WordPressShared
import WordPressComAnalytics
import Gridicons

class MeViewController: UITableViewController, UIViewControllerRestoration {
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

        // Preventing MultiTouch Scenarios
        view.exclusiveTouch = true

        ImmuTable.registerRows([
            NavigationItemRow.self,
            BadgeNavigationItemRow.self,
            ButtonRow.self,
            DestructiveButtonRow.self
            ], tableView: self.tableView)

        handler = ImmuTableViewHandler(takeOver: self)
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MeViewController.accountDidChange), name: WPAccountDefaultWordPressComAccountChangedNotification, object: nil)

        refreshAccountDetails()

        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        HelpshiftUtils.refreshUnreadNotificationCount()

        if splitViewControllerIsHorizontallyCompact {
            animateDeselectionInteractively()
        }
    }

    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // Required to update the tableview cell disclosure indicators
        reloadViewModel()
    }

    @objc private func accountDidChange() {
        reloadViewModel()

        // Reload the detail pane if the split view isn't compact
        if let splitViewController = splitViewController as? WPSplitViewController,
            let detailViewController = initialDetailViewControllerForSplitView(splitViewController) where !splitViewControllerIsHorizontallyCompact {
            showDetailViewController(detailViewController, sender: self)
        }
    }

    @objc private func reloadViewModel() {
        let account = defaultAccount()
        let loggedIn = account != nil
        let badgeCount = HelpshiftUtils.isHelpshiftEnabled() ? HelpshiftUtils.unreadNotificationCount() : 0

        // Warning: If you set the header view after the table model, the
        // table's top margin will be wrong.
        //
        // My guess is the table view adjusts the height of the first section
        // based on if there's a header or not.
        tableView.tableHeaderView = account.map { headerViewForAccount($0) }

        // After we've reloaded the view model we should maintain the current
        // table row selection, or if the split view we're in is not compact
        // then we'll just select the first item in the table.

        // First, we'll grab the appropriate index path so we can reselect it
        // after reloading the table
        let selectedIndexPath = tableView.indexPathForSelectedRow ?? NSIndexPath(forRow: 0, inSection: 0)

        // Then we'll reload the table view model (prompting a table reload)
        handler.viewModel = tableViewModel(loggedIn, helpshiftBadgeCount: badgeCount)

        if !splitViewControllerIsHorizontallyCompact {
            // And finally we'll reselect the selected row, if there is one
            tableView.selectRowAtIndexPath(selectedIndexPath, animated: false, scrollPosition: .None)
        }
    }

    private func headerViewForAccount(account: WPAccount) -> MeHeaderView {
        headerView.displayName = account.displayName
        headerView.username = account.username
        headerView.gravatarEmail = account.email

        return headerView
    }

    private func tableViewModel(loggedIn: Bool, helpshiftBadgeCount: Int) -> ImmuTable {
        let accessoryType: UITableViewCellAccessoryType = (splitViewControllerIsHorizontallyCompact) ? .DisclosureIndicator : .None

        let myProfile = NavigationItemRow(
            title: NSLocalizedString("My Profile", comment: "Link to My Profile section"),
            icon: Gridicon.iconOfType(.User),
            accessoryType: accessoryType,
            action: pushMyProfile())

        let accountSettings = NavigationItemRow(
            title: NSLocalizedString("Account Settings", comment: "Link to Account Settings section"),
            icon: Gridicon.iconOfType(.Cog),
            accessoryType: accessoryType,
            action: pushAccountSettings())

        let appSettings = NavigationItemRow(
            title: NSLocalizedString("App Settings", comment: "Link to App Settings section"),
            icon: Gridicon.iconOfType(.Phone),
            accessoryType: accessoryType,
            action: pushAppSettings())

        let notificationSettings = NavigationItemRow(
            title: NSLocalizedString("Notification Settings", comment: "Link to Notification Settings section"),
            icon: Gridicon.iconOfType(.Bell),
            accessoryType: accessoryType,
            action: pushNotificationSettings())

        let helpAndSupport = BadgeNavigationItemRow(
            title: NSLocalizedString("Help & Support", comment: "Link to Help section"),
            icon: Gridicon.iconOfType(.Help),
            badgeCount: helpshiftBadgeCount,
            accessoryType: accessoryType,
            action: pushHelp())

        let logIn = ButtonRow(
            title: NSLocalizedString("Connect to WordPress.com", comment: "Label for connecting to WordPress.com account"),
            action: presentLogin())

        let logOut = DestructiveButtonRow(
            title: NSLocalizedString("Disconnect from WordPress.com", comment: "Label for disconnecting from WordPress.com account"),
            action: confirmLogout())

        let wordPressComAccount = NSLocalizedString("WordPress.com Account", comment: "WordPress.com sign-in/sign-out section header title")

        if loggedIn {
            return ImmuTable(
                sections: [
                    ImmuTableSection(rows: [
                        myProfile,
                        accountSettings,
                        appSettings,
                        notificationSettings
                        ]),
                    ImmuTableSection(rows: [
                        helpAndSupport
                        ]),
                    ImmuTableSection(
                        headerText: wordPressComAccount,
                        rows: [
                            logOut
                        ])
                ])
        } else { // Logged out
            return ImmuTable(
                sections: [
                    ImmuTableSection(rows: [
                        appSettings,
                        ]),
                    ImmuTableSection(rows: [
                        helpAndSupport
                        ]),
                    ImmuTableSection(
                        headerText: wordPressComAccount,
                        rows: [
                            logIn
                        ])
                ])
        }
    }

    // MARK: - UITableViewDelegate

    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        let isNewSelection = (indexPath != tableView.indexPathForSelectedRow)

        if isNewSelection {
            return indexPath
        } else {
            return nil
        }
    }

    // MARK: - Actions

    private func presentGravatarPicker() {
        WPAppAnalytics.track(.GravatarTapped)

        let pickerViewController = GravatarPickerViewController()
        pickerViewController.onCompletion = { [weak self] image in
            if let updatedGravatarImage = image {
                self?.uploadGravatarImage(updatedGravatarImage)
            }

            self?.dismissViewControllerAnimated(true, completion: nil)
        }
        pickerViewController.modalPresentationStyle = .FormSheet
        presentViewController(pickerViewController, animated: true, completion: nil)
    }

    private var myProfileViewController: UIViewController? {
        guard let account = self.defaultAccount() else {
            let error = "Tried to push My Profile without a default account. This shouldn't happen"
            assertionFailure(error)
            DDLogSwift.logError(error)
            return nil
        }

        return MyProfileViewController(account: account)
    }

    private func pushMyProfile() -> ImmuTableAction {
        return { [unowned self] row in
            if let myProfileViewController = self.myProfileViewController {
                WPAppAnalytics.track(.OpenedMyProfile)
                self.showDetailViewController(myProfileViewController, sender: self)
            }
        }
    }

    private func pushAccountSettings() -> ImmuTableAction {
        return { [unowned self] row in
            if let account = self.defaultAccount() {
                WPAppAnalytics.track(.OpenedAccountSettings)
                guard let controller = AccountSettingsViewController(account: account) else {
                    return
                }

                self.showDetailViewController(controller, sender: self)
            }
        }
    }

    func pushAppSettings() -> ImmuTableAction {
        return { [unowned self] row in
            WPAppAnalytics.track(.OpenedAppSettings)
            let controller = AppSettingsViewController()
            self.showDetailViewController(controller, sender: self)
        }
    }

    func pushNotificationSettings() -> ImmuTableAction {
        return { [unowned self] row in
            let controller = NotificationSettingsViewController()
            self.showDetailViewController(controller, sender: self)
        }
    }

    func pushHelp() -> ImmuTableAction {
        return { [unowned self] row in
            let controller = SupportViewController()
            self.showDetailViewController(controller, sender: self)
        }
    }

    private func presentLogin() -> ImmuTableAction {
        return { [unowned self] row in
            self.tableView.deselectSelectedRowWithAnimation(true)
            SigninHelpers.showSigninForJustWPComFromPresenter(self)
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


    // MARK: - Notification observers

    func refreshModelWithNotification(notification: NSNotification) {
        reloadViewModel()
    }


    // MARK: - Gravatar Helpers

    private func uploadGravatarImage(newGravatar: UIImage) {
        WPAppAnalytics.track(.GravatarUploaded)

        gravatarUploadInProgress = true
        headerView.overrideGravatarImage(newGravatar)

        let service = GravatarService(context: ContextManager.sharedInstance().mainContext)
        service?.uploadImage(newGravatar) { [weak self] error in
            dispatch_async(dispatch_get_main_queue(), {
                self?.gravatarUploadInProgress = false
                self?.reloadViewModel()
            })
        }
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
    private var gravatarUploadInProgress = false {
        didSet {
            headerView.showsActivityIndicator = gravatarUploadInProgress
            headerView.userInteractionEnabled = !gravatarUploadInProgress
        }
    }

    private lazy var headerView : MeHeaderView = {
        let headerView = MeHeaderView()
        headerView.onGravatarPress = { [weak self] in
            self?.presentGravatarPicker()
        }
        return headerView
    }()
}

extension MeViewController: WPSplitViewControllerDetailProvider {
    func initialDetailViewControllerForSplitView(splitView: WPSplitViewController) -> UIViewController? {
        // If we're not logged in yet, return app settings
        guard let _ = defaultAccount() else {
            return AppSettingsViewController()
        }

        return myProfileViewController
    }
}
