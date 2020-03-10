import Foundation
import CocoaLumberjack
import WordPressShared


/// The purpose of this class is to render the Discussion Settings associated to a site, and
/// allow the user to tune those settings, as required.
///
open class DiscussionSettingsViewController: UITableViewController {
    // MARK: - Initializers / Deinitializers
    @objc public convenience init(blog: Blog) {
        self.init(style: .grouped)
        self.blog = blog
    }

    // MARK: - View Lifecycle
    open override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
        setupTableView()
        setupNotificationListeners()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadSelectedRow()
        tableView.deselectSelectedRowWithAnimation(true)
        refreshSettings()
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        saveSettingsIfNeeded()
    }



    // MARK: - Setup Helpers
    fileprivate func setupNavBar() {
        title = NSLocalizedString("Discussion", comment: "Title for the Discussion Settings Screen")
    }

    fileprivate func setupTableView() {
        WPStyleGuide.configureColors(view: view, tableView: tableView)
        WPStyleGuide.configureAutomaticHeightRows(for: tableView)

        // Note: We really want to handle 'Unselect' manually.
        // Reason: we always reload previously selected rows.
        clearsSelectionOnViewWillAppear = false
    }

    fileprivate func setupNotificationListeners() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(DiscussionSettingsViewController.handleContextDidChange(_:)),
            name: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
            object: settings.managedObjectContext)
    }



    // MARK: - Persistance!
    fileprivate func refreshSettings() {
        let service = BlogService(managedObjectContext: settings.managedObjectContext!)
        service.syncSettings(for: blog,
            success: { [weak self] in
                self?.tableView.reloadData()
                DDLogInfo("Reloaded Settings")
            },
            failure: { (error: Error) in
                DDLogError("Error while sync'ing blog settings: \(error)")
            })
    }

    fileprivate func saveSettingsIfNeeded() {
        if !settings.hasChanges {
            return
        }

        let service = BlogService(managedObjectContext: settings.managedObjectContext!)
        service.updateSettings(for: blog,
            success: nil,
            failure: { (error: Error) -> Void in
                DDLogError("Error while persisting settings: \(error)")
        })
    }

    @objc open func handleContextDidChange(_ note: Foundation.Notification) {
        guard let context = note.object as? NSManagedObjectContext else {
            return
        }

        if !context.updatedObjects.contains(settings) {
            return
        }

        saveSettingsIfNeeded()
    }



    // MARK: - UITableViewDataSoutce Methods
    open override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rowAtIndexPath(indexPath)
        let cell = cellForRow(row, tableView: tableView)

        switch row.style {
        case .Switch:
            configureSwitchCell(cell as! SwitchTableViewCell, row: row)
        default:
            configureTextCell(cell as! WPTableViewCell, row: row)
        }

        return cell
    }

    open override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].headerText
    }

    open override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return sections[section].footerText
    }

    open override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        WPStyleGuide.configureTableViewSectionFooter(view)
    }



    // MARK: - UITableViewDelegate Methods
    open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        rowAtIndexPath(indexPath).handler?(tableView)
    }



    // MARK: - Cell Setup Helpers
    fileprivate func rowAtIndexPath(_ indexPath: IndexPath) -> Row {
        return sections[indexPath.section].rows[indexPath.row]
    }

    fileprivate func cellForRow(_ row: Row, tableView: UITableView) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: row.style.rawValue) {
            return cell
        }

        switch row.style {
        case .Value1:
            return WPTableViewCell(style: .value1, reuseIdentifier: row.style.rawValue)
        case .Switch:
            return SwitchTableViewCell(style: .default, reuseIdentifier: row.style.rawValue)
        }
    }

    fileprivate func configureTextCell(_ cell: WPTableViewCell, row: Row) {
        cell.textLabel?.text        = row.title ?? String()
        cell.detailTextLabel?.text  = row.details ?? String()
        cell.accessoryType          = .disclosureIndicator
        WPStyleGuide.configureTableViewCell(cell)
    }

    fileprivate func configureSwitchCell(_ cell: SwitchTableViewCell, row: Row) {
        cell.name                   = row.title ?? String()
        cell.on                     = row.boolValue ?? true
        cell.onChange               = { (newValue: Bool) in
            row.handler?(newValue as AnyObject?)
        }
    }



    // MARK: - Row Handlers
    fileprivate func pressedCommentsAllowed(_ payload: AnyObject?) {
        guard let enabled = payload as? Bool else {
            return
        }

        settings.commentsAllowed = enabled
    }

    fileprivate func pressedPingbacksInbound(_ payload: AnyObject?) {
        guard let enabled = payload as? Bool else {
            return
        }

        settings.pingbackInboundEnabled = enabled
    }

    fileprivate func pressedPingbacksOutbound(_ payload: AnyObject?) {
        guard let enabled = payload as? Bool else {
            return
        }

        settings.pingbackOutboundEnabled = enabled
    }

    fileprivate func pressedRequireNameAndEmail(_ payload: AnyObject?) {
        guard let enabled = payload as? Bool else {
            return
        }

        settings.commentsRequireNameAndEmail = enabled
    }

    fileprivate func pressedRequireRegistration(_ payload: AnyObject?) {
        guard let enabled = payload as? Bool else {
            return
        }

        settings.commentsRequireRegistration = enabled
    }

    fileprivate func pressedCloseCommenting(_ payload: AnyObject?) {
        let pickerViewController                = SettingsPickerViewController(style: .grouped)
        pickerViewController.title              = NSLocalizedString("Close commenting", comment: "Close Comments Title")
        pickerViewController.switchVisible      = true
        pickerViewController.switchOn           = settings.commentsCloseAutomatically
        pickerViewController.switchText         = NSLocalizedString("Automatically Close", comment: "Discussion Settings")
        pickerViewController.selectionText      = NSLocalizedString("Close after", comment: "Close comments after a given number of days")
        pickerViewController.selectionFormat    = NSLocalizedString("%d days", comment: "Number of days")
        pickerViewController.pickerHint         = NSLocalizedString("Automatically close comments on content after a certain number of days.", comment: "Discussion Settings: Comments Auto-close")
        pickerViewController.pickerFormat       = NSLocalizedString("%d days", comment: "Number of days")
        pickerViewController.pickerMinimumValue = commentsAutocloseMinimumValue
        pickerViewController.pickerMaximumValue = commentsAutocloseMaximumValue
        pickerViewController.pickerSelectedValue = settings.commentsCloseAutomaticallyAfterDays as? Int
        pickerViewController.onChange           = { [weak self] (enabled: Bool, newValue: Int) in
            self?.settings.commentsCloseAutomatically = enabled
            self?.settings.commentsCloseAutomaticallyAfterDays = newValue as NSNumber
        }

        navigationController?.pushViewController(pickerViewController, animated: true)
    }

    fileprivate func pressedSortBy(_ payload: AnyObject?) {
        let settingsViewController              = SettingsSelectionViewController(style: .grouped)
        settingsViewController.title            = NSLocalizedString("Sort By", comment: "Discussion Settings Title")
        settingsViewController.currentValue     = settings.commentsSortOrder
        settingsViewController.titles           = CommentsSorting.allTitles
        settingsViewController.values           = CommentsSorting.allValues
        settingsViewController.onItemSelected   = { [weak self] (selected: Any?) in
            guard let newSortOrder = CommentsSorting(rawValue: selected as! Int) else {
                return
            }

            self?.settings.commentsSorting = newSortOrder
        }

        navigationController?.pushViewController(settingsViewController, animated: true)
    }

    fileprivate func pressedThreading(_ payload: AnyObject?) {
        let settingsViewController              = SettingsSelectionViewController(style: .grouped)
        settingsViewController.title            = NSLocalizedString("Threading", comment: "Discussion Settings Title")
        settingsViewController.currentValue     = settings.commentsThreading.rawValue as NSObject
        settingsViewController.titles           = CommentsThreading.allTitles
        settingsViewController.values           = CommentsThreading.allValues
        settingsViewController.onItemSelected   = { [weak self] (selected: Any?) in
            guard let newThreadingDepth = CommentsThreading(rawValue: selected as! Int) else {
                return
            }

            self?.settings.commentsThreading = newThreadingDepth
        }

        navigationController?.pushViewController(settingsViewController, animated: true)
    }

    fileprivate func pressedPaging(_ payload: AnyObject?) {
        let pickerViewController                = SettingsPickerViewController(style: .grouped)
        pickerViewController.title              = NSLocalizedString("Paging", comment: "Comments Paging")
        pickerViewController.switchVisible      = true
        pickerViewController.switchOn           = settings.commentsPagingEnabled
        pickerViewController.switchText         = NSLocalizedString("Paging", comment: "Discussion Settings")
        pickerViewController.selectionText      = NSLocalizedString("Comments per page", comment: "A label title.")
        pickerViewController.pickerHint         = NSLocalizedString("Break comment threads into multiple pages.", comment: "Text snippet summarizing what comment paging does.")
        pickerViewController.pickerMinimumValue = commentsPagingMinimumValue
        pickerViewController.pickerMaximumValue = commentsPagingMaximumValue
        pickerViewController.pickerSelectedValue = settings.commentsPageSize as? Int
        pickerViewController.onChange           = { [weak self] (enabled: Bool, newValue: Int) in
            self?.settings.commentsPagingEnabled = enabled
            self?.settings.commentsPageSize = newValue as NSNumber
        }

        navigationController?.pushViewController(pickerViewController, animated: true)
    }

    fileprivate func pressedAutomaticallyApprove(_ payload: AnyObject?) {
        let settingsViewController              = SettingsSelectionViewController(style: .grouped)
        settingsViewController.title            = NSLocalizedString("Automatically Approve", comment: "Discussion Settings Title")
        settingsViewController.currentValue     = settings.commentsAutoapproval.rawValue as NSObject
        settingsViewController.titles           = CommentsAutoapproval.allTitles
        settingsViewController.values           = CommentsAutoapproval.allValues
        settingsViewController.hints            = CommentsAutoapproval.allHints
        settingsViewController.onItemSelected   = { [weak self] (selected: Any?) in
            guard let newApprovalStatus = CommentsAutoapproval(rawValue: selected as! Int) else {
                return
            }

            self?.settings.commentsAutoapproval = newApprovalStatus
        }

        navigationController?.pushViewController(settingsViewController, animated: true)
    }

    fileprivate func pressedLinksInComments(_ payload: AnyObject?) {
        let pickerViewController                = SettingsPickerViewController(style: .grouped)
        pickerViewController.title              = NSLocalizedString("Links in comments", comment: "Comments Paging")
        pickerViewController.switchVisible      = false
        pickerViewController.selectionText      = NSLocalizedString("Links in comments", comment: "A label title")
        pickerViewController.pickerHint         = NSLocalizedString("Require manual approval for comments that include more than this number of links.", comment: "An explaination of a setting.")
        pickerViewController.pickerMinimumValue = commentsLinksMinimumValue
        pickerViewController.pickerMaximumValue = commentsLinksMaximumValue
        pickerViewController.pickerSelectedValue = settings.commentsMaximumLinks as? Int
        pickerViewController.onChange           = { [weak self] (enabled: Bool, newValue: Int) in
            self?.settings.commentsMaximumLinks = newValue as NSNumber
        }

        navigationController?.pushViewController(pickerViewController, animated: true)
    }

    fileprivate func pressedModeration(_ payload: AnyObject?) {
        let moderationKeys                      = settings.commentsModerationKeys
        let settingsViewController              = SettingsListEditorViewController(collection: moderationKeys)
        settingsViewController.title            = NSLocalizedString("Hold for Moderation", comment: "Moderation Keys Title")
        settingsViewController.insertTitle      = NSLocalizedString("New Moderation Word", comment: "Moderation Keyword Insertion Title")
        settingsViewController.editTitle        = NSLocalizedString("Edit Moderation Word", comment: "Moderation Keyword Edition Title")
        settingsViewController.footerText       = NSLocalizedString("When a comment contains any of these words in its content, name, URL, e-mail or IP, it will be held in the moderation queue. You can enter partial words, so \"press\" will match \"WordPress\".",
                                                                    comment: "Text rendered at the bottom of the Discussion Moderation Keys editor")
        settingsViewController.onChange         = { [weak self] (updated: Set<String>) in
            self?.settings.commentsModerationKeys = updated
        }

        navigationController?.pushViewController(settingsViewController, animated: true)
    }

    fileprivate func pressedBlacklist(_ payload: AnyObject?) {
        let blacklistKeys                       = settings.commentsBlacklistKeys
        let settingsViewController              = SettingsListEditorViewController(collection: blacklistKeys)
        settingsViewController.title            = NSLocalizedString("Blacklist", comment: "Blacklist Title")
        settingsViewController.insertTitle      = NSLocalizedString("New Blacklist Word", comment: "Blacklist Keyword Insertion Title")
        settingsViewController.editTitle        = NSLocalizedString("Edit Blacklist Word", comment: "Blacklist Keyword Edition Title")
        settingsViewController.footerText       = NSLocalizedString("When a comment contains any of these words in its content, name, URL, e-mail, or IP, it will be marked as spam. You can enter partial words, so \"press\" will match \"WordPress\".",
                                                                    comment: "Text rendered at the bottom of the Discussion Blacklist Keys editor")
        settingsViewController.onChange         = { [weak self] (updated: Set<String>) in
            self?.settings.commentsBlacklistKeys = updated
        }

        navigationController?.pushViewController(settingsViewController, animated: true)
    }



    // MARK: - Computed Properties
    fileprivate var sections: [Section] {
        return [postsSection, commentsSection, otherSection]
    }

    fileprivate var postsSection: Section {
        let headerText = NSLocalizedString("Defaults for New Posts", comment: "Discussion Settings: Posts Section")
        let footerText = NSLocalizedString("You can override these settings for individual posts.", comment: "Discussion Settings: Footer Text")
        let rows = [
            Row(style: .Switch,
                title: NSLocalizedString("Allow Comments", comment: "Settings: Comments Enabled"),
                boolValue: self.settings.commentsAllowed,
                handler: {  [weak self] in
                                self?.pressedCommentsAllowed($0)
                            }),

            Row(style: .Switch,
                title: NSLocalizedString("Send Pingbacks", comment: "Settings: Sending Pingbacks"),
                boolValue: self.settings.pingbackOutboundEnabled,
                handler: {  [weak self] in
                                self?.pressedPingbacksOutbound($0)
                            }),

            Row(style: .Switch,
                title: NSLocalizedString("Receive Pingbacks", comment: "Settings: Receiving Pingbacks"),
                boolValue: self.settings.pingbackInboundEnabled,
                handler: {  [weak self] in
                                self?.pressedPingbacksInbound($0)
                            })
        ]

        return Section(headerText: headerText, footerText: footerText, rows: rows)
    }

    fileprivate var commentsSection: Section {
        let headerText = NSLocalizedString("Comments", comment: "Settings: Comment Sections")
        let rows = [
            Row(style: .Switch,
                title: NSLocalizedString("Require name and email", comment: "Settings: Comments Approval settings"),
                boolValue: self.settings.commentsRequireNameAndEmail,
                handler: {  [weak self] in
                                self?.pressedRequireNameAndEmail($0)
                            }),

            Row(style: .Switch,
                title: NSLocalizedString("Require users to log in", comment: "Settings: Comments Approval settings"),
                boolValue: self.settings.commentsRequireRegistration,
                handler: {  [weak self] in
                                self?.pressedRequireRegistration($0)
                            }),

            Row(style: .Value1,
                title: NSLocalizedString("Close Commenting", comment: "Settings: Close comments after X period"),
                details: self.detailsForCloseCommenting,
                handler: {  [weak self] in
                                self?.pressedCloseCommenting($0)
                            }),

            Row(style: .Value1,
                title: NSLocalizedString("Sort By", comment: "Settings: Comments Sort Order"),
                details: self.detailsForSortBy,
                handler: {  [weak self] in
                                self?.pressedSortBy($0)
                            }),

            Row(style: .Value1,
                title: NSLocalizedString("Threading", comment: "Settings: Comments Threading preferences"),
                details: self.detailsForThreading,
                handler: {  [weak self] in
                                self?.pressedThreading($0)
                            }),

            Row(style: .Value1,
                title: NSLocalizedString("Paging", comment: "Settings: Comments Paging preferences"),
                details: self.detailsForPaging,
                handler: {  [weak self] in
                                self?.pressedPaging($0)
                            }),

            Row(style: .Value1,
                title: NSLocalizedString("Automatically Approve", comment: "Settings: Comments Approval settings"),
                details: self.detailsForAutomaticallyApprove,
                handler: {  [weak self] in
                                self?.pressedAutomaticallyApprove($0)
                            }),

            Row(style: .Value1,
                title: NSLocalizedString("Links in comments", comment: "Settings: Comments Approval settings"),
                details: self.detailsForLinksInComments,
                handler: {  [weak self] in
                                self?.pressedLinksInComments($0)
                            }),
        ]

        return Section(headerText: headerText, rows: rows)
    }

    fileprivate var otherSection: Section {
        let rows = [
            Row(style: .Value1,
                title: NSLocalizedString("Hold for Moderation", comment: "Settings: Comments Moderation"),
                handler: self.pressedModeration),

            Row(style: .Value1,
                title: NSLocalizedString("Blacklist", comment: "Settings: Comments Blacklist"),
                handler: self.pressedBlacklist)
        ]

        return Section(rows: rows)
    }



    // MARK: - Row Detail Helpers
    fileprivate var detailsForCloseCommenting: String {
        if !settings.commentsCloseAutomatically {
            return NSLocalizedString("Off", comment: "Disabled")
        }

        let numberOfDays = settings.commentsCloseAutomaticallyAfterDays ?? 0
        let format = NSLocalizedString("%@ days", comment: "Number of days after which comments should autoclose")
        return String(format: format, numberOfDays)
    }

    fileprivate var detailsForSortBy: String {
        return settings.commentsSorting.description
    }

    fileprivate var detailsForThreading: String {
        if !settings.commentsThreadingEnabled {
            return NSLocalizedString("Off", comment: "Disabled")
        }

        let levels = settings.commentsThreadingDepth ?? 0
        let format = NSLocalizedString("%@ levels", comment: "Number of Threading Levels")
        return String(format: format, levels)
    }

    fileprivate var detailsForPaging: String {
        if !settings.commentsPagingEnabled {
            return NSLocalizedString("None", comment: "Disabled")
        }

        let pageSize = settings.commentsPageSize ?? 0
        let format = NSLocalizedString("%@ comments", comment: "Number of Comments per Page")
        return String(format: format, pageSize)
    }

    fileprivate var detailsForAutomaticallyApprove: String {
        switch settings.commentsAutoapproval {
        case .disabled:
            return NSLocalizedString("None", comment: "No comment will be autoapproved")
        case .everything:
            return NSLocalizedString("All", comment: "Autoapprove every comment")
        case .fromKnownUsers:
            return NSLocalizedString("Known Users", comment: "Autoapprove only from known users")
        }
    }

    fileprivate var detailsForLinksInComments: String {
        guard let numberOfLinks = settings.commentsMaximumLinks else {
            return String()
        }

        let format = NSLocalizedString("%@ links", comment: "Number of Links")
        return String(format: format, numberOfLinks)
    }



    // MARK: - Private Nested Classes
    fileprivate class Section {
        let headerText: String?
        let footerText: String?
        let rows: [Row]

        init(headerText: String? = nil, footerText: String? = nil, rows: [Row]) {
            self.headerText = headerText
            self.footerText = footerText
            self.rows       = rows
        }
    }

    fileprivate class Row {
        let style: Style
        let title: String?
        let details: String?
        let handler: Handler?
        var boolValue: Bool?

        init(style: Style, title: String? = nil, details: String? = nil, boolValue: Bool? = nil, handler: Handler? = nil) {
            self.style      = style
            self.title      = title
            self.details    = details
            self.boolValue  = boolValue
            self.handler    = handler
        }

        typealias Handler = ((AnyObject?) -> Void)

        enum Style: String {
            case Value1     = "Value1"
            case Switch     = "SwitchCell"
        }
    }



    // MARK: - Private Properties
    fileprivate var blog: Blog!

    // MARK: - Computed Properties
    fileprivate var settings: BlogSettings {
        return blog.settings!
    }

    // MARK: - Typealiases
    fileprivate typealias CommentsSorting           = BlogSettings.CommentsSorting
    fileprivate typealias CommentsThreading         = BlogSettings.CommentsThreading
    fileprivate typealias CommentsAutoapproval      = BlogSettings.CommentsAutoapproval

    // MARK: - Constants
    fileprivate let commentsPagingMinimumValue      = 1
    fileprivate let commentsPagingMaximumValue      = 100
    fileprivate let commentsLinksMinimumValue       = 1
    fileprivate let commentsLinksMaximumValue       = 100
    fileprivate let commentsAutocloseMinimumValue   = 1
    fileprivate let commentsAutocloseMaximumValue   = 120
}
