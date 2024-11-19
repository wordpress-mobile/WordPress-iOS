import Foundation
import UIKit
import WordPressShared

/// The purpose of this class is to render the Discussion Settings associated to a site, and
/// allow the user to tune those settings, as required.
///
open class DiscussionSettingsViewController: UITableViewController {
    private let tracksDiscussionSettingsKey = "site_settings_discussion"
    private var isChangingSettings = false
    private var isSettingsChangeNeeded = false

    // MARK: - Initializers / Deinitializers
    @objc public convenience init(blog: Blog) {
        self.init(style: .insetGrouped)
        self.blog = blog
    }

    // MARK: - View Lifecycle
    open override func viewDidLoad() {
        super.viewDidLoad()

        setupNavBar()
        setupTableView()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        tableView.reloadSelectedRow()
        tableView.deselectSelectedRowWithAnimation(true)
        refreshSettings()
    }

    // MARK: - Setup Helpers
    private func setupNavBar() {
        title = NSLocalizedString("Discussion", comment: "Title for the Discussion Settings Screen")
    }

    private func setupTableView() {
        WPStyleGuide.configureColors(view: view, tableView: tableView)
        WPStyleGuide.configureAutomaticHeightRows(for: tableView)
        tableView.cellLayoutMarginsFollowReadableWidth = true

        // Note: We really want to handle 'Unselect' manually.
        // Reason: we always reload previously selected rows.
        clearsSelectionOnViewWillAppear = false
    }

    // MARK: - Persistance!
    private func refreshSettings() {
        let service = BlogService(coreDataStack: ContextManager.shared)
        service.syncSettings(for: blog, success: { [weak self] in
            self?.tableView.reloadData()
            DDLogInfo("Reloaded Settings")
        }, failure: { (error: Error) in
            DDLogError("Error while sync'ing blog settings: \(error)")
        })
    }

    private func setNeedsChangeSettings() {
        isSettingsChangeNeeded = true
        saveSettingsIfNeeded()
    }

    private func saveSettingsIfNeeded() {
        guard !isChangingSettings && isSettingsChangeNeeded else {
            return
        }
        isChangingSettings = true
        isSettingsChangeNeeded = false
        navigationItem.rightBarButtonItem = .activityIndicator

        let service = BlogService(coreDataStack: ContextManager.shared)
        service.updateSettings(for: blog, success: { [weak self] in
            self?.didFinishChangingSettings(nil)
        }, failure: { [weak self] error -> Void in
            self?.didFinishChangingSettings(error)
        })
    }

    private func didFinishChangingSettings(_ error: Error?) {
        isChangingSettings = false
        if isSettingsChangeNeeded {
            saveSettingsIfNeeded()
        } else {
            navigationItem.rightBarButtonItem = nil
        }
        if let error {
            DDLogError("Error while persisting settings: \(error)")
            let alert = UIAlertController(title: Strings.errorTitle, message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(.init(title: SharedStrings.Button.ok, style: .default, handler: nil))
            present(alert, animated: true)
        }
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
        case .switch:
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
    private func rowAtIndexPath(_ indexPath: IndexPath) -> Row {
        return sections[indexPath.section].rows[indexPath.row]
    }

    private func cellForRow(_ row: Row, tableView: UITableView) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: row.style.rawValue) {
            return cell
        }
        switch row.style {
        case .value1:
            return WPTableViewCell(style: .value1, reuseIdentifier: row.style.rawValue)
        case .switch:
            return SwitchTableViewCell(style: .default, reuseIdentifier: row.style.rawValue)
        }
    }

    private func configureTextCell(_ cell: WPTableViewCell, row: Row) {
        cell.textLabel?.text = row.title ?? String()
        cell.detailTextLabel?.text = row.details ?? String()
        cell.accessoryType = .disclosureIndicator
        WPStyleGuide.configureTableViewCell(cell)
    }

    private func configureSwitchCell(_ cell: SwitchTableViewCell, row: Row) {
        cell.name = row.title ?? String()
        cell.on = row.boolValue ?? true
        cell.onChange = { (newValue: Bool) in
            row.handler?(newValue as AnyObject?)
        }
    }

    // MARK: - Row Handlers
    private func pressedCommentsAllowed(_ payload: AnyObject?) {
        guard let enabled = payload as? Bool else {
            return
        }
        didChangeSetting("allow_comments", value: enabled as Any)
        settings.commentsAllowed = enabled
    }

    private func pressedPingbacksInbound(_ payload: AnyObject?) {
        guard let enabled = payload as? Bool else {
            return
        }
        didChangeSetting("receive_pingbacks", value: enabled as Any)
        settings.pingbackInboundEnabled = enabled
    }

    private func pressedPingbacksOutbound(_ payload: AnyObject?) {
        guard let enabled = payload as? Bool else {
            return
        }
        didChangeSetting("send_pingbacks", value: enabled as Any)
        settings.pingbackOutboundEnabled = enabled
    }

    private func pressedRequireNameAndEmail(_ payload: AnyObject?) {
        guard let enabled = payload as? Bool else {
            return
        }
        didChangeSetting("require_name_and_email", value: enabled as Any)
        settings.commentsRequireNameAndEmail = enabled
    }

    private func pressedRequireRegistration(_ payload: AnyObject?) {
        guard let enabled = payload as? Bool else {
            return
        }
        didChangeSetting("require_registration", value: enabled as Any)
        settings.commentsRequireRegistration = enabled
    }

    private func pressedCloseCommenting(_ payload: AnyObject?) {
        let pickerViewController = SettingsPickerViewController(style: .insetGrouped)
        pickerViewController.title = NSLocalizedString("Close commenting", comment: "Close Comments Title")
        pickerViewController.switchVisible = true
        pickerViewController.switchOn = settings.commentsCloseAutomatically
        pickerViewController.switchText = NSLocalizedString("Automatically Close", comment: "Discussion Settings")
        pickerViewController.selectionText = NSLocalizedString("Close after", comment: "Close comments after a given number of days")
        pickerViewController.selectionFormat = NSLocalizedString("%d days", comment: "Number of days")
        pickerViewController.pickerHint = NSLocalizedString("Automatically close comments on content after a certain number of days.", comment: "Discussion Settings: Comments Auto-close")
        pickerViewController.pickerFormat = NSLocalizedString("%d days", comment: "Number of days")
        pickerViewController.pickerMinimumValue = commentsAutocloseMinimumValue
        pickerViewController.pickerMaximumValue = commentsAutocloseMaximumValue
        pickerViewController.pickerSelectedValue = settings.commentsCloseAutomaticallyAfterDays as? Int
        pickerViewController.onChange = { [weak self] (enabled: Bool, newValue: Int) in
            self?.settings.commentsCloseAutomatically = enabled
            self?.settings.commentsCloseAutomaticallyAfterDays = newValue as NSNumber

            let value: Any = enabled ? newValue : "disabled"
            self?.didChangeSetting("close_commenting", value: value)
        }
        navigationController?.pushViewController(pickerViewController, animated: true)
    }

    private func pressedSortBy(_ payload: AnyObject?) {
        let settingsViewController = SettingsSelectionViewController(style: .insetGrouped)
        settingsViewController.title = NSLocalizedString("Sort By", comment: "Discussion Settings Title")
        settingsViewController.currentValue = settings.commentsSortOrder
        settingsViewController.titles = CommentsSorting.allTitles
        settingsViewController.values = CommentsSorting.allValues
        settingsViewController.onItemSelected = { [weak self] (selected: Any?) in
            guard let newSortOrder = CommentsSorting(rawValue: selected as! Int) else {
                return
            }
            self?.didChangeSetting("comments_sort_by", value: selected as Any)
            self?.settings.commentsSorting = newSortOrder
        }
        navigationController?.pushViewController(settingsViewController, animated: true)
    }

    private func pressedThreading(_ payload: AnyObject?) {
        let settingsViewController = SettingsSelectionViewController(style: .insetGrouped)
        settingsViewController.title = NSLocalizedString("Threading", comment: "Discussion Settings Title")
        settingsViewController.currentValue = settings.commentsThreading.rawValue as NSObject
        settingsViewController.titles = CommentsThreading.allTitles
        settingsViewController.values = CommentsThreading.allValues
        settingsViewController.onItemSelected = { [weak self] (selected: Any?) in
            guard let newThreadingDepth = CommentsThreading(rawValue: selected as! Int) else {
                return
            }
            self?.settings.commentsThreading = newThreadingDepth
            self?.didChangeSetting("comments_threading", value: selected as Any)
        }
        navigationController?.pushViewController(settingsViewController, animated: true)
    }

    private func pressedPaging(_ payload: AnyObject?) {
        let pickerViewController = SettingsPickerViewController(style: .insetGrouped)
        pickerViewController.title = NSLocalizedString("Paging", comment: "Comments Paging")
        pickerViewController.switchVisible = true
        pickerViewController.switchOn = settings.commentsPagingEnabled
        pickerViewController.switchText = NSLocalizedString("Paging", comment: "Discussion Settings")
        pickerViewController.selectionText = NSLocalizedString("Comments per page", comment: "A label title.")
        pickerViewController.pickerHint = NSLocalizedString("Break comment threads into multiple pages.", comment: "Text snippet summarizing what comment paging does.")
        pickerViewController.pickerMinimumValue = commentsPagingMinimumValue
        pickerViewController.pickerMaximumValue = commentsPagingMaximumValue
        pickerViewController.pickerSelectedValue = settings.commentsPageSize as? Int
        pickerViewController.onChange = { [weak self] (enabled: Bool, newValue: Int) in
            self?.settings.commentsPagingEnabled = enabled
            self?.settings.commentsPageSize = newValue as NSNumber

            let value: Any = enabled ? newValue : "disabled"
            self?.didChangeSetting("comments_paging", value: value)
        }
        navigationController?.pushViewController(pickerViewController, animated: true)
    }

    private func pressedAutomaticallyApprove(_ payload: AnyObject?) {
        let settingsViewController = SettingsSelectionViewController(style: .insetGrouped)
        settingsViewController.title = NSLocalizedString("Automatically Approve", comment: "Discussion Settings Title")
        settingsViewController.currentValue = settings.commentsAutoapproval.rawValue as NSObject
        settingsViewController.titles = CommentsAutoapproval.allTitles
        settingsViewController.values = CommentsAutoapproval.allValues
        settingsViewController.hints = CommentsAutoapproval.allHints
        settingsViewController.onItemSelected = { [weak self] (selected: Any?) in
            guard let newApprovalStatus = CommentsAutoapproval(rawValue: selected as! Int) else {
                return
            }
            self?.settings.commentsAutoapproval = newApprovalStatus
            self?.didChangeSetting("comments_automatically_approve", value: selected as Any)
        }
        navigationController?.pushViewController(settingsViewController, animated: true)
    }

    private func pressedLinksInComments(_ payload: AnyObject?) {
        let pickerViewController = SettingsPickerViewController(style: .insetGrouped)
        pickerViewController.title = NSLocalizedString("Links in comments", comment: "Comments Paging")
        pickerViewController.switchVisible = false
        pickerViewController.selectionText = NSLocalizedString("Links in comments", comment: "A label title")
        pickerViewController.pickerHint = NSLocalizedString("Require manual approval for comments that include more than this number of links.", comment: "An explaination of a setting.")
        pickerViewController.pickerMinimumValue = commentsLinksMinimumValue
        pickerViewController.pickerMaximumValue = commentsLinksMaximumValue
        pickerViewController.pickerSelectedValue = settings.commentsMaximumLinks as? Int
        pickerViewController.onChange = { [weak self] (enabled: Bool, newValue: Int) in
            self?.settings.commentsMaximumLinks = newValue as NSNumber
            self?.didChangeSetting("comments_links", value: newValue as Any)
        }
        navigationController?.pushViewController(pickerViewController, animated: true)
    }

    private func pressedModeration(_ payload: AnyObject?) {
        let moderationKeys = settings.commentsModerationKeys
        let settingsViewController = SettingsListEditorViewController(collection: moderationKeys)
        settingsViewController.title = NSLocalizedString("Hold for Moderation", comment: "Moderation Keys Title")
        settingsViewController.insertTitle = NSLocalizedString("New Moderation Word", comment: "Moderation Keyword Insertion Title")
        settingsViewController.editTitle = NSLocalizedString("Edit Moderation Word", comment: "Moderation Keyword Edition Title")
        settingsViewController.footerText = NSLocalizedString("When a comment contains any of these words in its content, name, URL, e-mail or IP, it will be held in the moderation queue. You can enter partial words, so \"press\" will match \"WordPress\".", comment: "Text rendered at the bottom of the Discussion Moderation Keys editor")
        settingsViewController.onChange = { [weak self] (updated: Set<String>) in
            self?.settings.commentsModerationKeys = updated
            self?.didChangeSetting("comments_hold_for_moderation", value: updated.count as Any)
        }
        navigationController?.pushViewController(settingsViewController, animated: true)
    }

    private func pressedBlocklist(_ payload: AnyObject?) {
        let blocklistKeys = settings.commentsBlocklistKeys
        let settingsViewController = SettingsListEditorViewController(collection: blocklistKeys)
        settingsViewController.title = NSLocalizedString("Blocklist", comment: "Blocklist Title")
        settingsViewController.insertTitle = NSLocalizedString("New Blocklist Word", comment: "Blocklist Keyword Insertion Title")
        settingsViewController.editTitle = NSLocalizedString("Edit Blocklist Word", comment: "Blocklist Keyword Edition Title")
        settingsViewController.footerText = NSLocalizedString("When a comment contains any of these words in its content, name, URL, e-mail, or IP, it will be marked as spam. You can enter partial words, so \"press\" will match \"WordPress\".", comment: "Text rendered at the bottom of the Discussion Blocklist Keys editor")
        settingsViewController.onChange = { [weak self] (updated: Set<String>) in
            self?.settings.commentsBlocklistKeys = updated
            self?.didChangeSetting("comments_block_list", value: updated.count as Any)
        }
        navigationController?.pushViewController(settingsViewController, animated: true)
    }

    private func didChangeSetting(_ fieldName: String, value: Any?) {
        WPAnalytics.trackSettingsChange(tracksDiscussionSettingsKey, fieldName: fieldName, value: value)
        setNeedsChangeSettings()
    }

    // MARK: - Computed Properties
    private var sections: [Section] {
        return [postsSection, commentsSection, otherSection]
    }

    private var postsSection: Section {
        let headerText = NSLocalizedString("Defaults for New Posts", comment: "Discussion Settings: Posts Section")
        let footerText = NSLocalizedString("You can override these settings for individual posts.", comment: "Discussion Settings: Footer Text")
        let rows = [
            Row(style: .switch,
                title: NSLocalizedString("Allow Comments", comment: "Settings: Comments Enabled"),
                boolValue: self.settings.commentsAllowed,
                handler: { [weak self] in
                    self?.pressedCommentsAllowed($0)
                }),

            Row(style: .switch,
                title: NSLocalizedString("Send Pingbacks", comment: "Settings: Sending Pingbacks"),
                boolValue: self.settings.pingbackOutboundEnabled,
                handler: { [weak self] in
                    self?.pressedPingbacksOutbound($0)
                }),

            Row(style: .switch,
                title: NSLocalizedString("Receive Pingbacks", comment: "Settings: Receiving Pingbacks"),
                boolValue: self.settings.pingbackInboundEnabled,
                handler: { [weak self] in
                    self?.pressedPingbacksInbound($0)
                })
        ]

        return Section(headerText: headerText, footerText: footerText, rows: rows)
    }

    private var commentsSection: Section {
        let headerText = NSLocalizedString("Comments", comment: "Settings: Comment Sections")
        let rows = [
            Row(style: .switch,
                title: NSLocalizedString("Require name and email", comment: "Settings: Comments Approval settings"),
                boolValue: self.settings.commentsRequireNameAndEmail,
                handler: { [weak self] in
                    self?.pressedRequireNameAndEmail($0)
                }),

            Row(style: .switch,
                title: NSLocalizedString("Require users to log in", comment: "Settings: Comments Approval settings"),
                boolValue: self.settings.commentsRequireRegistration,
                handler: { [weak self] in
                    self?.pressedRequireRegistration($0)
                }),

            Row(style: .value1,
                title: NSLocalizedString("Close Commenting", comment: "Settings: Close comments after X period"),
                details: self.detailsForCloseCommenting,
                handler: { [weak self] in
                    self?.pressedCloseCommenting($0)
                }),

            Row(style: .value1,
                title: NSLocalizedString("Sort By", comment: "Settings: Comments Sort Order"),
                details: self.detailsForSortBy,
                handler: { [weak self] in
                    self?.pressedSortBy($0)
                }),

            Row(style: .value1,
                title: NSLocalizedString("Threading", comment: "Settings: Comments Threading preferences"),
                details: self.detailsForThreading,
                handler: { [weak self] in
                    self?.pressedThreading($0)
                }),

            Row(style: .value1,
                title: NSLocalizedString("Paging", comment: "Settings: Comments Paging preferences"),
                details: self.detailsForPaging,
                handler: { [weak self] in
                    self?.pressedPaging($0)
                }),

            Row(style: .value1,
                title: NSLocalizedString("Automatically Approve", comment: "Settings: Comments Approval settings"),
                details: self.detailsForAutomaticallyApprove,
                handler: { [weak self] in
                    self?.pressedAutomaticallyApprove($0)
                }),

            Row(style: .value1,
                title: NSLocalizedString("Links in comments", comment: "Settings: Comments Approval settings"),
                details: self.detailsForLinksInComments,
                handler: { [weak self] in
                    self?.pressedLinksInComments($0)
                }),
        ]

        return Section(headerText: headerText, rows: rows)
    }

    private var otherSection: Section {
        let rows = [
            Row(style: .value1,
                title: NSLocalizedString("Hold for Moderation", comment: "Settings: Comments Moderation"),
                handler: self.pressedModeration),

            Row(style: .value1,
                title: NSLocalizedString("Blocklist", comment: "Settings: Comments Blocklist"),
                handler: self.pressedBlocklist)
        ]

        return Section(rows: rows)
    }

    // MARK: - Row Detail Helpers
    private var detailsForCloseCommenting: String {
        if !settings.commentsCloseAutomatically {
            return NSLocalizedString("Off", comment: "Disabled")
        }

        let numberOfDays = settings.commentsCloseAutomaticallyAfterDays ?? 0
        let format = NSLocalizedString("%@ days", comment: "Number of days after which comments should autoclose")
        return String(format: format, numberOfDays)
    }

    private var detailsForSortBy: String {
        return settings.commentsSorting.description
    }

    private var detailsForThreading: String {
        if !settings.commentsThreadingEnabled {
            return NSLocalizedString("Off", comment: "Disabled")
        }

        let levels = settings.commentsThreadingDepth ?? 0
        let format = NSLocalizedString("%@ levels", comment: "Number of Threading Levels")
        return String(format: format, levels)
    }

    private var detailsForPaging: String {
        if !settings.commentsPagingEnabled {
            return NSLocalizedString("None", comment: "Disabled")
        }

        let pageSize = settings.commentsPageSize ?? 0
        let format = NSLocalizedString("%@ comments", comment: "Number of Comments per Page")
        return String(format: format, pageSize)
    }

    private var detailsForAutomaticallyApprove: String {
        switch settings.commentsAutoapproval {
        case .disabled:
            return NSLocalizedString("None", comment: "No comment will be autoapproved")
        case .everything:
            return NSLocalizedString("All", comment: "Autoapprove every comment")
        case .fromKnownUsers:
            return NSLocalizedString("Known Users", comment: "Autoapprove only from known users")
        }
    }

    private var detailsForLinksInComments: String {
        guard let numberOfLinks = settings.commentsMaximumLinks else {
            return String()
        }

        let format = NSLocalizedString("%@ links", comment: "Number of Links")
        return String(format: format, numberOfLinks)
    }

    // MARK: - Private Nested Classes
    private class Section {
        let headerText: String?
        let footerText: String?
        let rows: [Row]

        init(headerText: String? = nil, footerText: String? = nil, rows: [Row]) {
            self.headerText = headerText
            self.footerText = footerText
            self.rows = rows
        }
    }

    private class Row {
        let style: Style
        let title: String?
        let details: String?
        let handler: Handler?
        var boolValue: Bool?

        init(style: Style, title: String? = nil, details: String? = nil, boolValue: Bool? = nil, handler: Handler? = nil) {
            self.style = style
            self.title = title
            self.details = details
            self.boolValue = boolValue
            self.handler = handler
        }

        typealias Handler = ((AnyObject?) -> Void)

        enum Style: String {
            case value1 = "Value1"
            case `switch` = "SwitchCell"
        }
    }

    // MARK: - Private Properties
    private var blog: Blog!

    // MARK: - Computed Properties
    private var settings: BlogSettings {
        return blog.settings!
    }

    // MARK: - Typealiases
    private typealias CommentsSorting = BlogSettings.CommentsSorting
    private typealias CommentsThreading = BlogSettings.CommentsThreading
    private typealias CommentsAutoapproval = BlogSettings.CommentsAutoapproval

    // MARK: - Constants
    private let commentsPagingMinimumValue = 1
    private let commentsPagingMaximumValue = 100
    private let commentsLinksMinimumValue = 1
    private let commentsLinksMaximumValue = 100
    private let commentsAutocloseMinimumValue = 1
    private let commentsAutocloseMaximumValue = 120
}

private enum Strings {
    static let errorTitle = NSLocalizedString("discussionSettings.saveErrorTitle", value: "Failed to save settings", comment: "Error tilte")
}
