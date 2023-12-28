import UIKit
import WordPressShared


/// The purpose of this class is to retrieve the collection of NotificationSettings from WordPress.com
/// Backend, and render the "Top Level" list.
/// On Row Press, we'll push the list of available Streams, which will, in turn, push the Details View
/// itself, which is in charge of rendering the actual available settings.
///
class NotificationSettingsViewController: UIViewController {

    // MARK: - Properties

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.sectionFooterHeight = UITableView.automaticDimension
        return tableView
    }()

    private lazy var activityIndicatorView: UIActivityIndicatorView = {
        let indicatorView = UIActivityIndicatorView()
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        return indicatorView
    }()

    private lazy var mainView: UIView = {
        let view = UIView()
        view.addSubviews([tableView, activityIndicatorView])
        return view
    }()


    // MARK: - Private Constants

    fileprivate let blogReuseIdentifier = WPBlogTableViewCell.classNameWithoutNamespaces()

    fileprivate let defaultReuseIdentifier = WPTableViewCell.classNameWithoutNamespaces()
    fileprivate let switchReuseIdentifier = SwitchTableViewCell.classNameWithoutNamespaces()

    fileprivate let emptyCount = 0
    fileprivate let loadMoreRowIndex = 3
    fileprivate let loadMoreRowCount = 4


    // MARK: - Private Properties

    fileprivate var groupedSettings: [Section: [NotificationSettings]] = [:]
    fileprivate var displayBlogMoreWasAccepted = false
    fileprivate var displayFollowedMoreWasAccepted = false
    fileprivate var followedSites: [ReaderSiteTopic] = []
    fileprivate var tableSections: [Section] = []

    private var notificationsEnabled = false

    override func loadView() {
        mainView.pinSubviewToAllEdges(tableView)
        mainView.pinSubviewAtCenter(activityIndicatorView)

        view = mainView
    }

    // MARK: - View Lifecycle

    open override func viewDidLoad() {
        super.viewDidLoad()

        // Initialize Interface
        setupNavigationItem()
        setupTableView()

        // Load Settings
        reloadSettings()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        WPAnalytics.track(.openedNotificationSettingsList)

        // Manually deselect the selected row. This is required due to a bug in iOS7 / iOS8
        tableView.deselectSelectedRowWithAnimation(true)
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        registerUserActivity()
    }


    // MARK: - Setup Helpers

    fileprivate func setupNavigationItem() {
        title = NSLocalizedString("Notification Settings", comment: "Title displayed in the Notification settings")
        navigationItem.backBarButtonItem = UIBarButtonItem(title: String(), style: .plain, target: nil, action: nil)
    }

    fileprivate func setupTableView() {
        // Register the cells
        tableView.register(WPBlogTableViewCell.self, forCellReuseIdentifier: blogReuseIdentifier)
        tableView.register(WPTableViewCell.self, forCellReuseIdentifier: defaultReuseIdentifier)
        tableView.register(SwitchTableViewCell.self, forCellReuseIdentifier: switchReuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self

        // Hide the separators, whenever the table is empty
        tableView.tableFooterView = UIView()

        // Style!
        WPStyleGuide.configureColors(view: view, tableView: tableView)
        WPStyleGuide.configureAutomaticHeightRows(for: tableView)

        activityIndicatorView.tintColor = .textSubtle
    }


    // MARK: - Service Helpers

    fileprivate func reloadSettings() {
        let service = NotificationSettingsService(coreDataStack: ContextManager.sharedInstance())

        let dispatchGroup = DispatchGroup()
        let siteService = ReaderTopicService(coreDataStack: ContextManager.shared)

        activityIndicatorView.startAnimating()

        if AppConfiguration.showsFollowedSitesSettings {
            dispatchGroup.enter()
            siteService.fetchFollowedSites(success: {
                dispatchGroup.leave()
            }, failure: { (error) in
                dispatchGroup.leave()
                DDLogError("Could not sync sites: \(String(describing: error))")
            })
        }

        dispatchGroup.enter()
        service.getAllSettings({ [weak self] (settings: [NotificationSettings]) in
            self?.groupedSettings = self?.groupSettings(settings) ?? [:]
            dispatchGroup.leave()
        }, failure: { [weak self] (error: NSError?) in
            dispatchGroup.leave()
            self?.handleLoadError()
        })

        dispatchGroup.enter()
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            self?.notificationsEnabled = settings.authorizationStatus == .authorized
            dispatchGroup.leave()
        }

        dispatchGroup.notify(queue: .main) { [weak self] in
            self?.followedSites = ((try? ReaderAbstractTopic.lookupAllSites(in: ContextManager.shared.mainContext)) ?? []).filter { !$0.isExternal }
            self?.setupSections()
            self?.activityIndicatorView.stopAnimating()
            self?.tableView.reloadData()
        }
    }

    fileprivate func groupSettings(_ settings: [NotificationSettings]) -> [Section: [NotificationSettings]] {
        // Find the Default Blog ID
        let defaultAccount = try? WPAccount.lookupDefaultWordPressComAccount(in: ContextManager.shared.mainContext)
        let primaryBlogId = defaultAccount?.defaultBlog?.dotComID as? Int

        // Proceed Grouping
        var blogSettings = [NotificationSettings]()
        var otherSettings = [NotificationSettings]()
        var wpcomSettings = [NotificationSettings]()

        for setting in settings {
            switch setting.channel {
            case let .blog(blogId):
                guard setting.blog != nil else {
                    continue
                }
                // Make sure that the Primary Blog is the first one in its category
                if blogId == primaryBlogId {
                    blogSettings.insert(setting, at: 0)
                } else {
                    blogSettings.append(setting)
                }
            case .other:
                otherSettings.append(setting)
            case .wordPressCom:
                wpcomSettings.append(setting)
            }
        }

        assert(otherSettings.count == 1)
        assert(wpcomSettings.count == 1)

        // Sections: Blogs + Other + WpCom
        return [.blog: blogSettings, .other: otherSettings, .wordPressCom: wpcomSettings]
    }

    // Setup the table sections using the Section enumeration
    //
    fileprivate func setupSections() {
        var section: [Section] = groupedSettings.isEmpty ? [] : [.blog, .other, .wordPressCom]
        if !followedSites.isEmpty && !section.isEmpty && AppConfiguration.showsFollowedSitesSettings {
            section.insert(.followedSites, at: 1)
        } else if !followedSites.isEmpty && section.isEmpty && AppConfiguration.showsFollowedSitesSettings {
            section.append(.followedSites)
        }

        if JetpackNotificationMigrationService.shared.shouldShowNotificationControl() && notificationsEnabled {
            section.insert(.notificationControl, at: 0)
        }

        tableSections = section
    }

    // Get a valid Section from a setion index
    //
    fileprivate func section(at index: Int) -> Section {
        return tableSections[index]
    }


    // MARK: - Error Handling

    fileprivate func handleLoadError() {
        let title = NSLocalizedString("Oops!", comment: "An informal exclaimation meaning `something went wrong`.")
        let message = NSLocalizedString("There has been a problem while loading your Notification Settings",
                                            comment: "Displayed after Notification Settings failed to load")
        let cancelText = NSLocalizedString("Cancel", comment: "Cancel. Action.")
        let retryText = NSLocalizedString("Try Again", comment: "Try Again. Action")

        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        alertController.addCancelActionWithTitle(cancelText) { (action: UIAlertAction) in
            _ = self.navigationController?.popViewController(animated: true)
        }

        alertController.addDefaultActionWithTitle(retryText) { (action: UIAlertAction) in
            self.reloadSettings()
        }

        present(alertController, animated: true)
    }
}

// MARK: - UITableView Datasource Methods
extension NotificationSettingsViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return tableSections.count
    }

    @objc open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = self.section(at: section)
        switch section {
        case .blog where requiresBlogsPagination:
            return displayBlogMoreWasAccepted ? rowCountForBlogSection + 1 : loadMoreRowCount
        case .followedSites:
            return displayFollowedMoreWasAccepted ? rowCountForFollowedSite + 1 : min(loadMoreRowCount, rowCountForFollowedSite)
        case .notificationControl:
            return 1
        default:
            return groupedSettings[section]?.count ?? 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = reusableIdentifierForIndexPath(indexPath)

        let cell = tableView.dequeueReusableCell(withIdentifier: identifier)!

        configureCell(cell, indexPath: indexPath)

        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // Hide when the section is empty!
        if isSectionEmpty(section) {
            return nil
        }

        let theSection = self.section(at: section)
        return theSection.headerText()
    }
}

// MARK: - UITableView Delegate Methods
extension NotificationSettingsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isPaginationRow(indexPath) {
            toggleDisplayMore(at: indexPath)
        } else if let siteTopic = siteTopic(at: indexPath) {
            displayDetails(for: siteTopic.siteID.intValue)
        } else if let settings = settingsForRowAtIndexPath(indexPath) {
            displayDetailsForSettings(settings)
        } else {
            tableView.deselectSelectedRowWithAnimation(true)
        }
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let currentSection = self.section(at: section)

        guard !isSectionEmpty(section), let text = currentSection.footerText() else {
            return nil
        }
        return makeFooterView(showBadge: currentSection.showBadge, text: text)
    }
}

// MARK: - UITableView Helpers
private extension NotificationSettingsViewController {

    /// Creates a label to be inserted in the sites section footer
    /// - Parameter text: the text of the label
    /// - Returns: the label
    func makeFooterLabelView(text: String) -> UIView {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = WPStyleGuide.fontForTextStyle(.footnote)
        label.numberOfLines = 0
        label.text = text
        label.textColor = .secondaryLabel

        let labelView = UIView()
        labelView.addSubview(label)
        labelView.pinSubviewToAllEdges(label, insets: FooterMetrics.footerLabelInsets)
        return labelView
    }


    /// Creates the footer for the my sites section
    /// - Parameter text: the text to be used in the label
    /// - Returns: the footer view
    func makeFooterView(showBadge: Bool = false, text: String) -> UIView {
        let labelView = makeFooterLabelView(text: text)

        guard showBadge else {
            return labelView
        }

        labelView.translatesAutoresizingMaskIntoConstraints = false

        let textProvider = JetpackBrandingTextProvider(screen: JetpackBadgeScreen.notificationsSettings)
        let badgeView = JetpackButton.makeBadgeView(title: textProvider.brandingText(),
                                                    topPadding: FooterMetrics.jetpackBadgeTopPadding,
                                                    bottomPadding: FooterMetrics.jetpackBadgeBottomPatting,
                                                    target: self,
                                                    selector: #selector(jetpackButtonTapped))
        badgeView.translatesAutoresizingMaskIntoConstraints = false

        let stackView = UIStackView(arrangedSubviews: [labelView, badgeView])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical

        let view = UIView()
        view.addSubview(stackView)
        view.pinSubviewToAllEdges(stackView)
        return view
    }

    func reusableIdentifierForIndexPath(_ indexPath: IndexPath) -> String {
        switch section(at: indexPath.section) {
        case .blog where !isPaginationRow(indexPath), .followedSites where !isPaginationRow(indexPath):
            return blogReuseIdentifier
        case .notificationControl:
            return switchReuseIdentifier
        default:
            return defaultReuseIdentifier
        }
    }

    func configureCell(_ cell: UITableViewCell, indexPath: IndexPath) {
        // Pagination Rows don't really have a Settings entity
        if isPaginationRow(indexPath) {
            cell.textLabel?.text = paginationRowDescription(indexPath)
            cell.textLabel?.textAlignment = .natural
            cell.accessoryType = .none
            WPStyleGuide.configureTableViewCell(cell)
            return
        }

        if let site = siteTopic(at: indexPath) {
            cell.imageView?.image = .siteIconPlaceholder

            cell.accessoryType = .disclosureIndicator
            cell.imageView?.backgroundColor = .neutral(.shade5)

            cell.textLabel?.text = site.title
            cell.detailTextLabel?.text = URL(string: site.siteURL)?.host
            cell.imageView?.downloadSiteIcon(at: site.siteBlavatar)

            WPStyleGuide.configureTableViewSmallSubtitleCell(cell)
            cell.layoutSubviews()
            return
        }

        if let cell = cell as? SwitchTableViewCell {
            configureNotificationSwitchCell(cell)
            return
        }

        // Proceed rendering the settings
        guard let settings = settingsForRowAtIndexPath(indexPath) else {
            return
        }

        switch settings.channel {
        case .blog:
            cell.textLabel?.text = settings.blog?.settings?.name ?? settings.channel.description()
            cell.detailTextLabel?.text = settings.blog?.displayURL as String? ?? String()
            cell.accessoryType = .disclosureIndicator

            if let blog = settings.blog {
                cell.imageView?.downloadSiteIcon(for: blog)
            } else {
                cell.imageView?.image = .siteIconPlaceholder
            }

            WPStyleGuide.configureTableViewSmallSubtitleCell(cell)

        default:
            cell.textLabel?.text = settings.channel.description()
            cell.textLabel?.textAlignment = .natural
            cell.accessoryType = .disclosureIndicator
            WPStyleGuide.configureTableViewCell(cell)
        }
    }

    func siteTopic(at index: IndexPath) -> ReaderSiteTopic? {
        guard !followedSites.isEmpty,
              index.row <= (followedSites.count - 1) else {
            return nil
        }

        switch section(at: index.section) {
        case .followedSites:
            return followedSites[index.row]

        default:
            return nil
        }
    }

    func settingsForRowAtIndexPath(_ indexPath: IndexPath) -> NotificationSettings? {
        let section = self.section(at: indexPath.section)
        guard let settings = groupedSettings[section] else {
            return nil
        }

        return settings[indexPath.row]
    }

    func isSectionEmpty(_ sectionIndex: Int) -> Bool {
        let section = self.section(at: sectionIndex)
        switch section {
        case .followedSites:
            return followedSites.isEmpty

        default:
            return groupedSettings[section]?.count == 0
        }
    }

    enum Section: Int {
        case blog
        case followedSites
        case other
        case wordPressCom
        case notificationControl

        func headerText() -> String? {
            switch self {
            case .blog:
                return NSLocalizedString("Your Sites", comment: "Displayed in the Notification Settings View")
            case .followedSites:
                return NSLocalizedString("Followed Sites", comment: "Displayed in the Notification Settings View")
            case .other:
                return NSLocalizedString("Other", comment: "Displayed in the Notification Settings View")
            case .wordPressCom:
                return nil
            case .notificationControl:
                return nil
            }
        }

        func footerText() -> String? {
            switch self {
            case .blog:
                return NSLocalizedString("Customize your site settings for Likes, Comments, Follows, and more.",
                                         comment: "Notification Settings for your own blogs")
            case .followedSites:
                return NSLocalizedString("Customize your followed site settings for New Posts and Comments",
                                         comment: "Notification Settings for your followed sites")
            case .other:
                return nil
            case .wordPressCom:
                return NSLocalizedString("We’ll always send important emails regarding your account, " +
                                         "but you can get some helpful extras, too.",
                                         comment: "Title displayed in the Notification Settings for WordPress.com")
            case .notificationControl:
                return NSLocalizedString("Turning the switch off will disable all notifications from this app, regardless of type.",
                                         comment: "Notification Settings switch for the app.")
            }
        }

        var showBadge: Bool {
            switch self {
            case .blog:
                return JetpackBrandingVisibility.all.enabled
            default:
                return false
            }
        }
    }

    enum FooterMetrics {
        static let footerLabelInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        static let jetpackBadgeTopPadding: CGFloat = 22
        static let jetpackBadgeBottomPatting: CGFloat = 8
    }
}

// MARK: - Load More Helpers
extension NotificationSettingsViewController {

    fileprivate var rowCountForFollowedSite: Int {
        return followedSites.count
    }

    fileprivate var requiresFollowedSitesPagination: Bool {
        return rowCountForFollowedSite > loadMoreRowIndex
    }

    fileprivate var rowCountForBlogSection: Int {
        return groupedSettings[.blog]?.count ?? 0
    }

    fileprivate var requiresBlogsPagination: Bool {
        return rowCountForBlogSection > loadMoreRowIndex
    }

    fileprivate func isDisplayMoreRow(_ path: IndexPath) -> Bool {
        let section = self.section(at: path.section)
        switch section {
        case .blog:
            let isDisplayMoreRow = path.row == loadMoreRowIndex
            return requiresFollowedSitesPagination && !displayBlogMoreWasAccepted && isDisplayMoreRow

        case .followedSites:
            let isDisplayMoreRow = path.row == loadMoreRowIndex
            return requiresFollowedSitesPagination && !displayFollowedMoreWasAccepted && isDisplayMoreRow

        default: return false
        }
    }

    fileprivate func isDisplayLessRow(_ path: IndexPath) -> Bool {
        let section = self.section(at: path.section)
        switch section {
        case .blog:
            let rowCount = rowCountForBlogSection
            let isDisplayLessRow = path.row == rowCount
            return requiresBlogsPagination && displayBlogMoreWasAccepted && isDisplayLessRow

        case .followedSites:
            let rowCount = rowCountForFollowedSite
            let isDisplayLessRow = path.row == rowCount
            return requiresFollowedSitesPagination && displayFollowedMoreWasAccepted && isDisplayLessRow

        default: return false
        }
    }

    fileprivate func isPaginationRow(_ path: IndexPath) -> Bool {
        return isDisplayMoreRow(path) || isDisplayLessRow(path)
    }

    fileprivate func paginationRowDescription(_ path: IndexPath) -> String {
        if isDisplayMoreRow(path) {
            return NSLocalizedString("View all…", comment: "Displays More Rows")
        }

        return NSLocalizedString("View less…", comment: "Displays Less Rows")
    }

    fileprivate func toggleDisplayMore(at index: IndexPath) {
        let section = self.section(at: index.section)
        switch section {
        case .blog:
            displayBlogMoreWasAccepted = !displayBlogMoreWasAccepted

        case .followedSites:
            displayFollowedMoreWasAccepted = !displayFollowedMoreWasAccepted

        default:
            return
        }
        // And refresh the section
        let sections = IndexSet(integer: index.section)
        tableView.reloadSections(sections, with: .fade)
    }
}

// MARK: - Navigation
private extension NotificationSettingsViewController {

    func displayDetails(for siteId: Int) {
        let siteSubscriptionsViewController = NotificationSiteSubscriptionViewController(siteId: siteId)
        navigationController?.pushViewController(siteSubscriptionsViewController, animated: true)
    }

    func displayDetailsForSettings(_ settings: NotificationSettings) {
        switch settings.channel {
        case .wordPressCom:
            // WordPress.com Row will push the SettingDetails ViewController, directly
            let detailsViewController = NotificationSettingDetailsViewController(settings: settings)
            navigationController?.pushViewController(detailsViewController, animated: true)
        default:
            // Our Sites + 3rd Party Sites rows will push the Streams View
            let streamsViewController = NotificationSettingStreamsViewController(settings: settings)
            navigationController?.pushViewController(streamsViewController, animated: true)
        }
    }

    @objc func jetpackButtonTapped() {
        JetpackBrandingCoordinator.presentOverlay(from: self)
        JetpackBrandingAnalyticsHelper.trackJetpackPoweredBadgeTapped(screen: .notificationsSettings)
    }
}

// MARK: - SearchableActivity Conformance
extension NotificationSettingsViewController: SearchableActivityConvertable {

    var activityType: String {
        return WPActivityType.notificationSettings.rawValue
    }

    var activityTitle: String {
        return NSLocalizedString("Notification Settings", comment: "Title of the 'Notification Settings' screen within the 'Me' tab - used for spotlight indexing on iOS.")
    }

    var activityKeywords: Set<String>? {
        let keyWordString = NSLocalizedString("wordpress, me, notification, notification settings, settings, comments, email, ping, follow, customize, customise",
                                              comment: "This is a comma separated list of keywords used for spotlight indexing of the 'Notification Settings' screen within the 'Me' tab.")
        let keywordArray = keyWordString.arrayOfTags()

        guard !keywordArray.isEmpty else {
            return nil
        }
        return Set(keywordArray)
    }
}

// MARK: - Notification Switch Cell
extension NotificationSettingsViewController {
    private func configureNotificationSwitchCell(_ cell: SwitchTableViewCell) {
        cell.name = NSLocalizedString("Allow Notifications", comment: "Title for a cell with switch control that allows to enable or disable notifications")
        cell.on = JetpackNotificationMigrationService.shared.wordPressNotificationsEnabled
        cell.onChange = { newValue in
            JetpackNotificationMigrationService.shared.wordPressNotificationsEnabled = newValue
        }
    }
}
