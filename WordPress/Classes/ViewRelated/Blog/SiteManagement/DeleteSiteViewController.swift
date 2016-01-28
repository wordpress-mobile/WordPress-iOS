import UIKit
import WordPressShared

/// DeleteSiteViewController handles deletion of a user's site.
///
public class DeleteSiteViewController : UITableViewController
{
    // MARK: - Properties: must be set by creator
    
    /// The blog whose site we may delete
    ///
    var blog : Blog!

    // MARK: - Properties
    
    /// Displayed and used as verification
    ///
    private var primaryDomain: String!
    
    /// Table content structure
    ///
    private struct Section
    {
        let header: TableViewHeaderDetailView
        let cell: UITableViewCell
        let action: (() -> Void)?
    }
    private var sections = [Section]()
    
    // MARK: - Initializer

    /// Preferred initializer for DeleteSiteViewController
    ///
    /// - Parameters:
    ///     - blog: The Blog currently at the site
    ///
    public convenience init(blog: Blog) {
        self.init(style: .Grouped)
        self.blog = blog
        self.primaryDomain = blog.displayURL
    }
    
    // MARK: - View Lifecycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Delete Site", comment: "Title of Delete Site settings page")
        
        WPStyleGuide.resetReadableMarginsForTableView(tableView)
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
       
        createTableContent()
    }
    
    private func createTableContent() {
        sections.append(createDomainSection())
        sections.append(createContentSection())
        sections.append(createDeleteSection())

        tableView.reloadData()
    }

    private func createDomainSection() -> Section {
        let domainHeading = NSLocalizedString("Domain Removal", comment: "Heading for Domain Removal on Delete Site settings page")
        
        let domainDetail = NSLocalizedString("Be careful! Deleting your site will also remove your domain(s) listed below.", comment: "Detail for Domain Removal on Delete Site settings page")

        let domainCell = WPTableViewCellDefault(style: .Value1, reuseIdentifier: nil)
        domainCell.textLabel?.text = primaryDomain
        WPStyleGuide.configureTableViewCell(domainCell)
        domainCell.selectionStyle = .None
        domainCell.textLabel?.textColor = WPStyleGuide.grey()
        
        return Section(
            header: TableViewHeaderDetailView(title: domainHeading, detail: domainDetail),
            cell: domainCell,
            action: nil)
    }
    
    private func createContentSection() -> Section {
        let contentHeading = NSLocalizedString("Keep Your Content", comment: "Heading for Keep Your Content on Delete Site settings page")
        
        let contentDetail = NSLocalizedString("If you are sure, please be sure to take the time and export your content now. It can not be recovered in the future.", comment: "Detail for Keep Your Content on Delete Site settings page")
        
        let contentTitle = NSLocalizedString("Export Content", comment: "Button to export content on Start Over settings page")

        let contentCell = WPTableViewCellDefault(style: .Value1, reuseIdentifier: nil)
        contentCell.textLabel?.text = contentTitle
        WPStyleGuide.configureTableViewActionCell(contentCell)
        contentCell.textLabel?.textAlignment = .Center

        return Section(
            header: TableViewHeaderDetailView(title: contentHeading, detail: contentDetail),
            cell: contentCell,
            action: nil)
    }

    private func createDeleteSection() -> Section {
        let deleteHeading = NSLocalizedString("Are You Sure", comment: "Heading for Are You Sure on Delete Site settings page")
        
        let deleteDetail = NSLocalizedString("This action can not be undone. Deleting your site will remove all content, contributors, and domains from the site.", comment: "Detail for Are You Sureon Delete Site settings page")
        
        let deleteTitle = NSLocalizedString("Delete Site", comment: "Button to delete site on Start Over settings page")

        let deleteCell = WPTableViewCellDefault(style: .Value1, reuseIdentifier: nil)
        deleteCell.textLabel?.text = deleteTitle
        WPStyleGuide.configureTableViewDestructiveActionCell(deleteCell)

        return Section(
            header: TableViewHeaderDetailView(title: deleteHeading, detail: deleteDetail),
            cell: deleteCell,
            action: nil)
    }
    
    // MARK: Table View Data Source
    
    override public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sections.count
    }
    
    override public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < sections.count else {
            return 0
        }

        return 1
    }
    
    override public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard indexPath.section < sections.count else {
            return UITableViewCell()
        }
        
        return sections[indexPath.section].cell
    }

    // MARK: - Table View Delegate
    
    override public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard indexPath.section < sections.count else {
            return
        }
        
        sections[indexPath.section].action?()
    }

    override public func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section < sections.count else {
            return nil
        }
        
        return sections[section].header
    }

    override public func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard section < sections.count else {
            return CGFloat.min
        }
        
        let headerView = sections[section].header
        headerView.layoutWidth = tableView.frame.width
        let headerHeight = headerView.intrinsicContentSize().height
        
        return headerHeight
    }
}
