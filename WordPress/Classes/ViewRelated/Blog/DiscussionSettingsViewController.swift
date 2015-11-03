import Foundation


/**
 *  @class          DiscussionSettingsViewController
 *  @brief          The purpose of this class is to render the Discussion Settings associated to a site, and
 *                  allow the user to tune those settings, as required.
 */

public class DiscussionSettingsViewController : UITableViewController
{
    // MARK: - Private Properties
    private var blog : Blog!


    
    // MARK: - Initializers
    public convenience init(blog: Blog) {
        self.init(style: .Grouped)
        self.blog = blog
    }
    
    
    
    // MARK: - View Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
        setupTableView()
    }
    
    
    
    // MARK: - Setup Helpers
    private func setupNavBar() {
        title = NSLocalizedString("Discussion", comment: "Title for the Discussion Settings Screen")
    }
    
    private func setupTableView() {
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
        tableView.cellLayoutMarginsFollowReadableWidth = false
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
        tableView.deselectSelectedRowWithAnimation(true)
        
        if let handler = rowAtIndexPath(indexPath).handler {
            handler()
        }
    }
    
    
    
    // MARK: - Private Methods
    private func rowAtIndexPath(indexPath: NSIndexPath) -> Row {
        return sections[indexPath.section].rows[indexPath.row]
    }
    
    private func cellForRow(row: Row, tableView: UITableView) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCellWithIdentifier(row.style.rawValue) {
            return cell
        }
        
        switch row.style {
        case .Value1:
            return WPTableViewCell(style: .Default, reuseIdentifier: row.style.rawValue)
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
        cell.name       = row.title ?? String()
//        cell.on         = newValues[settingKey] ?? (row.value ?? true)
//        cell.onChange = { [weak self] (newValue: Bool) in
//            
//        }
    }
    
    
    // MARK: - Computed Properties
    private var sections : [Section] {
        return [postsSection, commentsSection, approvalSection, otherSection]
    }
    
    private var postsSection : Section {
        let headerText = NSLocalizedString("Defaults for New Posts", comment: "Discussion Settings: Posts Section")
        let footerText = NSLocalizedString("You can override these settings for individual posts. Learn more...", comment: "Discussion Settings: Footer Text")
        let rows = [
            Row(style:      .Switch,
                title:      NSLocalizedString("Allow Comments", comment: "Settings: Comments Enabled"),
                handler:    nil),
            
            Row(style:      .Switch,
                title:      NSLocalizedString("Send Pingbacks", comment: "Settings: Sending Pingbacks"),
                handler:    nil),
            
            Row(style:      .Switch,
                title:      NSLocalizedString("Receive Pingbacks", comment: "Settings: Receiving Pingbacks"),
                handler:    nil)
        ]
        
        return Section(headerText: headerText, footerText: footerText, rows: rows)
    }
    
    private var commentsSection : Section {
        let headerText = NSLocalizedString("Comments", comment: "Settings: Comment Sections")
        let rows = [
            Row(style:      .Value1,
                title:      NSLocalizedString("Close After", comment: "Settings: Close comments after X period"),
                handler:    { self.showCloseAfterSettings() }),
            
            Row(style:      .Value1,
                title:      NSLocalizedString("Sort By", comment: "Settings: Comments Sort Order"),
                handler:    { self.showSortingSettings() }),
            
            Row(style:      .Value1,
                title:      NSLocalizedString("Threading", comment: "Settings: Comments Threading preferences"),
                handler:    { self.showThreadingSettings() }),
            
            Row(style:      .Value1,
                title:      NSLocalizedString("Paging", comment: "Settings: Comments Paging preferences"),
                handler:    { self.showPagingSettings() }),
            
            Row(style:      .Switch,
                title:      NSLocalizedString("Must be Manually Approved", comment: "Settings: Comments Approval settings"),
                handler:    nil),
            
            Row(style:      .Switch,
                title:      NSLocalizedString("Must include name & email", comment: "Settings: Comments Approval settings"),
                handler:    nil),
            
            Row(style:      .Switch,
                title:      NSLocalizedString("Users must be signed in", comment: "Settings: Comments Approval settings"),
                handler:    nil)
        ]

        return Section(headerText: headerText, rows: rows)
    }
    
    private var approvalSection : Section {
        let headerText = NSLocalizedString("Automatically Approve Comments", comment: "Settings: Auto-Approvals Section Header")
        let rows = [
            Row(style:      .Switch,
                title:      NSLocalizedString("From known users", comment: "Settings: Comments Auto Approval"),
                handler:    nil),
    
            Row(style:      .Switch,
                title:      NSLocalizedString("With multiple links", comment: "Settings: Comments Auto Approval"),
                handler:    nil)
        ]
        
        return Section(headerText: headerText, rows: rows)
    }
    
    private var otherSection : Section {
        let rows = [
            Row(style:      .Value1,
                title:      NSLocalizedString("Hold for Moderation", comment: "Settings: Comments Moderation"),
                handler:    { self.showModerationSettings() } ),
            
            Row(style:      .Value1,
                title:      NSLocalizedString("Blacklist", comment: "Settings: Comments Blacklist"),
                handler:    { self.showBlacklistSettings() } )
        ]
        
        return Section(rows: rows)
    }
    
    
    private func showCloseAfterSettings() {
        let settingsViewController              = SettingsSelectionViewController(style: .Grouped)
        settingsViewController.title            = NSLocalizedString("Close After", comment: "")
        settingsViewController.currentValue     = "2"
        settingsViewController.defaultValue     = "123"
        settingsViewController.titles           = ["Never", "One day", "One week", "One month"]
        settingsViewController.values           = ["31337", "1", "7", "30"]
        settingsViewController.onItemSelected   = { (selected: AnyObject!) in }
        
        navigationController?.pushViewController(settingsViewController, animated: true)
    }
    
    private func showSortingSettings() {
        let settingsViewController              = SettingsSelectionViewController(style: .Grouped)
        settingsViewController.title            = NSLocalizedString("Sort By", comment: "")
        settingsViewController.currentValue     = "1"
        settingsViewController.defaultValue     = "123"
        settingsViewController.titles           = ["Oldest First", "Newest First"]
        settingsViewController.values           = ["0", "1"]
        settingsViewController.onItemSelected   = { (selected: AnyObject!) in }
        
        navigationController?.pushViewController(settingsViewController, animated: true)
    }
    
    private func showThreadingSettings() {
        let settingsViewController              = SettingsSelectionViewController(style: .Grouped)
        settingsViewController.title            = NSLocalizedString("Threading", comment: "")
        settingsViewController.currentValue     = "2"
        settingsViewController.defaultValue     = "123"
        settingsViewController.titles           = ["Two levels", "Three levels", "Four levels", "Five levels"]
        settingsViewController.values           = ["2", "3", "4", "5"]
        settingsViewController.onItemSelected   = { (selected: AnyObject!) in }
        
        navigationController?.pushViewController(settingsViewController, animated: true)
    }
    
    private func showPagingSettings() {
        let settingsViewController              = SettingsSelectionViewController(style: .Grouped)
        settingsViewController.title            = NSLocalizedString("Paging", comment: "")
        settingsViewController.currentValue     = "50"
        settingsViewController.defaultValue     = "123"
        settingsViewController.titles           = ["None", "50 comments per page", "100 comments per page", "200 comments per page"]
        settingsViewController.values           = ["31337", "50", "100", "200"]
        settingsViewController.onItemSelected   = { (selected: AnyObject!) in }
        
        navigationController?.pushViewController(settingsViewController, animated: true)
    }

    private func showModerationSettings() {
        
    }
    
    private func showBlacklistSettings() {
        
    }
    
    
    // MARK: - Public Nested Classes
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
        let boolValue       : Bool?
        let handler         : Handler?
        
        init(style: Style, title: String? = nil, details: String? = nil, boolValue: Bool? = nil, handler: Handler? = nil) {
            self.style      = style
            self.title      = title
            self.details    = details
            self.boolValue  = boolValue
            self.handler    = handler
        }
        
        typealias Handler = (() -> ())
        
        enum Style : String {
            case Value1     = "Value1"
            case Switch     = "SwitchCell"
        }
    }
}
