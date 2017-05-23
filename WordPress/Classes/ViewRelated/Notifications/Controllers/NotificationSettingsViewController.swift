import Foundation
import WordPressShared.WPStyleGuide
import WordPressComAnalytics


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



    // MARK: - Setup Helpers
    fileprivate func setupNavigationItem() {
        title = NSLocalizedString("Notifications", comment: "Title displayed in the Notification settings")
        navigationItem.backBarButtonItem = UIBarButtonItem(title: String(), style: .plain, target: nil, action: nil)
    }

    fileprivate func setupTableView() {
        // Register the cells
        tableView.register(WPBlogTableViewCell.self, forCellReuseIdentifier: blogReuseIdentifier)
        tableView.register(WPTableViewCell.self, forCellReuseIdentifier: defaultReuseIdentifier)

        // Hide the separators, whenever the table is empty
        tableView.tableFooterView = UIView()

        // Style!
        WPStyleGuide.configureColors(for: view, andTableView: tableView)
        WPStyleGuide.configureAutomaticHeightRows(for: tableView)
    }



    // MARK: - Service Helpers
    fileprivate func reloadSettings() {
        let service = NotificationSettingsService(managedObjectContext: ContextManager.sharedInstance().mainContext)

        activityIndicatorView.startAnimating()

        service.getAllSettings({ [weak self] (settings: [NotificationSettings]) in
                self?.groupedSettings = self?.groupSettings(settings)
                self?.activityIndicatorView.stopAnimating()
                self?.tableView.reloadData()
            },
            failure: { [weak self] (error: NSError?) in
                self?.handleLoadError()
            })
    }

    fileprivate func groupSettings(_ settings: [NotificationSettings]) -> [[NotificationSettings]] {
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
        return [blogSettings, otherSettings, wpcomSettings]
    }



    // MARK: - Error Handling
    fileprivate func handleLoadError() {
        let title       = NSLocalizedString("Oops!", comment: "")
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

        present(alertController, animated: true, completion: nil)
    }




    // MARK: - UITableView Datasource Methods
    open func numberOfSectionsInTableView(_ tableView: UITableView) -> Int {
        return groupedSettings?.count ?? emptyCount
    }

    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .blog where requiresBlogsPagination:
            return displayMoreWasAccepted ? rowCountForBlogSection + 1 : loadMoreRowCount
        default:
            return groupedSettings![section].count
        }
    }

    open func tableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell {
        let identifier  = reusableIdentifierForIndexPath(indexPath)
        let cell        = tableView.dequeueReusableCell(withIdentifier: identifier)!

        configureCell(cell, indexPath: indexPath)

        return cell
    }

    open func tableView(_ tableView: UITableView, heightForRowAtIndexPath indexPath: IndexPath) -> CGFloat {
        let isBlogSection   = indexPath.section == Section.blog.rawValue
        let isNotPagination = !isPaginationRow(indexPath)

        return isBlogSection && isNotPagination ? blogRowHeight : WPTableViewDefaultRowHeight
    }

    open func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // Hide when the section is empty!
        if isSectionEmpty(section) {
            return nil
        }

        let theSection      = Section(rawValue: section)!
        return theSection.headerText()
    }

    open func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        WPStyleGuide.configureTableViewSectionHeader(view)
    }

    open func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        // Hide when the section is empty!
        if isSectionEmpty(section) {
            return nil
        }

        let theSection      = Section(rawValue: section)!
        return theSection.footerText()
    }

    open func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        WPStyleGuide.configureTableViewSectionFooter(view)
    }



    // MARK: - UITableView Delegate Methods
    open func tableView(_ tableView: UITableView, didSelectRowAtIndexPath indexPath: IndexPath) {
        if isPaginationRow(indexPath) {
            toggleDisplayMoreBlogs()
        } else if let settings = settingsForRowAtIndexPath(indexPath) {
            displayDetailsForSettings(settings)
        } else {
            tableView.deselectSelectedRowWithAnimation(true)
        }
    }



    // MARK: - UITableView Helpers
    fileprivate func reusableIdentifierForIndexPath(_ indexPath: IndexPath) -> String {
        switch Section(rawValue: indexPath.section)! {
        case .blog where !isPaginationRow(indexPath):
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

        // Proceed rendering the settings
        let settings = settingsForRowAtIndexPath(indexPath)!
        switch settings.channel {
        case .blog(_):
            cell.textLabel?.text            = settings.blog?.settings?.name ?? settings.channel.description()
            cell.detailTextLabel?.text      = settings.blog?.displayURL as String? ?? String()
            cell.accessoryType              = .disclosureIndicator

            if let siteIconURL = settings.blog?.icon {
                cell.imageView?.setImageWithSiteIcon(siteIconURL)
            } else {
                cell.imageView?.image = WPStyleGuide.Notifications.blavatarPlaceholderImage
            }

            WPStyleGuide.configureTableViewSmallSubtitleCell(cell)

        default:
            cell.textLabel?.text            = settings.channel.description()
            cell.textLabel?.textAlignment   = .natural
            cell.accessoryType              = .disclosureIndicator
            WPStyleGuide.configureTableViewCell(cell)
        }
    }

    fileprivate func settingsForRowAtIndexPath(_ indexPath: IndexPath) -> NotificationSettings? {
        return groupedSettings?[indexPath.section][indexPath.row]
    }

    fileprivate func isSectionEmpty(_ sectionIndex: Int) -> Bool {
        return groupedSettings == nil || groupedSettings?[sectionIndex].count == 0
    }



    // MARK: - Load More Helpers
    fileprivate var rowCountForBlogSection: Int {
        return groupedSettings?[Section.blog.rawValue].count ?? 0
    }

    fileprivate var requiresBlogsPagination: Bool {
        return rowCountForBlogSection > loadMoreRowIndex
    }

    fileprivate func isDisplayMoreRow(_ path: IndexPath) -> Bool {
        let isDisplayMoreRow = path.section == Section.blog.rawValue && path.row == loadMoreRowIndex
        return requiresBlogsPagination && !displayMoreWasAccepted && isDisplayMoreRow
    }

    fileprivate func isDisplayLessRow(_ path: IndexPath) -> Bool {
        let isDisplayLessRow = path.section == Section.blog.rawValue && path.row == rowCountForBlogSection
        return requiresBlogsPagination && displayMoreWasAccepted && isDisplayLessRow
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

    fileprivate func toggleDisplayMoreBlogs() {
        // Remember this action!
        displayMoreWasAccepted = !displayMoreWasAccepted

        // And refresh the section
        let sections = IndexSet(integer: Section.blog.rawValue)
        tableView.reloadSections(sections, with: .fade)
    }



    // MARK: - Segue Helpers
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
        case blog           = 0
        case other          = 1
        case wordPressCom   = 2

        func headerText() -> String {
            switch self {
            case .blog:
                return NSLocalizedString("Your Sites", comment: "Displayed in the Notification Settings View")
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
    fileprivate var groupedSettings: [[NotificationSettings]]?
    fileprivate var displayMoreWasAccepted          = false
}
