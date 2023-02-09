import UIKit
import WordPressAuthenticator

class SupportTableViewController: UITableViewController {

    // MARK: - Properties

    /// Configures the appearance of the support screen.
    let configuration: Configuration

    var sourceTag: WordPressSupportSourceTag?

    // If set, the Zendesk views will be shown from this view instead of in the navigation controller.
    // Specifically for Me > Help & Support on the iPad.
    var showHelpFromViewController: UIViewController?

    private var tableHandler: ImmuTableViewHandler?
    private let userDefaults = UserPersistentStoreFactory.instance()
    private let featureFlagStore: RemoteFeatureFlagStore
    private let isForumShown = SupportConfiguration.current() == .forum

    /// This closure is called when this VC is about to be dismissed due to the user
    /// tapping the dismiss button.
    ///
    private var dismissTapped: (() -> ())?

    // MARK: - Init

    init(configuration: Configuration = .init(), style: UITableView.Style = .grouped, featureFlagStore: RemoteFeatureFlagStore = RemoteFeatureFlagStore()) {
        self.configuration = configuration
        self.featureFlagStore = featureFlagStore
        super.init(style: style)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required convenience init(dismissTapped: (() -> ())? = nil) {
        self.init(style: .grouped)
        self.dismissTapped = dismissTapped
    }

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        WPAnalytics.track(.openedSupport)
        setupNavBar()
        setupTable()
        checkForAutomatticEmail()
        ZendeskUtils.sharedInstance.cacheUnlocalizedSitePlans()
        ZendeskUtils.fetchUserInformation()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tableView.sizeToFitHeaderView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadViewModel()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        createUserActivity()
    }

    @objc func showFromTabBar() {
        let navigationController = UINavigationController.init(rootViewController: self)

        if WPDeviceIdentification.isiPad() {
            navigationController.modalTransitionStyle = .crossDissolve
            navigationController.modalPresentationStyle = .formSheet
        }

        let rootViewController = RootViewCoordinator.sharedPresenter.rootViewController
        if let presentedVC = rootViewController.presentedViewController {
            presentedVC.present(navigationController, animated: true)
        } else {
            rootViewController.present(navigationController, animated: true)
        }
    }

    // MARK: - Button Actions

    @IBAction func dismissPressed(_ sender: AnyObject) {
        dismissTapped?()
        dismiss(animated: true)
    }
}

// MARK: - Private Extension

private extension SupportTableViewController {

    func registerObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(refreshNotificationIndicator(_:)), name: .ZendeskPushNotificationReceivedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshNotificationIndicator(_:)), name: .ZendeskPushNotificationClearedNotification, object: nil)
    }

    func setupNavBar() {
        title = isForumShown ? LocalizedText.viewTitle : LocalizedText.viewTitleSupport

        if isModal() {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: LocalizedText.closeButton,
                                                               style: WPStyleGuide.barButtonStyleForBordered(),
                                                               target: self,
                                                               action: #selector(SupportTableViewController.dismissPressed(_:)))
            navigationItem.leftBarButtonItem?.accessibilityIdentifier = "close-button"
        }
    }

    func setupTable() {
        ImmuTable.registerRows([SwitchRow.self,
                                NavigationItemRow.self,
                                TextRow.self,
                                HelpRow.self,
                                DestructiveButtonRow.self,
                                SupportEmailRow.self,
                                SupportForumRow.self,
                                SupportForumButtonRow.self],
                               tableView: tableView)
        tableHandler = ImmuTableViewHandler(takeOver: self)
        reloadViewModel()
        WPStyleGuide.configureColors(view: view, tableView: tableView)
        tableView.tableFooterView = UIView() // remove empty cells
        if let headerConfig = configuration.meHeaderConfiguration {
            let headerView = MeHeaderView()
            headerView.update(with: headerConfig)
            tableView.tableHeaderView = headerView
        }
        registerObservers()
    }

    // MARK: - Table Model

    func tableViewModel() -> ImmuTable {

        // Help Section
        var helpSection: ImmuTableSection?
        if SupportConfiguration.current(featureFlagStore: featureFlagStore) == .zendesk {
            var helpSectionRows = [ImmuTableRow]()
            helpSectionRows.append(HelpRow(title: LocalizedText.contactUs, action: contactUsSelected(), accessibilityIdentifier: "contact-support-button", featureFlagSupportForum: isForumShown))
            helpSectionRows.append(HelpRow(title: LocalizedText.tickets, action: myTicketsSelected(), showIndicator: ZendeskUtils.showSupportNotificationIndicator, accessibilityIdentifier: "my-tickets-button", featureFlagSupportForum: isForumShown))
            helpSectionRows.append(SupportEmailRow(title: LocalizedText.email,
                                                   value: ZendeskUtils.userSupportEmail() ?? LocalizedText.emailNotSet,
                                                   accessibilityHint: LocalizedText.contactEmailAccessibilityHint,
                                                   action: supportEmailSelected(),
                                                   accessibilityIdentifier: "set-contact-email-button",
                                                   featureFlagSupportForumEnabled: isForumShown))
            helpSection = ImmuTableSection(
                    headerText: LocalizedText.prioritySupportSectionHeader,
                    rows: helpSectionRows,
                    footerText: nil)
        }

        // Community Forums Section
        var communityForumsSectionRows = [ImmuTableRow]()
        communityForumsSectionRows.append(SupportForumRow(title: LocalizedText.wpForumPrompt,
                                                          action: nil,
                                                          accessibilityIdentifier: "visit-wordpress-forums-prompt"))
        communityForumsSectionRows.append(SupportForumButtonRow(title: LocalizedText.visitWpForumsButton,
                                                                accessibilityHint: LocalizedText.visitWpForumsButtonAccessibilityHint,
                                                                action: visitForumsSelected(),
                                                                accessibilityIdentifier: "visit-wordpress-forums-button"))

        let forumsSection = ImmuTableSection(headerText: LocalizedText.wpForumsSectionHeader,
                                             rows: communityForumsSectionRows,
                                             footerText: nil)

        // Information Section
        var informationSection: ImmuTableSection?
        if configuration.showsLogsSection {
            let versionRow = TextRow(title: LocalizedText.version, value: Bundle.main.shortVersionString())
            let switchRow = SwitchRow(title: LocalizedText.debug,
                                      value: userDefaults.bool(forKey: UserDefaultsKeys.extraDebug),
                                      onChange: extraDebugToggled())
            let logsRow = NavigationItemRow(title: LocalizedText.logs, action: activityLogsSelected(), accessibilityIdentifier: "activity-logs-button")
            informationSection = ImmuTableSection(
                headerText: LocalizedText.advancedSectionHeader,
                rows: [versionRow, logsRow, switchRow],
                footerText: LocalizedText.informationFooter
            )
        }

        // Log out Section
        var logOutSections: ImmuTableSection?
        if configuration.showsLogOutButton {
            let logOutRow = DestructiveButtonRow(
                title: LocalizedText.logOutButtonTitle,
                action: logOutTapped(),
                accessibilityIdentifier: ""
            )
            logOutSections = .init(headerText: LocalizedText.wpAccount, optionalRows: [logOutRow])
        }

        // Create and return table
        let sections = [helpSection, forumsSection, informationSection, logOutSections].compactMap { $0 }
        return ImmuTable(sections: sections)
    }

    // TODO - remove after FeatureFlag.wordPressSupportForum is removed
    func oldTableViewModel() -> ImmuTable {

        // Help Section
        var helpSectionRows = [ImmuTableRow]()
        helpSectionRows.append(HelpRow(title: LocalizedText.wpHelpCenter, action: helpCenterSelected(), accessibilityIdentifier: "help-center-link-button", featureFlagSupportForum: isForumShown))

        if ZendeskUtils.zendeskEnabled {
            helpSectionRows.append(HelpRow(title: LocalizedText.contactUs, action: contactUsSelected(), accessibilityIdentifier: "contact-support-button", featureFlagSupportForum: isForumShown))
            helpSectionRows.append(HelpRow(title: LocalizedText.myTickets, action: myTicketsSelected(), showIndicator: ZendeskUtils.showSupportNotificationIndicator, accessibilityIdentifier: "my-tickets-button", featureFlagSupportForum: isForumShown))
            helpSectionRows.append(SupportEmailRow(title: LocalizedText.contactEmail,
                                                   value: ZendeskUtils.userSupportEmail() ?? LocalizedText.emailNotSet,
                                                   accessibilityHint: LocalizedText.contactEmailAccessibilityHint,
                                                   action: supportEmailSelected(),
                                                   accessibilityIdentifier: "set-contact-email-button",
                                                   featureFlagSupportForumEnabled: isForumShown))
        } else {
            helpSectionRows.append(HelpRow(title: LocalizedText.wpForums, action: contactUsSelected(), featureFlagSupportForum: isForumShown))
        }

        let helpSection = ImmuTableSection(
                headerText: nil,
                rows: helpSectionRows,
                footerText: LocalizedText.helpFooter)

        // Information Section
        var informationSection: ImmuTableSection?
        if configuration.showsLogsSection {
            let versionRow = TextRow(title: LocalizedText.version, value: Bundle.main.shortVersionString())
            let switchRow = SwitchRow(title: LocalizedText.extraDebug,
                                      value: userDefaults.bool(forKey: UserDefaultsKeys.extraDebug),
                                      onChange: extraDebugToggled())
            let logsRow = NavigationItemRow(title: LocalizedText.activityLogs, action: activityLogsSelected(), accessibilityIdentifier: "activity-logs-button")
            informationSection = ImmuTableSection(
                    headerText: nil,
                    rows: [versionRow, switchRow, logsRow],
                    footerText: LocalizedText.informationFooterOld
            )
        }

        // Log out Section
        var logOutSections: ImmuTableSection?
        if configuration.showsLogOutButton {
            let logOutRow = DestructiveButtonRow(
                    title: LocalizedText.logOutButtonTitle,
                    action: logOutTapped(),
                    accessibilityIdentifier: ""
            )
            logOutSections = .init(headerText: LocalizedText.wpAccount, optionalRows: [logOutRow])
        }

        // Create and return table
        let sections = [helpSection, informationSection, logOutSections].compactMap { $0 }
        return ImmuTable(sections: sections)
    }

    @objc func refreshNotificationIndicator(_ notification: Foundation.Notification) {
        reloadViewModel()
    }

    func reloadViewModel() {
        tableHandler?.viewModel = isForumShown ? tableViewModel() : oldTableViewModel()
    }

    // MARK: - Row Handlers

    func helpCenterSelected() -> ImmuTableAction {
        return { [unowned self] _ in
            self.tableView.deselectSelectedRowWithAnimation(true)
            guard let url = Constants.appSupportURL else {
                return
            }
            WPAnalytics.track(.supportHelpCenterViewed)
            UIApplication.shared.open(url)
        }
    }

    func contactUsSelected() -> ImmuTableAction {
        return { [weak self] row in
            guard let self = self else { return }
            self.tableView.deselectSelectedRowWithAnimation(true)
            if SupportConfiguration.current(featureFlagStore: self.featureFlagStore) == .zendesk {
                guard let controllerToShowFrom = self.controllerToShowFrom() else {
                    return
                }
                ZendeskUtils.sharedInstance.showNewRequestIfPossible(from: controllerToShowFrom, with: self.sourceTag) { [weak self] identityUpdated in
                    if identityUpdated {
                        self?.reloadViewModel()
                    }
                }
            } else {
                self.launchForum(url: Constants.forumsURL)
            }
        }
    }

    func myTicketsSelected() -> ImmuTableAction {
        return { [weak self] row in
            guard let self = self else { return }
            ZendeskUtils.pushNotificationRead()
            self.tableView.deselectSelectedRowWithAnimation(true)

            guard let controllerToShowFrom = self.controllerToShowFrom() else {
                return
            }
            ZendeskUtils.sharedInstance.showTicketListIfPossible(from: controllerToShowFrom, with: self.sourceTag) { [weak self] identityUpdated in
                if identityUpdated {
                    self?.reloadViewModel()
                }
            }
        }
    }

    func supportEmailSelected() -> ImmuTableAction {
        return { [unowned self] row in

            self.tableView.deselectSelectedRowWithAnimation(true)

            guard let controllerToShowFrom = self.controllerToShowFrom() else {
                return
            }

            WPAnalytics.track(.supportIdentityFormViewed)
            ZendeskUtils.sharedInstance.showSupportEmailPrompt(from: controllerToShowFrom) { success in
                guard success else {
                    return
                }
                // Tracking when the dialog's "OK" button is pressed, not necessarily
                // if the value changed.
                WPAnalytics.track(.supportIdentitySet)
                self.reloadViewModel()
                self.checkForAutomatticEmail()
            }
        }
    }

    func visitForumsSelected() -> ImmuTableAction {
        return { [weak self] row in
            guard let self = self else { return }
            self.tableView.deselectSelectedRowWithAnimation(true)
            self.launchForum(url: Constants.forumsURL)
        }
    }

    private func launchForum(url: URL?) {
        guard let url = url else {
            return
        }
        WPAnalytics.track(.supportOpenMobileForumTapped)
        UIApplication.shared.open(url)
    }

    /// Zendesk does not allow agents to submit tickets, and displays a 'Message failed to send' error upon attempt.
    /// If the user email address is a8c, display a warning.
    ///
    func checkForAutomatticEmail() {
        guard let email = ZendeskUtils.userSupportEmail(),
            (Constants.automatticEmails.first { email.contains($0) }) != nil else {
                return
        }

        let alert = UIAlertController(title: "Warning",
                                      message: "Automattic email account detected. Please log in with a non-Automattic email to submit or view support tickets.",
                                      preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
        alert.addAction(cancel)

        present(alert, animated: true, completion: nil)
    }

    func extraDebugToggled() -> (_ newValue: Bool) -> Void {
        return { [unowned self] newValue in
            self.userDefaults.set(newValue, forKey: UserDefaultsKeys.extraDebug)
            WPLogger.configureLoggerLevelWithExtraDebug()
        }
    }

    func activityLogsSelected() -> ImmuTableAction {
        return { [unowned self] row in
            let activityLogViewController = ActivityLogViewController()
            self.navigationController?.pushViewController(activityLogViewController, animated: true)
        }
    }

    private func logOutTapped() -> ImmuTableAction {
        return { [weak self] row in
            guard let self else {
                return
            }
            self.tableView.deselectSelectedRowWithAnimation(true)
            let actionHandler = LogOutActionHandler()
            actionHandler.logOut(with: self)
        }
    }

    // MARK: - ImmuTableRow Struct

    struct HelpRow: ImmuTableRow {
        static let cell = ImmuTableCell.class(WPTableViewCellIndicator.self)

        let title: String
        let showIndicator: Bool
        let action: ImmuTableAction?
        let accessibilityIdentifier: String?
        let featureFlagSupportForumEnabled: Bool

        init(title: String, action: @escaping ImmuTableAction, showIndicator: Bool = false, accessibilityIdentifier: String? = nil, featureFlagSupportForum: Bool = false) {
            self.title = title
            self.showIndicator = showIndicator
            self.action = action
            self.accessibilityIdentifier = accessibilityIdentifier
            self.featureFlagSupportForumEnabled = featureFlagSupportForum
        }

        func configureCell(_ cell: UITableViewCell) {
            let cell = cell as! WPTableViewCellIndicator
            cell.textLabel?.text = title
            WPStyleGuide.configureTableViewCell(cell)
            if featureFlagSupportForumEnabled {
                cell.accessoryType = .disclosureIndicator
            } else {
                cell.textLabel?.textColor = .primary
                cell.showIndicator = showIndicator
            }
            cell.accessibilityTraits = .button
            cell.accessibilityIdentifier = accessibilityIdentifier
        }
    }

    struct SupportEmailRow: ImmuTableRow {
        static let cell = ImmuTableCell.class(WPTableViewCellValue1.self)

        let title: String
        let value: String
        let accessibilityHint: String
        let action: ImmuTableAction?
        let accessibilityIdentifier: String?
        let featureFlagSupportForumEnabled: Bool

        func configureCell(_ cell: UITableViewCell) {
            cell.textLabel?.text = title
            cell.detailTextLabel?.text = value
            WPStyleGuide.configureTableViewCell(cell)
            if !featureFlagSupportForumEnabled {
                cell.textLabel?.textColor = .primary
            }
            cell.accessibilityTraits = .button
            cell.accessibilityHint = accessibilityHint
            cell.accessibilityIdentifier = accessibilityIdentifier
        }
    }

    struct SupportForumRow: ImmuTableRow {
        static let cell = ImmuTableCell.class(WPTableViewCellDefault.self)

        let title: String
        let action: ImmuTableAction?
        let accessibilityIdentifier: String?

        func configureCell(_ cell: UITableViewCell) {
            cell.textLabel?.text = title
            cell.selectionStyle = .none
            WPStyleGuide.configureTableViewCell(cell)
        }
    }

    struct SupportForumButtonRow: ImmuTableRow {
        typealias CellType = SupportForumButtonCell

        static let cell = ImmuTableCell.class(CellType.self)

        let title: String
        let accessibilityHint: String
        let action: ImmuTableAction?
        let accessibilityIdentifier: String?


        func configureCell(_ cell: UITableViewCell) {
            guard let cell = cell as? CellType else {
                return
            }

            cell.button.setTitle(title, for: .normal)
            cell.button.accessibilityHint = accessibilityHint
            cell.button.addAction(UIAction { _ in
                action?(self)
            }, for: .touchUpInside)
        }

    }

    // MARK: - Helpers

    func controllerToShowFrom() -> UIViewController? {
        return showHelpFromViewController ?? navigationController ?? nil
    }

    // MARK: - Localized Text

    struct LocalizedText {
        static let viewTitle = NSLocalizedString("support.title", value: "Help", comment: "View title for Help & Support page.")
        static let closeButton = NSLocalizedString("support.button.close.title", value: "Close", comment: "Dismiss the current view")
        static let wpHelpCenter = NSLocalizedString("support.row.helpCenter.title", value: "WordPress Help Center", comment: "Option in Support view to launch the Help Center.")
        static let contactUs = NSLocalizedString("support.row.contactUs.title", value: "Contact Support", comment: "Option in Support view to contact the support team.")
        static let wpForums = NSLocalizedString("support.row.forums.title", value: "WordPress Forums", comment: "Option in Support view to view the Forums.")
        static let prioritySupportSectionHeader = NSLocalizedString("support.sectionHeader.prioritySupport.title", value: "Priority Support", comment: "Section header in Support view for priority support.")
        static let wpForumsSectionHeader = NSLocalizedString("support.sectionHeader.forum.title", value: "Community Forums", comment: "Section header in Support view for the Forums.")
        static let advancedSectionHeader = NSLocalizedString("support.sectionHeader.advanced.title", value: "Advanced", comment: "Section header in Support view for advanced information.")
        static let wpForumPrompt = NSLocalizedString("support.row.communityForum.title", value: "Ask a question in the community forum and get help from our group of volunteers.", comment: "Suggestion in Support view to visit the Forums.")
        static let visitWpForumsButton = NSLocalizedString("support.button.visitForum.title", value: "Visit WordPress.org", comment: "Option in Support view to visit the WordPress.org support forums.")
        static let visitWpForumsButtonAccessibilityHint = NSLocalizedString("support.button.visitForum.accessibilityHint", value: "Tap to visit the community forum website in an external browser", comment: "Accessibility hint, informing user the button can be used to visit the support forums website.")
        static let myTickets = NSLocalizedString("support.row.myTickets.title", value: "My Tickets", comment: "Option in Support view to access previous help tickets.")
        static let tickets = NSLocalizedString("support.row.tickets.title", value: "Tickets", comment: "Option in Support view to access previous help tickets.")
        static let helpFooter = NSLocalizedString("support.sectionFooter.helpCenter.title", value: "Visit the Help Center to get answers to common questions, or contact us for more help.", comment: "Support screen footer text displayed when Zendesk is enabled.")
        static let version = NSLocalizedString("support.row.version.title", value: "Version", comment: "Label in Support view displaying the app version.")
        static let debug = NSLocalizedString("support.row.debug.title", value: "Debug", comment: "Option in Support view to enable/disable adding debug information to support ticket.")
        static let logs = NSLocalizedString("support.row.logs.title", value: "Logs", comment: "Option in Support view to see activity logs.")
        static let informationFooter = NSLocalizedString("support.sectionFooter.advanced.title", value: "Enable Debugging to include additional information in your logs that can help troubleshoot issues with the app.", comment: "Support screen footer text explaining the benefits of enabling the Debug feature.")
        static let email = NSLocalizedString("support.row.email.title", value: "Email", comment: "Support email label.")
        static let contactEmailAccessibilityHint = NSLocalizedString("support.row.contactEmail.accessibilityHint", value: "Shows a dialog for changing the Contact Email.", comment: "Accessibility hint describing what happens if the Contact Email button is tapped.")
        static let emailNotSet = NSLocalizedString("support.row.contactEmail.emailNoteSet.detail", value: "Not Set", comment: "Display value for Support email field if there is no user email address.")
        static let wpAccount = NSLocalizedString("support.sectionHeader.account.title", value: "WordPress.com Account", comment: "WordPress.com sign-out section header title")
        static let logOutButtonTitle = NSLocalizedString("support.button.logOut.title", value: "Log Out", comment: "Button for confirming logging out from WordPress.com account")

        //TODO - can remove these below after WordPressSupportForum feature flag removed
        static let activityLogs = NSLocalizedString("support.row.activityLogs.title", value: "Activity Logs", comment: "Option in Support view to see activity logs.")
        static let informationFooterOld = NSLocalizedString("support.sectionFooter.advanced.old.title", value: "The Extra Debug feature includes additional information in activity logs, and can help us troubleshoot issues with the app.", comment: "Support screen footer text explaining the Extra Debug feature.")
        static let extraDebug = NSLocalizedString("support.row.extraDebug.title", value: "Extra Debug", comment: "Option in Support view to enable/disable adding extra information to support ticket.")
        static let contactEmail = NSLocalizedString("support.row.contactEmail.title", value: "Contact Email", comment: "Support email label.")
        static let viewTitleSupport = NSLocalizedString("zendeskSupport.title", value: "Support", comment: "View title for Help & Support page.")
    }

    // MARK: - User Defaults Keys

    struct UserDefaultsKeys {
        static let extraDebug = "extra_debug"
    }

    // MARK: - Constants

    struct Constants {
        static let appSupportURL = URL(string: "https://apps.wordpress.com/mobile-app-support/")

        static let forumsURL = URL(string: "https://wordpress.org/support/forum/mobile/")
        static let automatticEmails = ["@automattic.com", "@a8c.com"]
    }
}

private class SupportForumButtonCell: WPTableViewCellDefault {

    let button: SpotlightableButton = {
        let button = SpotlightableButton(type: .custom)

        button.titleLabel?.font = WPStyleGuide.fontForTextStyle(.callout)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button.contentHorizontalAlignment = .trailing

        button.setTitleColor(.primary, for: .normal)

        button.setImage(UIImage.gridicon(.external,
                                         size: CGSize(width: LayoutSpacing.imageSize, height: LayoutSpacing.imageSize)),
                        for: .normal)

        // Align the image to the right
        if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
            button.semanticContentAttribute = .forceLeftToRight
            button.imageEdgeInsets = LayoutSpacing.rtlButtonTitleImageInsets
        } else {
            button.semanticContentAttribute = .forceRightToLeft
            button.imageEdgeInsets = LayoutSpacing.buttonTitleImageInsets
        }

        button.translatesAutoresizingMaskIntoConstraints = false

        return button
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        contentView.addSubview(button)

        NSLayoutConstraint.activate([
                                        button.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: LayoutSpacing.padding),
                                        button.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -LayoutSpacing.padding),
                                        button.topAnchor.constraint(equalTo: contentView.topAnchor, constant: LayoutSpacing.padding),
                                        button.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -LayoutSpacing.padding)
                                    ])
    }

    enum LayoutSpacing {
        static let imageSize: CGFloat = 17.0
        static let padding: CGFloat = 16.0
        static let buttonTitleImageInsets = UIEdgeInsets(top: 1, left: 4, bottom: 0, right: 0)
        static let rtlButtonTitleImageInsets = UIEdgeInsets(top: 1, left: -4, bottom: 0, right: 4)
    }
}
