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
        let row = sections[indexPath.section].rows[indexPath.row]
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
    }
    
    
    
    // MARK: - Private Methods
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
        let postsSection = Section()
        postsSection.headerText = NSLocalizedString("Defaults for New Posts",
                                                    comment: "Discussion Settings: Posts Section")
        
        postsSection.footerText = NSLocalizedString("You can override these settings for individual posts. Learn more...",
                                                    comment: "Discussion Settings: Footer Text")
        postsSection.rows = [
            Row(style: .Switch, title: NSLocalizedString("Allow Comments", comment: "Settings: Comments Enabled")),
            Row(style: .Switch, title: NSLocalizedString("Send Pingbacks", comment: "Settings: Sending Pingbacks")),
            Row(style: .Switch, title: NSLocalizedString("Receive Pingbacks", comment: "Settings: Receiving Pingbacks"))
        ]
        
        
        let commentsSection = Section()
        commentsSection.headerText = NSLocalizedString("Comments", comment: "Settings: Comment Sections")
        commentsSection.rows = [
            Row(style: .Value1,
                title: NSLocalizedString("Close After", comment: "Settings: Close comments after X period")),
            
            Row(style: .Value1,
                title: NSLocalizedString("Sort By", comment: "Settings: Comments Sort Order")),
            
            Row(style: .Value1,
                title: NSLocalizedString("Threading", comment: "Settings: Comments Threading preferences")),
            
            Row(style: .Value1,
                title: NSLocalizedString("Paging", comment: "Settings: Comments Paging preferences")),
            
            Row(style: .Switch,
                title: NSLocalizedString("Must be Manually Approved", comment: "Settings: Comments Approval settings")),
            
            Row(style: .Switch,
                title: NSLocalizedString("Must include name & email", comment: "Settings: Comments Approval settings")),
            
            Row(style: .Switch,
                title: NSLocalizedString("Users must be signed in", comment: "Settings: Comments Approval settings"))
        ]
        
        let approvalSection = Section()
        approvalSection.headerText = NSLocalizedString("Automatically Approve Comments", comment: "Settings: Auto-Approvals Section Header")
        approvalSection.rows = [
            Row(style: .Switch,
                title: NSLocalizedString("From known users", comment: "Settings: Comments Auto Approval")),
            
            Row(style: .Switch,
                title: NSLocalizedString("With multiple links", comment: "Settings: Comments Auto Approval"))
        ]
        
        let otherSection = Section()
        otherSection.rows = [
            Row(style: .Value1,
                title: NSLocalizedString("Hold for Moderation", comment: "Settings: Comments Moderation")),
            
            Row(style: .Value1,
                title: NSLocalizedString("Blacklist", comment: "Settings: Comments Blacklist"))
        ]
        
        return [postsSection, commentsSection, approvalSection, otherSection]
    }
    
    
    
    // MARK: - Public Nested Classes
    private class Section {
        var headerText      : String?
        var footerText      : String?
        var rows            : [Row]!
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
        
        typealias Handler = (Row -> Void)
        
        enum Style : String {
            case Value1     = "Value1"
            case Switch     = "SwitchCell"
        }
    }
}
