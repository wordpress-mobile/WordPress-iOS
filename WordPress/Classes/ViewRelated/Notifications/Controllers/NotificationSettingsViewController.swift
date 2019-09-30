import Foundation
import WordPressShared.WPStyleGuide


/// The purpose of this class is to retrieve the collection of NotificationSettings from WordPress.com
/// Backend, and render the "Top Level" list.
/// On Row Press, we'll push the list of available Streams, which will, in turn, push the Details View
/// itself, which is in charge of rendering the actual available settings.
///
open class NotificationSettingsViewController: UIViewController {
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

        // Hide the separators, whenever the table is empty
        tableView.tableFooterView = UIView()

        // Style!
        WPStyleGuide.configureColors(view: view, tableView: tableView)
        WPStyleGuide.configureAutomaticHeightRows(for: tableView)
    }


    // MARK: - Service Helpers

    fileprivate func reloadSettings() {
        let service = NotificationSettingsService(managedObjectContext: ContextManager.sharedInstance().mainContext)

        let dispatchGroup = DispatchGroup()
        let siteService = ReaderTopicService(managedObjectContext: ContextManager.sharedInstance().mainContext)

        activityIndicatorView.startAnimating()

        dispatchGroup.enter()
        siteService.fetchFollowedSites(success: {
            dispatchGroup.leave()
        }, failure: { (error) in
            dispatchGroup.leave()
            DDLogError("Could not sync sites: \(String(describing: error))")
        })

        dispatchGroup.enter()
        service.getAllSettings({ [weak self] (settings: [NotificationSettings]) in
            self?.groupedSettings = self?.groupSettings(settings) ?? [:]
            dispatchGroup.leave()
        }, failure: { [weak self] (error: NSError?) in
            dispatchGroup.leave()
            self?.handleLoadError()
        })

        dispatchGroup.notify(queue: .main) { [weak self] in
            self?.followedSites = (siteService.allSiteTopics() ?? []).filter { !$0.isExternal }
            self?.setupSections()
            self?.activityIndicatorView.stopAnimating()
            self?.tableView.reloadData()
        }
    }

    fileprivate func groupSettings(_ settings: [NotificationSettings]) -> [Section: [NotificationSettings]] {
        // Find the Default Blog ID
        let service         = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        let defaultAccount  = service.defaultWordPressComAccount()
        let primaryBlogId   = defaultAccount?.defaultBlog?.dotComID as? Int

        // Proceed Grouping
        var blogSettings    = [NotificationSettings]()
        var otherSettings   = [NotificationSettings]()
        var wpcomSettings   = [NotificationSettings]()

        for setting in settings {
            switch setting.channel {
            case let .blog(blogId):
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
        if !followedSites.isEmpty && !section.isEmpty {
            section.insert(.followedSites, at: 1)
        } else if !followedSites.isEmpty && section.isEmpty {
            section.append(.followedSites)
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
        let title       = NSLocalizedString("Oops!", comment: "An informal exclaimation meaning `something went wrong`.")
        let message     = NSLocalizedString("There has been a problem while loading your Notification Settings",
                                            comment: "Displayed after Notification Settings failed to load")
        let cancelText  = NSLocalizedString("Cancel", comment: "Cancel. Action.")
        let retryText   = NSLocalizedString("Try Again", comment: "Try Again. Action")

        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        alertController.addCancelActionWithTitle(cancelText) { (action: UIAlertAction) in
            _ = self.navigationController?.popViewController(animated: true)
        }

        alertController.addDefaultActionWithTitle(retryText) { (action: UIAlertAction) in
            self.reloadSettings()
        }

        present(alertController, animated: true)
    }


    // MARK: - UITableView Datasource Methods

    @objc open func numberOfSectionsInTableView(_ tableView: UITableView) -> Int {
        return tableSections.count
    }

    @objc open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = self.section(at: section)
        switch section {
        case .blog where requiresBlogsPagination:
            return displayBlogMoreWasAccepted ? rowCountForBlogSection + 1 : loadMoreRowCount
        case .followedSites:
            return displayFollowedMoreWasAccepted ? rowCountForFollowedSite + 1 : min(loadMoreRowCount, rowCountForFollowedSite)
        default:
            return groupedSettings[section]?.count ?? 0
        }
    }

    @objc open func tableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell {
        let identifier  = reusableIdentifierForIndexPath(indexPath)
        let cell        = tableView.dequeueReusableCell(withIdentifier: identifier)!

        configureCell(cell, indexPath: indexPath)

        return cell
    }

    @objc open func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // Hide when the section is empty!
        if isSectionEmpty(section) {
            return nil
        }

        let theSection = self.section(at: section)
        return theSection.headerText()
    }

    @objc open func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        // Hide when the section is empty!
        if isSectionEmpty(section) {
            return nil
        }

        let theSection = self.section(at: section)
        return theSection.footerText()
    }

    @objc open func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        WPStyleGuide.configureTableViewSectionFooter(view)
    }


    // MARK: - UITableView Delegate Methods

    @objc open func tableView(_ tableView: UITableView, didSelectRowAtIndexPath indexPath: IndexPath) {
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


    // MARK: - UITableView Helpers

    fileprivate func reusableIdentifierForIndexPath(_ indexPath: IndexPath) -> String {
        switch section(at: indexPath.section) {
        case .blog where !isPaginationRow(indexPath), .followedSites where !isPaginationRow(indexPath):
            return blogReuseIdentifier
        default:
            return defaultReuseIdentifier
        }
    }

    fileprivate func configureCell(_ cell: UITableViewCell, indexPath: IndexPath) {
        // Pagination Rows don't really have a Settings entity
        if isPaginationRow(indexPath) {
            cell.textLabel?.text            = paginationRowDescription(indexPath)
            cell.textLabel?.textAlignment   = .natural
            cell.accessoryType              = .none
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

        // Proceed rendering the settings
        guard let settings = settingsForRowAtIndexPath(indexPath) else {
            return
        }

        switch settings.channel {
        case .blog:
            cell.textLabel?.text            = settings.blog?.settings?.name ?? settings.channel.description()
            cell.detailTextLabel?.text      = settings.blog?.displayURL as String? ?? String()
            cell.accessoryType              = .disclosureIndicator

            if let blog = settings.blog {
                cell.imageView?.downloadSiteIcon(for: blog)
            } else {
                cell.imageView?.image = .siteIconPlaceholder
            }

            WPStyleGuide.configureTableViewSmallSubtitleCell(cell)

        default:
            cell.textLabel?.text            = settings.channel.description()
            cell.textLabel?.textAlignment   = .natural
            cell.accessoryType              = .disclosureIndicator
            WPStyleGuide.configureTableViewCell(cell)
        }
    }

    fileprivate func siteTopic(at index: IndexPath) -> ReaderSiteTopic? {
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

    fileprivate func settingsForRowAtIndexPath(_ indexPath: IndexPath) -> NotificationSettings? {
        let section = self.section(at: indexPath.section)
        guard let settings = groupedSettings[section] else {
            return nil
        }

        return settings[indexPath.row]
    }

    fileprivate func isSectionEmpty(_ sectionIndex: Int) -> Bool {
        let section = self.section(at: sectionIndex)
        switch section {
        case .followedSites:
            return followedSites.isEmpty

        default:
            return groupedSettings[section]?.count == 0
        }
    }


    // MARK: - Load More Helpers

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


    // MARK: - Segue Helpers

    fileprivate func displayDetails(for siteId: Int) {
        let siteSubscriptionsViewController = NotificationSiteSubscriptionViewController(siteId: siteId)
        navigationController?.pushViewController(siteSubscriptionsViewController, animated: true)
    }

    fileprivate func displayDetailsForSettings(_ settings: NotificationSettings) {
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


    // MARK: - Table Sections

    fileprivate enum Section: Int {
        case blog
        case followedSites
        case other
        case wordPressCom

        func headerText() -> String {
            switch self {
            case .blog:
                return NSLocalizedString("Your Sites", comment: "Displayed in the Notification Settings View")
            case .followedSites:
                return NSLocalizedString("Followed Sites", comment: "Displayed in the Notification Settings View")
            case .other:
                return NSLocalizedString("Other", comment: "Displayed in the Notification Settings View")
            case .wordPressCom:
                return String()
            }
        }

        func footerText() -> String {
            switch self {
            case .blog:
                return NSLocalizedString("Customize your site settings for Likes, Comments, Follows, and more.",
                                         comment: "Notification Settings for your own blogs")
            case .followedSites:
                return NSLocalizedString("Customize your followed site settings for New Posts and Comments",
                                         comment: "Notification Settings for your followed sites")
            case .other:
                return String()
            case .wordPressCom:
                return NSLocalizedString("We’ll always send important emails regarding your account, " +
                    "but you can get some helpful extras, too.",
                    comment: "Title displayed in the Notification Settings for WordPress.com")
            }
        }


        // MARK: - Private Constants

        fileprivate static let paddingZero      = CGFloat(0)
        fileprivate static let paddingWordPress = CGFloat(40)
    }



    // MARK: - Private Outlets

    @IBOutlet fileprivate var tableView: UITableView!
    @IBOutlet fileprivate var activityIndicatorView: UIActivityIndicatorView!


    // MARK: - Private Constants

    fileprivate let blogReuseIdentifier             = WPBlogTableViewCell.classNameWithoutNamespaces()
    fileprivate let blogRowHeight                   = CGFloat(54.0)

    fileprivate let defaultReuseIdentifier          = WPTableViewCell.classNameWithoutNamespaces()

    fileprivate let emptyCount                      = 0
    fileprivate let loadMoreRowIndex                = 3
    fileprivate let loadMoreRowCount                = 4


    // MARK: - Private Properties

    fileprivate var groupedSettings: [Section: [NotificationSettings]] = [:]
    fileprivate var displayBlogMoreWasAccepted          = false
    fileprivate var displayFollowedMoreWasAccepted      = false
    fileprivate var followedSites: [ReaderSiteTopic] = []
    fileprivate var tableSections: [Section] = []
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
