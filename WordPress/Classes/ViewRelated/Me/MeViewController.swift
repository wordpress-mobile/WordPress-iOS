import UIKit
import CocoaLumberjack
import WordPressShared
import Gridicons
import WordPressAuthenticator


class MeViewController: UITableViewController, UIViewControllerRestoration {
    @objc static let restorationIdentifier = "WPMeRestorationID"
    @objc var handler: ImmuTableViewHandler!

    static func viewController(withRestorationIdentifierPath identifierComponents: [String],
                               coder: NSCoder) -> UIViewController? {
        return WPTabBarController.sharedInstance().meViewController
    }

    // MARK: - Table View Controller

    override init(style: UITableView.Style) {
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
        notificationCenter.addObserver(self, selector: #selector(refreshModelWithNotification(_:)), name: .ZendeskPushNotificationReceivedNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(refreshModelWithNotification(_:)), name: .ZendeskPushNotificationClearedNotification, object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Preventing MultiTouch Scenarios
        view.isExclusiveTouch = true

        ImmuTable.registerRows([
            NavigationItemRow.self,
            IndicatorNavigationItemRow.self,
            ButtonRow.self,
            DestructiveButtonRow.self
            ], tableView: self.tableView)

        handler = ImmuTableViewHandler(takeOver: self)
        WPStyleGuide.configureAutomaticHeightRows(for: tableView)

        NotificationCenter.default.addObserver(self, selector: #selector(MeViewController.accountDidChange), name: NSNotification.Name.WPAccountDefaultWordPressComAccountChanged, object: nil)

        WPStyleGuide.configureColors(view: view, tableView: tableView)
        tableView.accessibilityIdentifier = "Me Table"
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.layoutHeaderView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        refreshAccountDetails()

        if splitViewControllerIsHorizontallyCompact {
            animateDeselectionInteractively()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        registerUserActivity()
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
        handler.viewModel = tableViewModel(loggedIn)

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

    private var appSettingsRow: NavigationItemRow {
        let accessoryType: UITableViewCell.AccessoryType = (splitViewControllerIsHorizontallyCompact) ? .disclosureIndicator : .none

        return NavigationItemRow(
            title: RowTitles.appSettings,
            icon: Gridicon.iconOfType(.phone),
            accessoryType: accessoryType,
            action: pushAppSettings(),
            accessibilityIdentifier: "appSettings")
    }

    fileprivate func tableViewModel(_ loggedIn: Bool) -> ImmuTable {
        let accessoryType: UITableViewCell.AccessoryType = (splitViewControllerIsHorizontallyCompact) ? .disclosureIndicator : .none

        let myProfile = NavigationItemRow(
            title: RowTitles.myProfile,
            icon: Gridicon.iconOfType(.user),
            accessoryType: accessoryType,
            action: pushMyProfile(),
            accessibilityIdentifier: "myProfile")

        let accountSettings = NavigationItemRow(
            title: RowTitles.accountSettings,
            icon: Gridicon.iconOfType(.cog),
            accessoryType: accessoryType,
            action: pushAccountSettings(),
            accessibilityIdentifier: "accountSettings")

        let helpAndSupportIndicator = IndicatorNavigationItemRow(
            title: RowTitles.support,
            icon: Gridicon.iconOfType(.help),
            showIndicator: ZendeskUtils.showSupportNotificationIndicator,
            accessoryType: accessoryType,
            action: pushHelp())

        let logIn = ButtonRow(
            title: RowTitles.logIn,
            action: presentLogin())

        let logOut = DestructiveButtonRow(
            title: RowTitles.logOut,
            action: logoutRowWasPressed(),
            accessibilityIdentifier: "logOutFromWPcomButton")

        let wordPressComAccount = HeaderTitles.wpAccount

        if loggedIn {
            return ImmuTable(
                sections: [
                    ImmuTableSection(rows: [
                        myProfile,
                        accountSettings,
                        appSettingsRow
                        ],
                         footerText: NSLocalizedString("Notification settings can now be found in the Notifications tab", comment: "Instruction informing the user where notification settings can be found.")),
                    ImmuTableSection(rows: [helpAndSupportIndicator]),
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
                        appSettingsRow,
                        ]),
                    ImmuTableSection(rows: [helpAndSupportIndicator]),
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

    fileprivate var myProfileViewController: UIViewController? {
        guard let account = self.defaultAccount() else {
            let error = "Tried to push My Profile without a default account. This shouldn't happen"
            assertionFailure(error)
            DDLogError(error)
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

    func pushHelp() -> ImmuTableAction {
        return { [unowned self] row in
            let controller = SupportTableViewController()

            // If iPad, show Support from Me view controller instead of navigation controller.
            if !self.splitViewControllerIsHorizontallyCompact {
                controller.showHelpFromViewController = self
            }

            self.showDetailViewController(controller, sender: self)
        }
    }

    fileprivate func presentLogin() -> ImmuTableAction {
        return { [unowned self] row in
            self.tableView.deselectSelectedRowWithAnimation(true)
            self.promptForLoginOrSignup()
        }
    }

    fileprivate func logoutRowWasPressed() -> ImmuTableAction {
        return { [unowned self] row in
            self.tableView.deselectSelectedRowWithAnimation(true)
            self.displayLogOutAlert()
        }
    }

    /// Selects the My Profile row and pushes the Support view controller
    ///
    @objc public func navigateToMyProfile() {
        navigateToTarget(for: RowTitles.myProfile)
    }

    /// Selects the Account Settings row and pushes the Account Settings view controller
    ///
    @objc public func navigateToAccountSettings() {
        navigateToTarget(for: RowTitles.accountSettings)
    }

    /// Selects the App Settings row and pushes the App Settings view controller
    ///
    @objc public func navigateToAppSettings() {
        navigateToTarget(for: appSettingsRow.title)
    }

    /// Selects the Help & Support row and pushes the Support view controller
    ///
    @objc public func navigateToHelpAndSupport() {
        navigateToTarget(for: RowTitles.support)
    }

    fileprivate func navigateToTarget(for rowTitle: String) {
        let matchRow: ((ImmuTableRow) -> Bool) = { row in
            if let row = row as? NavigationItemRow {
                return row.title == rowTitle
            } else if let row = row as? IndicatorNavigationItemRow {
                return row.title == rowTitle
            }
            return false
        }

        let sections = handler.viewModel.sections

        if let section = sections.index(where: { $0.rows.contains(where: matchRow) }),
            let row = sections[section].rows.index(where: matchRow) {
            let indexPath = IndexPath(row: row, section: section)

            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .middle)
            handler.tableView(self.tableView, didSelectRowAt: indexPath)
        }
    }

    // MARK: - Helpers

    // FIXME: (@koke 2015-12-17) Not cool. Let's stop passing managed objects
    // and initializing stuff with safer values like userID
    fileprivate func defaultAccount() -> WPAccount? {
        let context = ContextManager.sharedInstance().mainContext
        let service = AccountService(managedObjectContext: context)
        let account = service.defaultWordPressComAccount()
        return account
    }

    fileprivate func refreshAccountDetails() {
        guard let account = defaultAccount() else {
            reloadViewModel()
            return
        }

        let context = ContextManager.sharedInstance().mainContext
        let service = AccountService(managedObjectContext: context)
        service.updateUserDetails(for: account, success: { [weak self] in
            self?.reloadViewModel()
            }, failure: { error in
                DDLogError(error.localizedDescription)
        })
    }

    // MARK: - LogOut

    private func displayLogOutAlert() {
        let alert  = UIAlertController(title: logOutAlertTitle, message: nil, preferredStyle: .alert)
        alert.addActionWithTitle(LogoutAlert.cancelAction, style: .cancel)
        alert.addActionWithTitle(LogoutAlert.logoutAction, style: .destructive) { _ in
            AccountHelper.logOutDefaultWordPressComAccount()
        }

        present(alert, animated: true)
    }

    private var logOutAlertTitle: String {
        let context = ContextManager.sharedInstance().mainContext
        let service = PostService(managedObjectContext: context)
        let count = service.countPostsWithoutRemote()

        guard count > 0 else {
            return LogoutAlert.defaultTitle
        }

        let format = count > 1 ? LogoutAlert.unsavedTitlePlural : LogoutAlert.unsavedTitleSingular
        return String(format: format, count)
    }

    // MARK: - Private Properties

    fileprivate lazy var headerView: MeHeaderView = {
        let headerView = MeHeaderView()
        headerView.onGravatarPress = { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.presentGravatarPicker(from: strongSelf)
        }
        headerView.onDroppedImage = { [weak self] image in
            let imageCropViewController = ImageCropViewController(image: image)
            imageCropViewController.maskShape = .square
            imageCropViewController.shouldShowCancelButton = true

            imageCropViewController.onCancel = { [weak self] in
                self?.dismiss(animated: true)
                self?.updateGravatarStatus(.idle)
            }
            imageCropViewController.onCompletion = { [weak self] image, _ in
                self?.dismiss(animated: true)
                self?.uploadGravatarImage(image)
            }

            let navController = UINavigationController(rootViewController: imageCropViewController)
            navController.modalPresentationStyle = .formSheet
            self?.present(navController, animated: true)
        }
        return headerView
    }()

    /// Shows an actionsheet with options to Log In or Create a WordPress site.
    /// This is a temporary stop-gap measure to preserve for users only logged
    /// into a self-hosted site the ability to create a WordPress.com account.
    ///
    fileprivate func promptForLoginOrSignup() {
        WordPressAuthenticator.showLogin(from: self, animated: true, showCancel: true, restrictToWPCom: true)
    }
}

// MARK: - WPSplitViewControllerDetailProvider Conformance

extension MeViewController: WPSplitViewControllerDetailProvider {
    func initialDetailViewControllerForSplitView(_ splitView: WPSplitViewController) -> UIViewController? {
        // If we're not logged in yet, return app settings
        guard let _ = defaultAccount() else {
            return AppSettingsViewController()
        }

        return myProfileViewController
    }
}

// MARK: - SearchableActivity Conformance

extension MeViewController: SearchableActivityConvertable {
    var activityType: String {
        return WPActivityType.me.rawValue
    }

    var activityTitle: String {
        return NSLocalizedString("Me", comment: "Title of the 'Me' tab - used for spotlight indexing on iOS.")
    }

    var activityKeywords: Set<String>? {
        let keyWordString = NSLocalizedString("wordpress, me, settings, account, notification log out, logout, log in, login, help, support",
                                              comment: "This is a comma separated list of keywords used for spotlight indexing of the 'Me' tab.")
        let keywordArray = keyWordString.arrayOfTags()

        guard !keywordArray.isEmpty else {
            return nil
        }

        return Set(keywordArray)
    }
}

// MARK: - Gravatar uploading
//
extension MeViewController: GravatarUploader {
    /// Update the UI based on the status of the gravatar upload
    func updateGravatarStatus(_ status: GravatarUploaderStatus) {
        switch status {
        case .uploading(image: let newGravatarImage):
            headerView.showsActivityIndicator = true
            headerView.isUserInteractionEnabled = false
            headerView.overrideGravatarImage(newGravatarImage)
        case .finished:
            reloadViewModel()
            fallthrough
        default:
            headerView.showsActivityIndicator = false
            headerView.isUserInteractionEnabled = true
        }
    }
}

// MARK: - Constants

private extension MeViewController {
    enum RowTitles {
        static let appSettings = NSLocalizedString("App Settings", comment: "Link to App Settings section")
        static let myProfile = NSLocalizedString("My Profile", comment: "Link to My Profile section")
        static let accountSettings = NSLocalizedString("Account Settings", comment: "Link to Account Settings section")
        static let support = NSLocalizedString("Help & Support", comment: "Link to Help section")
        static let logIn = NSLocalizedString("Log In", comment: "Label for logging in to WordPress.com account")
        static let logOut = NSLocalizedString("Log Out", comment: "Label for logging out from WordPress.com account")
    }

    enum HeaderTitles {
        static let wpAccount = NSLocalizedString("WordPress.com Account", comment: "WordPress.com sign-in/sign-out section header title")
    }

    enum LogoutAlert {
        static let defaultTitle =  NSLocalizedString("Log out of WordPress?", comment: "LogOut confirmation text, whenever there are no local changes")
        static let unsavedTitleSingular = NSLocalizedString("You have changes to %d post that hasn't been uploaded to your site. Logging out now will delete those changes. Log out anyway?",
                                                            comment: "Warning displayed before logging out. The %d placeholder will contain the number of local posts (SINGULAR!)")
        static let unsavedTitlePlural = NSLocalizedString("You have changes to %d posts that haven’t been uploaded to your site. Logging out now will delete those changes. Log out anyway?",
                                                          comment: "Warning displayed before logging out. The %d placeholder will contain the number of local posts (PLURAL!)")
        static let cancelAction = NSLocalizedString("Cancel", comment: "Verb. A button title. Tapping cancels an action.")
        static let logoutAction = NSLocalizedString("Log Out", comment: "Button for confirming logging out from WordPress.com account")
    }
}

// MARK: - Private Extension for Notification handling

private extension MeViewController {

    @objc func refreshModelWithNotification(_ notification: Foundation.Notification) {
        reloadViewModel()
    }
}
