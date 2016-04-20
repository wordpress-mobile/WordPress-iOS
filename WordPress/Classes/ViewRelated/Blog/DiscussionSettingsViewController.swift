import Foundation
import WordPressShared


/// The purpose of this class is to render the Discussion Settings associated to a site, and
/// allow the user to tune those settings, as required.

public class DiscussionSettingsViewController : UITableViewController
{
    // MARK: - Initializers / Deinitializers
    public convenience init(blog: Blog) {
        self.init(style: .Grouped)
        self.blog = blog
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    

    
    // MARK: - View Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
        setupTableView()
        setupNotificationListeners()
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadSelectedRow()
        tableView.deselectSelectedRowWithAnimation(true)
        refreshSettings()
    }
    
    public override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        saveSettingsIfNeeded()
    }
    
    
    
    // MARK: - Setup Helpers
    private func setupNavBar() {
        title = NSLocalizedString("Discussion", comment: "Title for the Discussion Settings Screen")
    }
    
    private func setupTableView() {
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
        tableView.cellLayoutMarginsFollowReadableWidth = false
        
        // Note: We really want to handle 'Unselect' manually. 
        // Reason: we always reload previously selected rows.
        clearsSelectionOnViewWillAppear = false
    }

    private func setupNotificationListeners() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "handleContextDidChange:",
            name: NSManagedObjectContextObjectsDidChangeNotification,
            object: settings.managedObjectContext)
    }
    
    

    // MARK: - Persistance!
    private func refreshSettings() {
        let service = BlogService(managedObjectContext: settings.managedObjectContext)
        service.syncSettingsForBlog(blog,
            success: { [weak self] in
                self?.tableView.reloadData()
                DDLogSwift.logInfo("Reloaded Settings")
            },
            failure: { (error: NSError!) in
                DDLogSwift.logError("Error while sync'ing blog settings: \(error)")
            })
    }
    
    private func saveSettingsIfNeeded() {
        if !settings.hasChanges {
            return
        }
        
        let service = BlogService(managedObjectContext: settings.managedObjectContext)
        service.updateSettingsForBlog(blog,
            success: nil,
            failure: { (error: NSError!) -> Void in
                DDLogSwift.logError("Error while persisting settings: \(error)")
        })
    }
    
    public func handleContextDidChange(note: NSNotification) {
        guard let context = note.object as? NSManagedObjectContext else {
            return
        }
        
        if !context.updatedObjects.contains(settings) {
            return
        }
        
        saveSettingsIfNeeded()
    }
    
    
    
    // MARK: - UITableViewDataSoutce Methods
    public override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sections.count
    }
    
    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }
    
    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
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
    
    public override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let headerText = sections[section].headerText else {
            return CGFloat.min
        }
        
        return WPTableViewSectionHeaderFooterView.heightForHeader(headerText, width: tableView.bounds.width)
    }
    
    public override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerText = sections[section].headerText else {
            return nil
        }
        
        let footerView = WPTableViewSectionHeaderFooterView(reuseIdentifier: nil, style: .Header)
        footerView.title = headerText
        return footerView
    }
    
    public override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard let footerText = sections[section].footerText else {
            return 0
        }
        
        return WPTableViewSectionHeaderFooterView.heightForFooter(footerText, width: tableView.bounds.width)
    }
    
    public override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let footerText = sections[section].footerText else {
            return nil
        }
        
        let footerView = WPTableViewSectionHeaderFooterView(reuseIdentifier: nil, style: .Footer)
        footerView.title = footerText
        return footerView
    }
    
    
    
    // MARK: - UITableViewDelegate Methods
    public override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        rowAtIndexPath(indexPath).handler?(tableView)
    }
    
    
    
    // MARK: - Cell Setup Helpers
    private func rowAtIndexPath(indexPath: NSIndexPath) -> Row {
        return sections[indexPath.section].rows[indexPath.row]
    }
    
    private func cellForRow(row: Row, tableView: UITableView) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCellWithIdentifier(row.style.rawValue) {
            return cell
        }
        
        switch row.style {
        case .Value1:
            return WPTableViewCell(style: .Value1, reuseIdentifier: row.style.rawValue)
        case .Switch:
            return SwitchTableViewCell(style: .Default, reuseIdentifier: row.style.rawValue)
        }
    }
    
    private func configureTextCell(cell: WPTableViewCell, row: Row) {
        cell.textLabel?.text        = row.title ?? String()
        cell.detailTextLabel?.text  = row.details ?? String()
        cell.accessoryType          = .DisclosureIndicator
        WPStyleGuide.configureTableViewCell(cell)
    }
    
    private func configureSwitchCell(cell: SwitchTableViewCell, row: Row) {
        cell.name                   = row.title ?? String()
        cell.on                     = row.boolValue ?? true
        cell.onChange               = { (newValue: Bool) in
            row.handler?(newValue)
        }
    }
    
    
    
    // MARK: - Row Handlers
    private func pressedCommentsAllowed(payload: AnyObject?) {
        guard let enabled = payload as? Bool else {
            return
        }
        
        settings.commentsAllowed = enabled
    }

    private func pressedPingbacksInbound(payload: AnyObject?) {
        guard let enabled = payload as? Bool else {
            return
        }
        
        settings.pingbackInboundEnabled = enabled
    }
    
    private func pressedPingbacksOutbound(payload: AnyObject?) {
        guard let enabled = payload as? Bool else {
            return
        }
        
        settings.pingbackOutboundEnabled = enabled
    }

    private func pressedRequireNameAndEmail(payload: AnyObject?) {
        guard let enabled = payload as? Bool else {
            return
        }
        
        settings.commentsRequireNameAndEmail = enabled
    }
    
    private func pressedRequireRegistration(payload: AnyObject?) {
        guard let enabled = payload as? Bool else {
            return
        }
        
        settings.commentsRequireRegistration = enabled
    }
    
    private func pressedCloseCommenting(payload: AnyObject?) {
        let pickerViewController                = SettingsPickerViewController(style: .Grouped)
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
        pickerViewController.onChange           = { [weak self] (enabled : Bool, newValue: Int) in
            self?.settings.commentsCloseAutomatically = enabled
            self?.settings.commentsCloseAutomaticallyAfterDays = newValue
        }
        
        navigationController?.pushViewController(pickerViewController, animated: true)
    }
    
    private func pressedSortBy(payload: AnyObject?) {
        let settingsViewController              = SettingsSelectionViewController(style: .Grouped)
        settingsViewController.title            = NSLocalizedString("Sort By", comment: "Discussion Settings Title")
        settingsViewController.currentValue     = settings.commentsSortOrder
        settingsViewController.titles           = CommentsSorting.allTitles
        settingsViewController.values           = CommentsSorting.allValues
        settingsViewController.onItemSelected   = { [weak self] (selected: AnyObject!) in
            guard let newSortOrder = CommentsSorting(rawValue: selected as! Int) else {
                return
            }
            
            self?.settings.commentsSorting = newSortOrder
        }
        
        navigationController?.pushViewController(settingsViewController, animated: true)
    }
    
    private func pressedThreading(payload: AnyObject?) {
        let settingsViewController              = SettingsSelectionViewController(style: .Grouped)
        settingsViewController.title            = NSLocalizedString("Threading", comment: "Discussion Settings Title")
        settingsViewController.currentValue     = settings.commentsThreading.rawValue
        settingsViewController.titles           = CommentsThreading.allTitles
        settingsViewController.values           = CommentsThreading.allValues
        settingsViewController.onItemSelected   = { [weak self] (selected: AnyObject!) in
            guard let newThreadingDepth = CommentsThreading(rawValue: selected as! Int) else {
                return
            }

            self?.settings.commentsThreading = newThreadingDepth
        }
        
        navigationController?.pushViewController(settingsViewController, animated: true)
    }
    
    private func pressedPaging(payload: AnyObject?) {
        let pickerViewController                = SettingsPickerViewController(style: .Grouped)
        pickerViewController.title              = NSLocalizedString("Paging", comment: "Comments Paging")
        pickerViewController.switchVisible      = true
        pickerViewController.switchOn           = settings.commentsPagingEnabled
        pickerViewController.switchText         = NSLocalizedString("Paging", comment: "Discussion Settings")
        pickerViewController.selectionText      = NSLocalizedString("Comments per page", comment: "")
        pickerViewController.pickerHint         = NSLocalizedString("Break comment threads into multiple pages.", comment: "")
        pickerViewController.pickerMinimumValue = commentsPagingMinimumValue
        pickerViewController.pickerMaximumValue = commentsPagingMaximumValue
        pickerViewController.pickerSelectedValue = settings.commentsPageSize as? Int
        pickerViewController.onChange           = { [weak self] (enabled : Bool, newValue: Int) in
            self?.settings.commentsPagingEnabled = enabled
            self?.settings.commentsPageSize = newValue
        }
        
        navigationController?.pushViewController(pickerViewController, animated: true)
    }
    
    private func pressedAutomaticallyApprove(payload: AnyObject?) {
        let settingsViewController              = SettingsSelectionViewController(style: .Grouped)
        settingsViewController.title            = NSLocalizedString("Automatically Approve", comment: "Discussion Settings Title")
        settingsViewController.currentValue     = settings.commentsAutoapproval.rawValue
        settingsViewController.titles           = CommentsAutoapproval.allTitles
        settingsViewController.values           = CommentsAutoapproval.allValues
        settingsViewController.hints            = CommentsAutoapproval.allHints
        settingsViewController.onItemSelected   = { [weak self] (selected: AnyObject!) in
            guard let newApprovalStatus = CommentsAutoapproval(rawValue: selected as! Int) else {
                return
            }

            self?.settings.commentsAutoapproval = newApprovalStatus
        }
        
        navigationController?.pushViewController(settingsViewController, animated: true)
    }

    private func pressedLinksInComments(payload: AnyObject?) {
        let pickerViewController                = SettingsPickerViewController(style: .Grouped)
        pickerViewController.title              = NSLocalizedString("Links in comments", comment: "Comments Paging")
        pickerViewController.switchVisible      = false
        pickerViewController.selectionText      = NSLocalizedString("Links in comments", comment: "")
        pickerViewController.pickerHint         = NSLocalizedString("Require manual approval for comments that include more than this number of links.", comment: "")
        pickerViewController.pickerMinimumValue = commentsLinksMinimumValue
        pickerViewController.pickerMaximumValue = commentsLinksMaximumValue
        pickerViewController.pickerSelectedValue = settings.commentsMaximumLinks as? Int
        pickerViewController.onChange           = { [weak self] (enabled : Bool, newValue: Int) in
            self?.settings.commentsMaximumLinks = newValue
        }
        
        navigationController?.pushViewController(pickerViewController, animated: true)
    }
    
    private func pressedModeration(payload: AnyObject?) {
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
    
    private func pressedBlacklist(payload: AnyObject?) {
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
    private var sections : [Section] {
        return [postsSection, commentsSection, otherSection]
    }
    
    private var postsSection : Section {
        let headerText = NSLocalizedString("Defaults for New Posts", comment: "Discussion Settings: Posts Section")
        let footerText = NSLocalizedString("You can override these settings for individual posts.", comment: "Discussion Settings: Footer Text")
        let rows = [
            Row(style:      .Switch,
                title:      NSLocalizedString("Allow Comments", comment: "Settings: Comments Enabled"),
                boolValue:  self.settings.commentsAllowed,
                handler:    {   [weak self] in
                                self?.pressedCommentsAllowed($0)
                            }),
            
            Row(style:      .Switch,
                title:      NSLocalizedString("Send Pingbacks", comment: "Settings: Sending Pingbacks"),
                boolValue:  self.settings.pingbackOutboundEnabled,
                handler:    {   [weak self] in
                                self?.pressedPingbacksOutbound($0)
                            }),
            
            Row(style:      .Switch,
                title:      NSLocalizedString("Receive Pingbacks", comment: "Settings: Receiving Pingbacks"),
                boolValue:  self.settings.pingbackInboundEnabled,
                handler:    {   [weak self] in
                                self?.pressedPingbacksInbound($0)
                            })
        ]
        
        return Section(headerText: headerText, footerText: footerText, rows: rows)
    }
    
    private var commentsSection : Section {
        let headerText = NSLocalizedString("Comments", comment: "Settings: Comment Sections")
        let rows = [
            Row(style:      .Switch,
                title:      NSLocalizedString("Require name and email", comment: "Settings: Comments Approval settings"),
                boolValue:  self.settings.commentsRequireNameAndEmail,
                handler:    {   [weak self] in
                                self?.pressedRequireNameAndEmail($0)
                            }),
            
            Row(style:      .Switch,
                title:      NSLocalizedString("Require users to sign in", comment: "Settings: Comments Approval settings"),
                boolValue:  self.settings.commentsRequireRegistration,
                handler:    {   [weak self] in
                                self?.pressedRequireRegistration($0)
                            }),
            
            Row(style:      .Value1,
                title:      NSLocalizedString("Close Commenting", comment: "Settings: Close comments after X period"),
                details:    self.detailsForCloseCommenting,
                handler:    {   [weak self] in
                                self?.pressedCloseCommenting($0)
                            }),
            
            Row(style:      .Value1,
                title:      NSLocalizedString("Sort By", comment: "Settings: Comments Sort Order"),
                details:    self.detailsForSortBy,
                handler:    {   [weak self] in
                                self?.pressedSortBy($0)
                            }),
            
            Row(style:      .Value1,
                title:      NSLocalizedString("Threading", comment: "Settings: Comments Threading preferences"),
                details:    self.detailsForThreading,
                handler:    {   [weak self] in
                                self?.pressedThreading($0)
                            }),
            
            Row(style:      .Value1,
                title:      NSLocalizedString("Paging", comment: "Settings: Comments Paging preferences"),
                details:    self.detailsForPaging,
                handler:    {   [weak self] in
                                self?.pressedPaging($0)
                            }),
            
            Row(style:      .Value1,
                title:      NSLocalizedString("Automatically Approve", comment: "Settings: Comments Approval settings"),
                details:    self.detailsForAutomaticallyApprove,
                handler:    {   [weak self] in
                                self?.pressedAutomaticallyApprove($0)
                            }),
            
            Row(style:      .Value1,
                title:      NSLocalizedString("Links in comments", comment: "Settings: Comments Approval settings"),
                details:    self.detailsForLinksInComments,
                handler:    {   [weak self] in
                                self?.pressedLinksInComments($0)
                            }),
        ]

        return Section(headerText: headerText, rows: rows)
    }
    
    private var otherSection : Section {
        let rows = [
            Row(style:      .Value1,
                title:      NSLocalizedString("Hold for Moderation", comment: "Settings: Comments Moderation"),
                handler:    self.pressedModeration),
            
            Row(style:      .Value1,
                title:      NSLocalizedString("Blacklist", comment: "Settings: Comments Blacklist"),
                handler:    self.pressedBlacklist)
        ]
        
        return Section(rows: rows)
    }

    
    
    // MARK: - Row Detail Helpers
    private var detailsForCloseCommenting : String {
        if !settings.commentsCloseAutomatically {
            return NSLocalizedString("Off", comment: "Disabled")
        }
        
        let numberOfDays = settings.commentsCloseAutomaticallyAfterDays ?? 0
        let format = NSLocalizedString("%@ days", comment: "Number of days after which comments should autoclose")
        return String(format: format, numberOfDays)
    }
    
    private var detailsForSortBy : String {
        return settings.commentsSorting.description
    }
    
    private var detailsForThreading : String {
        if !settings.commentsThreadingEnabled {
            return NSLocalizedString("Off", comment: "Disabled")
        }

        let levels = settings.commentsThreadingDepth ?? 0
        let format = NSLocalizedString("%@ levels", comment: "Number of Threading Levels")
        return String(format: format, levels)
    }
    
    private var detailsForPaging : String {
        if !settings.commentsPagingEnabled {
            return NSLocalizedString("None", comment: "Disabled")
        }
        
        let pageSize = settings.commentsPageSize ?? 0
        let format = NSLocalizedString("%@ comments", comment: "Number of Comments per Page")
        return String(format: format, pageSize)
    }
    
    private var detailsForAutomaticallyApprove : String {
        switch settings.commentsAutoapproval {
        case .Disabled:
            return NSLocalizedString("None", comment: "No comment will be autoapproved")
        case .Everything:
            return NSLocalizedString("All", comment: "Autoapprove every comment")
        case .FromKnownUsers:
            return NSLocalizedString("Known Users", comment: "Autoapprove only from known users")
        }
    }
    
    private var detailsForLinksInComments : String {
        guard let numberOfLinks = settings.commentsMaximumLinks else {
            return String()
        }

        let format = NSLocalizedString("%@ links", comment: "Number of Links")
        return String(format: format, numberOfLinks)
    }
    
    
    
    // MARK: - Private Nested Classes
    private class Section {
        let headerText      : String?
        let footerText      : String?
        let rows            : [Row]
        
        init(headerText: String? = nil, footerText: String? = nil, rows : [Row]) {
            self.headerText = headerText
            self.footerText = footerText
            self.rows       = rows
        }
    }
    
    private class Row {
        let style           : Style
        let title           : String?
        let details         : String?
        let handler         : Handler?
        var boolValue       : Bool?
        
        init(style: Style, title: String? = nil, details: String? = nil, boolValue: Bool? = nil, handler: Handler? = nil) {
            self.style      = style
            self.title      = title
            self.details    = details
            self.boolValue  = boolValue
            self.handler    = handler
        }
        
        typealias Handler = (AnyObject? -> Void)
        
        enum Style : String {
            case Value1     = "Value1"
            case Switch     = "SwitchCell"
        }
    }
    
    

    // MARK: - Private Properties
    private var blog : Blog!
    
    // MARK: - Computed Properties
    private var settings : BlogSettings {
        return blog.settings
    }
    
    // MARK: - Typealiases
    private typealias CommentsSorting           = BlogSettings.CommentsSorting
    private typealias CommentsThreading         = BlogSettings.CommentsThreading
    private typealias CommentsAutoapproval      = BlogSettings.CommentsAutoapproval
    
    // MARK: - Constants
    private let commentsPagingMinimumValue      = 1
    private let commentsPagingMaximumValue      = 100
    private let commentsLinksMinimumValue       = 1
    private let commentsLinksMaximumValue       = 100
    private let commentsAutocloseMinimumValue   = 1
    private let commentsAutocloseMaximumValue   = 120
}
