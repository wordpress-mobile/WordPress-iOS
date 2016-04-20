import UIKit
import SVProgressHUD
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
    
    /// Enabled by primaryDomain keyboard entry
    ///
    private weak var deleteAction: UIAlertAction?

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
        
        let contentTitle = NSLocalizedString("Export Content", comment: "Button to export content on Delete Site settings page")

        let contentCell = WPTableViewCellDefault(style: .Value1, reuseIdentifier: nil)
        contentCell.textLabel?.text = contentTitle
        WPStyleGuide.configureTableViewActionCell(contentCell)
        contentCell.textLabel?.textAlignment = .Center

        return Section(
            header: TableViewHeaderDetailView(title: contentHeading, detail: contentDetail),
            cell: contentCell,
            action: { [unowned self] in
                self.exportContent()
            })
    }

    private func createDeleteSection() -> Section {
        let deleteHeading = NSLocalizedString("Are You Sure", comment: "Heading for Are You Sure on Delete Site settings page")
        
        let deleteDetail = NSLocalizedString("This action can not be undone. Deleting your site will remove all content, contributors, and domains from the site.", comment: "Detail for Are You Sure on Delete Site settings page")
        
        let deleteTitle = NSLocalizedString("Delete Site", comment: "Button to delete site on Delete Site settings page")

        let deleteCell = WPTableViewCellDefault(style: .Value1, reuseIdentifier: nil)
        deleteCell.textLabel?.text = deleteTitle
        WPStyleGuide.configureTableViewDestructiveActionCell(deleteCell)

        return Section(
            header: TableViewHeaderDetailView(title: deleteHeading, detail: deleteDetail),
            cell: deleteCell,
            action: { [unowned self] in
                self.confirmDeleteSite()
            })
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

    // MARK: - Actions

    private func exportContent() {
        tableView.deselectSelectedRowWithAnimation(true)
        
        let exportTitle = NSLocalizedString("Export Content", comment: "Title of alert when Export Content selected")
        let exportMessage = NSLocalizedString("Currently exporting is only available through the web interface. Please go to WordPress.com in your browser to export content.", comment: "Message of alert when Export Content selected")
        let alertController = UIAlertController(title: exportTitle, message: exportMessage, preferredStyle: .Alert)
        
        let okTitle = NSLocalizedString("OK", comment: "Alert dismissal title")
        alertController.addDefaultActionWithTitle(okTitle, handler: nil)
        
        presentViewController(alertController, animated: true, completion: nil)
    }

    private func confirmDeleteSite() {
        tableView.deselectSelectedRowWithAnimation(true)
        
        presentViewController(confirmDeleteController(), animated: true, completion: nil)
    }
    
    private func confirmDeleteController() -> UIAlertController {
        let title = NSLocalizedString("Confirm Delete Site", comment: "Title of Delete Site confirmation alert")
        let messageFormat = NSLocalizedString("Please type in \n\n%@\n\n in the field below to confirm. Your site will then be gone forever.", comment: "Message of Delete Site confirmation alert; substitution is site's primary domain")
        let message = String(format: messageFormat, primaryDomain)
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        
        let cancelTitle = NSLocalizedString("Cancel", comment: "Alert dismissal title")
        alertController.addCancelActionWithTitle(cancelTitle, handler: nil)
        
        let deleteTitle = NSLocalizedString("Delete this site", comment: "Delete Site confirmation action title")
        let deleteAction = UIAlertAction(title: deleteTitle, style: .Destructive, handler: { action in
            self.deleteSiteConfirmed()
        })
        deleteAction.enabled = false
        alertController.addAction(deleteAction)
        self.deleteAction = deleteAction
        
        alertController.addTextFieldWithConfigurationHandler({ textField in
            textField.addTarget(self, action: "alertTextFieldDidChange:", forControlEvents: .EditingChanged)
        })
        
        return alertController
    }

    func alertTextFieldDidChange(sender: UITextField) {
        deleteAction?.enabled = sender.text == primaryDomain
    }
    
    private func deleteSiteConfirmed() {
        SVProgressHUD.show()
        
        let service = SiteManagementService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        service.deleteSiteForBlog(blog,
            success: { [weak self] in
                let status = NSLocalizedString("Site deleted!", comment: "Overlay message displayed when site successfully deleted")
                SVProgressHUD.showSuccessWithStatus(status)
                
                if let navController = self?.navigationController {
                    navController.popToRootViewControllerAnimated(true)
                }
            },
            failure: { [weak self] error in
                DDLogSwift.logError("Error deleting site \(self?.primaryDomain): \(error.localizedDescription)")
                SVProgressHUD.dismiss()
                
                self?.showError(error)
            })
    }
    
    private func showError(error: NSError) {
        let errorTitle = NSLocalizedString("Delete Site Error", comment: "Title of alert when site deletion fails")
        let alertController = UIAlertController(title: errorTitle, message: error.localizedDescription, preferredStyle: .Alert)
        
        let okTitle = NSLocalizedString("OK", comment: "Alert dismissal title")
        alertController.addDefaultActionWithTitle(okTitle, handler: nil)
        
        alertController.presentFromRootViewController()
    }
}
