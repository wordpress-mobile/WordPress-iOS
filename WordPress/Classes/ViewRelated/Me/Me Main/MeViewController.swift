import UIKit
import CocoaLumberjack
import WordPressShared
import Gridicons
import WordPressAuthenticator
import AutomatticAbout

class MeViewController: UITableViewController {
    var handler: ImmuTableViewHandler!

    // MARK: - Table View Controller

    override init(style: UITableView.Style) {
        super.init(style: style)
        navigationItem.title = NSLocalizedString("Me", comment: "Me page title")
        clearsSelectionOnViewWillAppear = false
    }

    required convenience init() {
        self.init(style: .insetGrouped)
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

        reloadViewModel()

        extendedLayoutIncludesOpaqueBars = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.layoutHeaderView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        refreshAccountDetailsAndSettings()

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
        handler.viewModel = tableViewModel(with: account)

        let primaryViewController = (splitViewController?.viewControllers.first as? UINavigationController)?.topViewController
        if !splitViewControllerIsHorizontallyCompact && primaryViewController is MeViewController {
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
        let accessoryType: UITableViewCell.AccessoryType = isPrimaryViewControllerInSplitView() ? .none : .disclosureIndicator

        return NavigationItemRow(
            title: RowTitles.appSettings,
            icon: .gridicon(.phone),
            accessoryType: accessoryType,
            action: pushAppSettings(),
            accessibilityIdentifier: "appSettings")
    }

    fileprivate func tableViewModel(with account: WPAccount?) -> ImmuTable {
        let accessoryType: UITableViewCell.AccessoryType = isPrimaryViewControllerInSplitView() ? .none : .disclosureIndicator

        let loggedIn = account != nil

        let myProfile = NavigationItemRow(
            title: RowTitles.myProfile,
            icon: .gridicon(.user),
            accessoryType: accessoryType,
            action: pushMyProfile(),
            accessibilityIdentifier: "myProfile")

        let qrLogin = NavigationItemRow(
            title: RowTitles.qrLogin,
            icon: .gridicon(.camera),
            accessoryType: accessoryType,
            action: presentQRLogin(),
            accessibilityIdentifier: "qrLogin")

        let accountSettings = NavigationItemRow(
            title: RowTitles.accountSettings,
            icon: .gridicon(.cog),
            accessoryType: accessoryType,
            action: pushAccountSettings(),
            accessibilityIdentifier: "accountSettings")

        let helpAndSupportIndicator = IndicatorNavigationItemRow(
            title: RowTitles.support,
            icon: .gridicon(.help),
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

        let shouldShowQRLoginRow = AppConfiguration.qrLoginEnabled && !(account?.settings?.twoStepEnabled ?? false)

        return ImmuTable(sections: [
            // first section
            .init(rows: {
                var rows: [ImmuTableRow] = [appSettingsRow]
                if loggedIn {
                    var loggedInRows = [myProfile, accountSettings]
                    if shouldShowQRLoginRow {
                        loggedInRows.append(qrLogin)
                    }

                    rows = loggedInRows + rows
                }
                return rows
            }()),

            // middle section
            .init(rows: {
                var rows: [ImmuTableRow] = [helpAndSupportIndicator]

                rows.append(NavigationItemRow(title: ShareAppContentPresenter.RowConstants.buttonTitle,
                                              icon: ShareAppContentPresenter.RowConstants.buttonIconImage,
                                              accessoryType: accessoryType,
                                              action: displayShareFlow(),
                                              loading: sharePresenter.isLoading))

                rows.append(NavigationItemRow(title: RowTitles.about,
                                              icon: UIImage.gridicon(AppConfiguration.isJetpack ? .plans : .mySites),
                                              accessoryType: accessoryType,
                                              action: pushAbout(),
                                              accessibilityIdentifier: "About"))

                return rows
            }()),

            // last section
            .init(headerText: wordPressComAccount, rows: {
                return [loggedIn ? logOut : logIn]
            }())
        ])
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
                self.showOrPushController(myProfileViewController)
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
                self.showOrPushController(controller)
            }
        }
    }

    private func presentQRLogin() -> ImmuTableAction {
        return { [weak self] row in
            guard let self = self else {
                return
            }

            self.tableView.deselectSelectedRowWithAnimation(true)
            QRLoginCoordinator.present(from: self, origin: .menu)
        }
    }

    func pushAppSettings() -> ImmuTableAction {
        return { [unowned self] row in
            self.navigateToAppSettings()
        }
    }

    func pushHelp() -> ImmuTableAction {
        return { [unowned self] row in
            let controller = SupportTableViewController(style: .insetGrouped)
            self.showOrPushController(controller)
        }
    }

    private func pushAbout() -> ImmuTableAction {
        return { [unowned self] _ in
            let configuration = AppAboutScreenConfiguration(sharePresenter: self.sharePresenter)
            let controller = AutomatticAboutScreen.controller(appInfo: AppAboutScreenConfiguration.appInfo,
                                                              configuration: configuration,
                                                              fonts: AppAboutScreenConfiguration.fonts)
            self.present(controller, animated: true) {
                self.tableView.deselectSelectedRowWithAnimation(true)
            }
        }
    }

    func displayShareFlow() -> ImmuTableAction {
        return { [unowned self] row in
            defer {
                self.tableView.deselectSelectedRowWithAnimation(true)
            }

            guard let selectedIndexPath = self.tableView.indexPathForSelectedRow,
                  let selectedCell = self.tableView.cellForRow(at: selectedIndexPath) else {
                return
            }

            self.sharePresenter.present(for: AppConstants.shareAppName, in: self, source: .me, sourceView: selectedCell)
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
    @objc public func navigateToAppSettings(completion: ((AppSettingsViewController) -> Void)? = nil) {
        self.selectRowForTitle(appSettingsRow.title)
        WPAppAnalytics.track(.openedAppSettings)
        let destination = AppSettingsViewController()
        self.showOrPushController(destination) {
            completion?(destination)
        }
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

        if let sections = handler?.viewModel.sections,
            let section = sections.firstIndex(where: { $0.rows.contains(where: matchRow) }),
            let row = sections[section].rows.firstIndex(where: matchRow) {
            let indexPath = IndexPath(row: row, section: section)

            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .middle)
            handler.tableView(self.tableView, didSelectRowAt: indexPath)
        }
    }

    private func selectRowForTitle(_ rowTitle: String) {
        self.tableView.selectRow(at: indexPathForRowTitle(rowTitle), animated: true, scrollPosition: .middle)
    }

    private func indexPathForRowTitle(_ rowTitle: String) -> IndexPath? {
        let matchRow: ((ImmuTableRow) -> Bool) = { row in
            if let row = row as? NavigationItemRow {
                return row.title == rowTitle
            } else if let row = row as? IndicatorNavigationItemRow {
                return row.title == rowTitle
            }
            return false
        }
        guard let sections = handler?.viewModel.sections,
              let section = sections.firstIndex(where: { $0.rows.contains(where: matchRow) }),
              let row = sections[section].rows.firstIndex(where: matchRow) else {
            return nil
        }
        return IndexPath(row: row, section: section)
    }

    private func showOrPushController(_ controller: UIViewController, completion: (() -> Void)? = nil) {
        let shouldShowInDetailViewController = isPrimaryViewControllerInSplitView()
        if shouldShowInDetailViewController {
            self.showDetailViewController(controller, sender: self)
            completion?()
            return
        } else if let navigationController {
            navigationController.pushViewController(controller, animated: true, rightBarButton: self.navigationItem.rightBarButtonItem)
            navigationController.transitionCoordinator?.animate(alongsideTransition: nil, completion: { _ in
                completion?()
            })
        } else {
            completion?()
        }
    }

    private func isPrimaryViewControllerInSplitView() -> Bool {
        let primaryViewController = (splitViewController?.viewControllers.first as? UINavigationController)?.topViewController

        return MySitesCoordinator.isSplitViewEnabled && primaryViewController is MeViewController
    }

    // MARK: - Helpers

    // FIXME: (@koke 2015-12-17) Not cool. Let's stop passing managed objects
    // and initializing stuff with safer values like userID
    fileprivate func defaultAccount() -> WPAccount? {
        return try? WPAccount.lookupDefaultWordPressComAccount(in: ContextManager.shared.mainContext)
    }

    fileprivate func refreshAccountDetailsAndSettings() {
        guard let account = defaultAccount(), let api = account.wordPressComRestApi else {
            reloadViewModel()
            return
        }

        let accountService = AccountService(coreDataStack: ContextManager.sharedInstance())
        let accountSettingsService = AccountSettingsService(userID: account.userID.intValue, api: api)

        Task {
            do {
                async let refreshDetails: Void = Self.refreshAccountDetails(with: accountService, account: account)
                async let refreshSettings: Void = Self.refreshAccountSettings(with: accountSettingsService)
                let _ = try await [refreshDetails, refreshSettings]
                self.reloadViewModel()
            } catch let error {
                DDLogError(error.localizedDescription)
            }
        }
    }

    fileprivate static func refreshAccountDetails(with service: AccountService, account: WPAccount) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            service.updateUserDetails(for: account, success: {
                continuation.resume()
            }, failure: { error in
                continuation.resume(throwing: error)
            })
        }
    }

    fileprivate static func refreshAccountSettings(with service: AccountSettingsService) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            service.refreshSettings { result in
                switch result {
                case .success: continuation.resume()
                case .failure(let error): continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - LogOut

    private func displayLogOutAlert() {
        let alert  = UIAlertController(title: logOutAlertTitle, message: nil, preferredStyle: .alert)
        alert.addActionWithTitle(LogoutAlert.cancelAction, style: .cancel)
        alert.addActionWithTitle(LogoutAlert.logoutAction, style: .destructive) { [weak self] _ in
            self?.dismiss(animated: true) {
                AccountHelper.logOutDefaultWordPressComAccount()
            }
        }

        present(alert, animated: true)
    }

    private var logOutAlertTitle: String {
        let context = ContextManager.sharedInstance().mainContext
        let count = AbstractPost.countLocalPosts(in: context)

        guard count > 0 else {
            return LogoutAlert.defaultTitle
        }

        let format = count > 1 ? LogoutAlert.unsavedTitlePlural : LogoutAlert.unsavedTitleSingular
        return String(format: format, count)
    }

    // MARK: - Private Properties

    fileprivate lazy var headerView = MeHeaderView()

    /// Shows an actionsheet with options to Log In or Create a WordPress site.
    /// This is a temporary stop-gap measure to preserve for users only logged
    /// into a self-hosted site the ability to create a WordPress.com account.
    ///
    fileprivate func promptForLoginOrSignup() {
        WordPressAuthenticator.showLogin(from: self, animated: true, showCancel: true, restrictToWPCom: true)
    }

    private lazy var sharePresenter: ShareAppContentPresenter = {
        let presenter = ShareAppContentPresenter(account: defaultAccount())
        presenter.delegate = self
        return presenter
    }()
}

// MARK: - WPSplitViewControllerDetailProvider Conformance

extension MeViewController: WPSplitViewControllerDetailProvider {
    func initialDetailViewControllerForSplitView(_ splitView: WPSplitViewController) -> UIViewController? {

        guard let _ = defaultAccount() else {
            return nil
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

// MARK: - Constants

private extension MeViewController {
    enum RowTitles {
        static let appSettings = NSLocalizedString("App Settings", comment: "Link to App Settings section")
        static let myProfile = NSLocalizedString("My Profile", comment: "Link to My Profile section")
        static let accountSettings = NSLocalizedString("Account Settings", comment: "Link to Account Settings section")
        static let qrLogin = NSLocalizedString("Scan Login Code", comment: "Link to opening the QR login scanner")
        static let support = NSLocalizedString("Help & Support", comment: "Link to Help section")
        static let logIn = NSLocalizedString("Log In", comment: "Label for logging in to WordPress.com account")
        static let logOut = NSLocalizedString("Log Out", comment: "Label for logging out from WordPress.com account")
        static let about = AppConstants.Settings.aboutTitle
    }

    enum HeaderTitles {
        static let wpAccount = NSLocalizedString("WordPress.com Account", comment: "WordPress.com sign-in/sign-out section header title")
    }

    enum LogoutAlert {
        static let defaultTitle = AppConstants.Logout.alertTitle
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

// MARK: - ShareAppContentPresenterDelegate

extension MeViewController: ShareAppContentPresenterDelegate {
    func didUpdateLoadingState(_ loading: Bool) {
        reloadViewModel()
    }
}

// MARK: - Jetpack powered badge
extension MeViewController {

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard section == handler.viewModel.sections.count - 1,
              JetpackBrandingVisibility.all.enabled else {
            return nil
        }
        let textProvider = JetpackBrandingTextProvider(screen: JetpackBadgeScreen.me)
        return JetpackButton.makeBadgeView(title: textProvider.brandingText(),
                                           target: self,
                                           selector: #selector(jetpackButtonTapped))
    }

    @objc private func jetpackButtonTapped() {
        JetpackBrandingCoordinator.presentOverlay(from: self)
        JetpackBrandingAnalyticsHelper.trackJetpackPoweredBadgeTapped(screen: .me)
    }
}
