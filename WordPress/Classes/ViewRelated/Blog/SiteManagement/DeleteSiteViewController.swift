import UIKit
import SVProgressHUD
import WordPressShared

/// DeleteSiteViewController allows user delete their site.
///
open class DeleteSiteViewController: UITableViewController {

    // MARK: - Properties

    var blog: Blog!

    @IBOutlet weak var warningImage: UIImageView!
    @IBOutlet weak var siteTitleLabel: UILabel!
    @IBOutlet weak var siteTitleSubText: UILabel!
    @IBOutlet weak var sectionTwoHeader: UILabel!
    @IBOutlet weak var sectionTwoColumnOneItem: UILabel!
    @IBOutlet weak var sectionTwoColumnTwoItem: UILabel!
    @IBOutlet weak var sectionTwoColumnOneItem2: UILabel!
    @IBOutlet weak var sectionTwoColumnTwoItem2: UILabel!
    @IBOutlet weak var sectionTwoColumnOneItem3: UILabel!
    @IBOutlet weak var sectionTwoColumnTwoItem3: UILabel!
    @IBOutlet weak var sectionThreeBody: UILabel!
    @IBOutlet weak var supportButton: UIButton!
    @IBOutlet weak var trashImage: UIImageView!
    @IBOutlet weak var deleteSiteLabel: UILabel!
    
    
//    // MARK: - Properties: table content
//
//    let headerView: TableViewHeaderDetailView = {
//        let header = NSLocalizedString("Delete Site", comment: "Heading for instructions on Delete Site settings page")
//        let detail = NSLocalizedString("This action can not be undone. Deleting the site will remove all content, " +
//                                       "contributors, domains, and upgrades from the site.\n\n" +
//                                       "It you're unsure about what will be deleted or need any help, not to worry, " +
//                                       "our support team is here to answer any questions you may have.",
//                                       comment: "Detailed instructions on Delete Site settings page")
//
//       return TableViewHeaderDetailView(title: header, detail: detail)
//    }()
//
//    let contactCell: UITableViewCell = {
//        let contactTitle = NSLocalizedString("Contact Support", comment: "Button title for contacting support on Delete Site settings page")
//
//        let actionCell = WPTableViewCellDefault(style: .value1, reuseIdentifier: nil)
//        actionCell.textLabel?.text = contactTitle
//        WPStyleGuide.configureTableViewActionCell(actionCell)
//        actionCell.textLabel?.textAlignment = .center
//
//        return actionCell
//    }()
//
//    let deleteCell: UITableViewCell = {
//        let deleteTitle = NSLocalizedString("Delete Site", comment: "Button title to delete your site on the Delete Site settings page")
//
//        let actionCell = WPTableViewCellDefault(style: .value1, reuseIdentifier: nil)
//        actionCell.textLabel?.text = deleteTitle
//        WPStyleGuide.configureTableViewDestructiveActionCell(actionCell)
//
//        return actionCell
//    }()

    // MARK: - Initializer

//    init(blog: Blog) {
//        self.blog = blog
//        super.init(style: .grouped)
//    }
//
//    required public init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }

    // MARK: - View Lifecycle

//    override open func viewDidLoad() {
//        super.viewDidLoad()
//
//        title = NSLocalizedString("Delete Site", comment: "Title of settings page for deleting a site")
//
//        tableView.cellLayoutMarginsFollowReadableWidth = true
//        tableView.estimatedSectionHeaderHeight = 100.0
//        tableView.sectionHeaderHeight = UITableViewAutomaticDimension
//
//        WPStyleGuide.configureColors(for: view, andTableView: tableView)
//    }

    override open func viewDidLoad() {
        assert(blog != nil)
        super.viewDidLoad()
        WPStyleGuide.configureColors(for: view, andTableView: tableView)
    }

    // MARK: - Actions

    fileprivate func deleteSite() {
        tableView.deselectSelectedRowWithAnimation(true)
        present(confirmDeleteController(), animated: true, completion: nil)
    }

    fileprivate func contactSupport() {
        tableView.deselectSelectedRowWithAnimation(true)

        WPAppAnalytics.track(.siteSettingsStartOverContactSupportClicked, with: blog)
        if HelpshiftUtils.isHelpshiftEnabled() {
            setupHelpshift(blog.account!)

            let metadata = helpshiftMetadata(blog)
            HelpshiftSupport.showConversation(self, withOptions: metadata)
        } else {
            if let contact = URL(string: "https://support.wordpress.com/contact/") {
                UIApplication.shared.open(contact)
            }
        }
    }

    // MARK: - Delete Site Helpers

    /// Creates confirmation alert for Delete Site
    ///
    /// - Returns: UIAlertController
    ///
    fileprivate func confirmDeleteController() -> UIAlertController {
        let confirmTitle = NSLocalizedString("Confirm Delete Site", comment: "Title of Delete Site confirmation alert")
        let messageFormat = NSLocalizedString("Please type in \n\n%@\n\n in the field below to confirm. Your site will then be gone forever.", comment: "Message of Delete Site confirmation alert; substitution is site's host")
        let message = String(format: messageFormat, blog.displayURL!)
        let alertController = UIAlertController(title: confirmTitle, message: message, preferredStyle: .alert)

        let cancelTitle = NSLocalizedString("Cancel", comment: "Alert dismissal title")
        alertController.addCancelActionWithTitle(cancelTitle, handler: nil)

        let deleteTitle = NSLocalizedString("Delete this site", comment: "Delete Site confirmation action title")
        let deleteAction = UIAlertAction(title: deleteTitle, style: .destructive, handler: { action in
            self.deleteSiteConfirmed()
        })
        deleteAction.isEnabled = false
        alertController.addAction(deleteAction)

        alertController.addTextField(configurationHandler: { textField in
            textField.addTarget(self, action: #selector(DeleteSiteViewController.alertTextFieldDidChange(_:)), for: .editingChanged)
        })

        return alertController
    }

    /// Verifies site address as password for Delete Site
    ///
    func alertTextFieldDidChange(_ sender: UITextField) {
        guard let deleteAction = (presentedViewController as? UIAlertController)?.actions.last else {
            return
        }

        guard deleteAction.style == .destructive else {
            return
        }

        let prompt = blog.displayURL?.lowercased.trim()
        let password = sender.text?.lowercased().trim()
        deleteAction.isEnabled = prompt == password
    }

    /// Handles deletion of the blog's site and all content from WordPress.com
    ///
    /// - Note: This is permanent and cannot be reversed by user
    ///
    fileprivate func deleteSiteConfirmed() {
        let status = NSLocalizedString("Deleting site…", comment: "Overlay message displayed while deleting site")
        SVProgressHUD.setDefaultMaskType(.black)
        SVProgressHUD.show(withStatus: status)

        let trackedBlog = blog
        WPAppAnalytics.track(.siteSettingsDeleteSiteRequested, with: trackedBlog)
        let service = SiteManagementService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        service.deleteSiteForBlog(blog,
                                  success: { [weak self] in
                                    WPAppAnalytics.track(.siteSettingsDeleteSiteResponseOK, with: trackedBlog)
                                    let status = NSLocalizedString("Site deleted", comment: "Overlay message displayed when site successfully deleted")
                                    SVProgressHUD.showSuccess(withStatus: status)

                                    self?.updateNavigationStackAfterSiteDeletion()

                                    let accountService = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext)
                                    accountService.updateUserDetails(for: (accountService.defaultWordPressComAccount()!), success: { _ in }, failure: { _ in })
            },
                                  failure: { error in
                                    DDLogSwift.logError("Error deleting site: \(error.localizedDescription)")
                                    WPAppAnalytics.track(.siteSettingsDeleteSiteResponseError, with: trackedBlog)
                                    SVProgressHUD.dismiss()

                                    let errorTitle = NSLocalizedString("Delete Site Error", comment: "Title of alert when site deletion fails")
                                    let alertController = UIAlertController(title: errorTitle, message: error.localizedDescription, preferredStyle: .alert)

                                    let okTitle = NSLocalizedString("OK", comment: "Alert dismissal title")
                                    alertController.addDefaultActionWithTitle(okTitle, handler: nil)

                                    alertController.presentFromRootViewController()
        })
    }

    fileprivate func updateNavigationStackAfterSiteDeletion() {
        if let primaryNavigationController = self.splitViewController?.viewControllers.first as? UINavigationController {
            if let secondaryNavigationController = self.splitViewController?.viewControllers.last as? UINavigationController {

                // If this view controller is in the detail pane of its splitview
                // (i.e. its navigation controller isn't the navigation controller in the primary position in the splitview)
                // then replace it with an empty view controller, as we just deleted its blog
                if primaryNavigationController != secondaryNavigationController && secondaryNavigationController == self.navigationController {
                    let emptyViewController = UIViewController()
                    WPStyleGuide.configureColors(for: emptyViewController.view, andTableView: nil)

                    self.navigationController?.viewControllers = [emptyViewController]
                }
            }

            // Pop the primary navigation controller back to the sites list
            primaryNavigationController.popToRootViewController(animated: true)
        }
    }

    // MARK: - Contact Support Helpers

    fileprivate func setupHelpshift(_ account: WPAccount) {
        let user = account.userID.stringValue
        HelpshiftSupport.setUserIdentifier(user)

        let name = account.username
        let email = account.email
        HelpshiftCore.setName(name, andEmail: email)
    }

    fileprivate func helpshiftMetadata(_ blog: Blog) -> [AnyHashable: Any] {
        let tags = blog.account.map({ HelpshiftUtils.planTags(for: $0) }) ?? []
        let options: [String: AnyObject] = [
            "Source": "Delete Site" as AnyObject,
            "Blog": blog.logDescription() as AnyObject,
            HelpshiftSupportTagsKey: tags as AnyObject
        ]

        return [HelpshiftSupportCustomMetadataKey: options]
    }
}

//// MARK: - UITableViewDelegate
//
//extension DeleteSiteViewController {
//    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        switch indexPath.row {
//        case 0:
//            return contactSupport()
//        default:
//            return deleteSite()
//        }
//    }
//
//    override open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        return headerView
//    }
//}
//
//// MARK: - UITableViewDataSource
//
//extension DeleteSiteViewController {
//    override open func numberOfSections(in tableView: UITableView) -> Int {
//        return 1
//    }
//
//    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return 2
//    }
//
//    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        switch indexPath.row {
//        case 0:
//            return contactCell
//        default:
//            return deleteCell
//        }
//    }
//}
