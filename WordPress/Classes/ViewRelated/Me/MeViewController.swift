import UIKit
import WordPressShared
import WordPressComAnalytics
import Gridicons

class MeViewController: UITableViewController, UIViewControllerRestoration {
    static let restorationIdentifier = "WPMeRestorationID"
    var handler: ImmuTableViewHandler!

    static func viewController(withRestorationIdentifierPath identifierComponents: [Any], coder: NSCoder) -> UIViewController? {
        return WPTabBarController.sharedInstance().meViewController
    }

    // MARK: - Table View Controller

    override init(style: UITableViewStyle) {
        super.init(style: style)
        navigationItem.title = NSLocalizedString("Me", comment: "Me page title")
        // Need to use `super` to work around a Swift compiler bug
        // https://bugs.swift.org/browse/SR-3465
        super.restorationIdentifier = MeViewController.restorationIdentifier
        restorationClass = type(of: self)
        clearsSelectionOnViewWillAppear = false
    }

    required convenience init() {
        self.init(style: .grouped)
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(MeViewController.refreshModelWithNotification(_:)), name: NSNotification.Name.HelpshiftUnreadCountUpdated, object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Preventing MultiTouch Scenarios
        view.isExclusiveTouch = true

        ImmuTable.registerRows([
            NavigationItemRow.self,
            BadgeNavigationItemRow.self,
            ButtonRow.self,
            DestructiveButtonRow.self
            ], tableView: self.tableView)

        handler = ImmuTableViewHandler(takeOver: self)
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44

        NotificationCenter.default.addObserver(self, selector: #selector(MeViewController.accountDidChange), name: NSNotification.Name.WPAccountDefaultWordPressComAccountChanged, object: nil)

        refreshAccountDetails()

        WPStyleGuide.configureColors(for: view, andTableView: tableView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        HelpshiftUtils.refreshUnreadNotificationCount()

        if splitViewControllerIsHorizontallyCompact {
            animateDeselectionInteractively()
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // Required to update the tableview cell disclosure indicators
        reloadViewModel()
    }

    @objc fileprivate func accountDidChange() {
        reloadViewModel()

        // Reload the detail pane if the split view isn't compact
        if let splitViewController = splitViewController as? WPSplitViewController,
            let detailViewController = initialDetailViewControllerForSplitView(splitViewController), !splitViewControllerIsHorizontallyCompact {
            showDetailViewController(detailViewController, sender: self)
        }
    }

    @objc fileprivate func reloadViewModel() {
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
        let selectedIndexPath = tableView.indexPathForSelectedRow ?? IndexPath(row: 0, section: 0)

        // Then we'll reload the table view model (prompting a table reload)
        handler.viewModel = tableViewModel(loggedIn, helpshiftBadgeCount: badgeCount)

        if !splitViewControllerIsHorizontallyCompact {
            // And finally we'll reselect the selected row, if there is one
            tableView.selectRow(at: selectedIndexPath, animated: false, scrollPosition: .none)
        }
    }

    fileprivate func headerViewForAccount(_ account: WPAccount) -> MeHeaderView {
        headerView.displayName = account.displayName
        headerView.username = account.username
        headerView.gravatarEmail = account.email

        return headerView
    }

    fileprivate func tableViewModel(_ loggedIn: Bool, helpshiftBadgeCount: Int) -> ImmuTable {
        let accessoryType: UITableViewCellAccessoryType = (splitViewControllerIsHorizontallyCompact) ? .disclosureIndicator : .none

        let myProfile = NavigationItemRow(
            title: NSLocalizedString("My Profile", comment: "Link to My Profile section"),
            icon: Gridicon.iconOfType(.user),
            accessoryType: accessoryType,
            action: pushMyProfile())

        let accountSettings = NavigationItemRow(
            title: NSLocalizedString("Account Settings", comment: "Link to Account Settings section"),
            icon: Gridicon.iconOfType(.cog),
            accessoryType: accessoryType,
            action: pushAccountSettings())

        let appSettings = NavigationItemRow(
            title: NSLocalizedString("App Settings", comment: "Link to App Settings section"),
            icon: Gridicon.iconOfType(.phone),
            accessoryType: accessoryType,
            action: pushAppSettings(),
            accessibilityIdentifier: "appSettingsButton")

        let notificationSettings = NavigationItemRow(
            title: NSLocalizedString("Notification Settings", comment: "Link to Notification Settings section"),
            icon: Gridicon.iconOfType(.bell),
            accessoryType: accessoryType,
            action: pushNotificationSettings())

        let helpAndSupport = BadgeNavigationItemRow(
            title: NSLocalizedString("Help & Support", comment: "Link to Help section"),
            icon: Gridicon.iconOfType(.help),
            badgeCount: helpshiftBadgeCount,
            accessoryType: accessoryType,
            action: pushHelp())

        let logIn = ButtonRow(
            title: NSLocalizedString("Log In", comment: "Label for logging in to WordPress.com account"),
            action: presentLogin())

        let logOut = DestructiveButtonRow(
            title: NSLocalizedString("Log Out", comment: "Label for logging out from WordPress.com account"),
            action: confirmLogout(),
            accessibilityIdentifier: "logOutFromWPcomButton")

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

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let isNewSelection = (indexPath != tableView.indexPathForSelectedRow)

        if isNewSelection {
            return indexPath
        } else {
            return nil
        }
    }

    // MARK: - Actions

    fileprivate func presentGravatarPicker() {
        WPAppAnalytics.track(.gravatarTapped)

        let pickerViewController = GravatarPickerViewController()
        pickerViewController.onCompletion = { [weak self] image in
            if let updatedGravatarImage = image {
                self?.uploadGravatarImage(updatedGravatarImage)
            }

            self?.dismiss(animated: true, completion: nil)
        }
        pickerViewController.modalPresentationStyle = .formSheet
        present(pickerViewController, animated: true, completion: nil)
    }

    fileprivate var myProfileViewController: UIViewController? {
        guard let account = self.defaultAccount() else {
            let error = "Tried to push My Profile without a default account. This shouldn't happen"
            assertionFailure(error)
            DDLogSwift.logError(error)
            return nil
        }

        return MyProfileViewController(account: account)
    }

    fileprivate func pushMyProfile() -> ImmuTableAction {
        return { [unowned self] row in
            if let myProfileViewController = self.myProfileViewController {
                WPAppAnalytics.track(.openedMyProfile)
                self.showDetailViewController(myProfileViewController, sender: self)
            }
        }
    }

    fileprivate func pushAccountSettings() -> ImmuTableAction {
        return { [unowned self] row in
            if let account = self.defaultAccount() {
                WPAppAnalytics.track(.openedAccountSettings)
                guard let controller = AccountSettingsViewController(account: account) else {
                    return
                }

                self.showDetailViewController(controller, sender: self)
            }
        }
    }

    func pushAppSettings() -> ImmuTableAction {
        return { [unowned self] row in
            WPAppAnalytics.track(.openedAppSettings)
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

    fileprivate func presentLogin() -> ImmuTableAction {
        return { [unowned self] row in
            self.tableView.deselectSelectedRowWithAnimation(true)
            SigninHelpers.showSigninForJustWPComFromPresenter(self)
        }
    }

    fileprivate func confirmLogout() -> ImmuTableAction {
        return { [unowned self] row in
            let format = NSLocalizedString("Disconnecting your account will remove all of @%@’s WordPress.com data from this device.", comment: "Label for disconnecting WordPress.com account. The %@ is a placeholder for the user's screen name.")
            let title = String(format: format, self.defaultAccount()!.username)
            let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)

            let cancel = UIAlertAction(
                title: NSLocalizedString("Cancel", comment: ""),
                style: .cancel,
                handler: nil)
            let disconnect = UIAlertAction(
                title: NSLocalizedString("Disconnect", comment: "Button for confirming disconnecting WordPress.com account"),
                style: .destructive,
                handler: { [unowned self] _ in
                self.logOut()
            })

            alert.addAction(cancel)
            alert.addAction(disconnect)

            self.present(alert, animated: true, completion: nil)
            self.tableView.deselectSelectedRowWithAnimation(true)
        }
    }


    // MARK: - Notification observers

    func refreshModelWithNotification(_ notification: Foundation.Notification) {
        reloadViewModel()
    }


    // MARK: - Gravatar Helpers

    fileprivate func uploadGravatarImage(_ newGravatar: UIImage) {
        WPAppAnalytics.track(.gravatarUploaded)

        gravatarUploadInProgress = true
        headerView.overrideGravatarImage(newGravatar)

        let service = GravatarService(context: ContextManager.sharedInstance().mainContext)
        service?.uploadImage(newGravatar) { [weak self] error in
            DispatchQueue.main.async(execute: {
                self?.gravatarUploadInProgress = false
                self?.reloadViewModel()
            })
        }
    }

    // MARK: - Helpers

    // FIXME: (@koke 2015-12-17) Not cool. Let's stop passing managed objects
    // and initializing stuff with safer values like userID
    fileprivate func defaultAccount() -> WPAccount? {
        let context = ContextManager.sharedInstance().mainContext
        let service = AccountService(managedObjectContext: context)
        let account = service.defaultWordPressComAccount()
        // Again, ! isn't cool, but let's keep it for now until we refactor the VC
        // initialization parameters.
        return account
    }

    fileprivate func refreshAccountDetails() {
        guard let account = defaultAccount() else { return }
        let context = ContextManager.sharedInstance().mainContext
        let service = AccountService(managedObjectContext: context)
        service.updateUserDetails(for: account, success: { _ in }, failure: { _ in })
    }

    fileprivate func logOut() {
        let context = ContextManager.sharedInstance().mainContext
        let service = AccountService(managedObjectContext: context)
        service.removeDefaultWordPressComAccount()
    }

    // MARK: - Private Properties
    fileprivate var gravatarUploadInProgress = false {
        didSet {
            headerView.showsActivityIndicator = gravatarUploadInProgress
            headerView.isUserInteractionEnabled = !gravatarUploadInProgress
        }
    }

    fileprivate lazy var headerView: MeHeaderView = {
        let headerView = MeHeaderView()
        headerView.onGravatarPress = { [weak self] in
            self?.presentGravatarPicker()
        }
        return headerView
    }()
}

extension MeViewController: WPSplitViewControllerDetailProvider {
    func initialDetailViewControllerForSplitView(_ splitView: WPSplitViewController) -> UIViewController? {
        // If we're not logged in yet, return app settings
        guard let _ = defaultAccount() else {
            return AppSettingsViewController()
        }

        return myProfileViewController
    }
}
