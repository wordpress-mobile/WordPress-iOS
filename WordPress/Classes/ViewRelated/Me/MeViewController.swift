import UIKit
import WordPressShared
import WordPressComAnalytics
import Gridicons

class MeViewController: UITableViewController, UIViewControllerRestoration {
    static let restorationIdentifier = "WPMeRestorationID"

    private static let preferredFiltersPopoverContentSize = CGSize(width: 320.0, height: 220.0)

    var accountsButton : NavBarTitleDropdownButton!
    var handler: ImmuTableViewHandler!
    var accountHelper: AccountSelectionHelper?

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

        self.accountsButton = NavBarTitleDropdownButton.init(frame: CGRectMake(0, 0, 300, 44))
        self.accountsButton.addTarget(self, action: #selector(MeViewController.didTapMeButton(_:)), forControlEvents: .TouchUpInside)
        self.navigationItem.titleView = self.accountsButton

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
        self.retrieveAccounts { (accounts: [Account]) in
            self.accountHelper?.accounts = accounts
        }
    }

    @IBAction func didTapMeButton(sender: AnyObject) {
        displayAccounts()
    }

    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // Required to update the tableview cell disclosure indicators
        reloadViewModel()
    }

    func switchAccountHelper() -> AccountSelectionHelper {
        var navBarHeight = self.navigationController?.navigationBar.frame.size.height
        if (navBarHeight == nil) {
            navBarHeight = 44
        }
        let accountHelper = AccountSelectionHelper(parentView: self.view,
                                                   accounts: [],
                                                   delegate: self,
                                                   height: navBarHeight!)

        accountHelper.delegate = self

        self.retrieveAccounts { (accounts: [Account]) in
            self.accountHelper?.accounts = accounts
        }

        return accountHelper
    }

    @objc private func accountDidChange(notification: NSNotification) {
        reloadViewModel()

        self.retrieveAccounts { (accounts: [Account]) in
            self.accountHelper?.accounts = accounts
        }

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

    func tableViewModel(loggedIn: Bool, helpshiftBadgeCount: Int) -> ImmuTable {
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

        let addAccount = ButtonRow(
            title:  NSLocalizedString("Add WP Account", comment: "Add account for WordPress.com"),
            action: addWPAccount())

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
                            addAccount,
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

    private func addWPAccount() -> ImmuTableAction {
        return { [unowned self] row in
            let signInWPComViewController = SigninWPComViewController.controller(LoginFields(), immediateSignin: false)
            signInWPComViewController.restrictSigninToWPCom = true
            let navController = NUXNavigationController(rootViewController: signInWPComViewController)
            self.presentViewController(navController, animated: true, completion: nil)
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

    // MARK: - Public for testing purposes

    func retrieveAccounts(completion: ([Account]) -> Void) {
        let context = ContextManager.sharedInstance().mainContext
        let service = AccountService(managedObjectContext: context)
        service.retrieveAllAccountsWith { ( accounts: [AnyObject] ) in

            let accountsParsed = accounts as! [WPAccount]
            var accountsCompleted: [Account] = []
            for account in accountsParsed {

                let accountStruct = Account.init(userId: account.userID,
                                                 username: account.username,
                                                 email: account.email)
                accountsCompleted.append(accountStruct)
            }

            completion(accountsCompleted)
        }
    }

    func logOut() {
        let accountService = AccountServiceFacade()
        accountService.removeAndReplaceWPAccountIfAvailable()
    }

    // MARK: - NavTitle

    func displayAccounts() {

        self.retrieveAccounts({ (retrievedAccounts: [Account]) in
            let titles = retrievedAccounts.map({ (account: Account) -> String in
                return account.username
            })

            let dict: [NSObject : AnyObject] = [SettingsSelectionDefaultValueKey: retrievedAccounts.first!,
                SettingsSelectionTitleKey: NSLocalizedString("Me", comment: "Title of the list of logged users"),
                SettingsSelectionTitlesKey: titles as [String],
                SettingsSelectionValuesKey: retrievedAccounts as [Account],
                SettingsSelectionCurrentValueKey: retrievedAccounts.first!]

            let controller = SettingsSelectionViewController(style: .Plain, andDictionary: dict as [NSObject : AnyObject])
            controller.onItemSelected = { [weak self] (selectedValue: AnyObject!) -> () in
                if let strongSelf = self
                    /*, let index = strongSelf.filterSettings.availablePostListFilters().indexOf(selectedValue as! PostListFilter) */
                 {
                    /*
                    strongSelf.filterSettings.setCurrentFilterIndex(index)
                    strongSelf.dismissViewControllerAnimated(true, completion: nil)

                    strongSelf.refreshAndReload()
                    strongSelf.syncItemsWithUserInteraction(false)*/
                }
            }

            controller.tableView.scrollEnabled = false

            self.displayAccountPopover(controller)
        })
    }

    func displayAccountPopover(controller: UIViewController) {
        //controller.preferredContentSize = self.dynamicType.preferredFiltersPopoverContentSize

        guard let titleView = navigationItem.titleView else {
            return
        }

        ForcePopoverPresenter.configurePresentationControllerForViewController(controller, presentingFromView: titleView)

        presentViewController(controller, animated: true, completion: nil)
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

extension MeViewController: AccountSelectionHelperDelegate {
    func selectedAccount(account: Account) {
        let context = ContextManager.sharedInstance().mainContext
        let service = AccountService(managedObjectContext: context)
        guard let selectedAccount = service.findAccountWithUserID(account.userId) else { return }
        service.setDefaultWordPressComAccount(selectedAccount)
    }
}
