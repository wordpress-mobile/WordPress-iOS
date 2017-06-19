import UIKit
import CocoaLumberjack
import SVProgressHUD
import WordPressShared
import Gridicons

/// DeleteSiteViewController allows user delete their site.
///
open class DeleteSiteViewController: UITableViewController {

    /// A convenience method for obtaining an instance of this controller from a storyboard.
    ///
    /// - Parameter blog: A Blog instance.
    ///
    class func controller(_ blog: Blog) -> DeleteSiteViewController {
        let storyboard = UIStoryboard(name: "DeleteSite", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: "DeleteSiteViewController") as! DeleteSiteViewController
        controller.blog = blog
        return controller
    }

    // MARK: - Properties

    var blog: Blog!

    @IBOutlet fileprivate weak var warningImage: UIImageView!
    @IBOutlet fileprivate weak var siteTitleLabel: UILabel!
    @IBOutlet fileprivate weak var siteTitleSubText: UILabel!
    @IBOutlet fileprivate weak var sectionTwoHeader: UILabel!
    @IBOutlet fileprivate var      sectionTwoColumnItems: [UILabel]!
    @IBOutlet fileprivate weak var sectionTwoColumnOneItem: UILabel!
    @IBOutlet fileprivate weak var sectionTwoColumnTwoItem: UILabel!
    @IBOutlet fileprivate weak var sectionTwoColumnOneItem2: UILabel!
    @IBOutlet fileprivate weak var sectionTwoColumnTwoItem2: UILabel!
    @IBOutlet fileprivate weak var sectionTwoColumnOneItem3: UILabel!
    @IBOutlet fileprivate weak var sectionTwoColumnTwoItem3: UILabel!
    @IBOutlet fileprivate weak var sectionThreeBody: UILabel!
    @IBOutlet fileprivate weak var supportButton: UIButton!
    @IBOutlet fileprivate weak var deleteSiteButton: UIButton!

    // MARK: - View Lifecycle

    override open func viewDidLoad() {
        super.viewDidLoad()

        assert(blog != nil)
        title = NSLocalizedString("Delete Site", comment: "Title of settings page for deleting a site")
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 200.0
        WPStyleGuide.configureColors(for: view, andTableView: tableView)
        setupHeaderSection()
        setupListSection()
        setupMainBodySection()
        setupDeleteButton()
    }

    // MARK: - Configuration

    /// One time setup of section one (header)
    ///
    fileprivate func setupHeaderSection() {
        let warningIcon = Gridicon.iconOfType(.notice, withSize: CGSize(width: 48.0, height: 48.0))

        warningImage.image = warningIcon
        warningImage.tintColor = WPStyleGuide.warningYellow()
        siteTitleLabel.textColor = WPStyleGuide.darkGrey()
        siteTitleLabel.text = blog.displayURL as String?
        siteTitleSubText.textColor = WPStyleGuide.darkGrey()
        siteTitleSubText.text = NSLocalizedString("will be unavailable in the future.",
                                                  comment: "Second part of delete screen title stating [the site] will be unavailable in the future.")
    }

    /// One time setup of second section (list)
    ///
    fileprivate func setupListSection() {
        sectionTwoHeader.textColor = WPStyleGuide.grey()
        sectionTwoColumnItems.forEach({ $0.textColor = WPStyleGuide.darkGrey() })

        sectionTwoHeader.text = NSLocalizedString("these items will be deleted:",
                                                  comment: "Header of delete screen section listing things that will be deleted.").uppercased()

        sectionTwoColumnOneItem.text = NSLocalizedString("• Posts",
                                                         comment: "Item 1 of delete screen section listing things that will be deleted.")

        sectionTwoColumnTwoItem.text = NSLocalizedString("• Users & Authors",
                                                         comment: "Item 2 of delete screen section listing things that will be deleted.")

        sectionTwoColumnOneItem2.text = NSLocalizedString("• Pages",
                                                          comment: "Item 3 of delete screen section listing things that will be deleted.")

        sectionTwoColumnTwoItem2.text = NSLocalizedString("• Domains",
                                                          comment: "Item 4 of delete screen section listing things that will be deleted.")

        sectionTwoColumnOneItem3.text = NSLocalizedString("• Media",
                                                          comment: "Item 5 of delete screen section listing things that will be deleted.")

        sectionTwoColumnTwoItem3.text = NSLocalizedString("• Purchased Upgrades",
                                                          comment: "Item 6 of delete screen section listing things that will be deleted.")
    }

    /// One time setup of third section (main body)
    ///
    fileprivate func setupMainBodySection() {
        let paragraph1 = NSLocalizedString("This action <b>can not</b> be undone. Deleting the site will remove all " +
                                           "content, contributors, domains, and upgrades from the site.",
                                            comment: "Paragraph 1 of 2 of main text body for the delete screen. NOTE: it is important " +
                                                     "the localized 'can not' text be surrounded with the HTML '<b>' tags.")

        let paragraph2 = NSLocalizedString("If you're unsure about what will be deleted or need any help, not to worry, " +
                                           "our support team is here to answer any questions you may have.",
                                           comment: "Paragraph 2 of 2 of main text body for the delete screen.")

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        let attributes = [ NSFontAttributeName: UIFont.systemFont(ofSize: 17.0),
                           NSForegroundColorAttributeName: WPStyleGuide.darkGrey(),
                           NSParagraphStyleAttributeName: paragraphStyle ]
        let htmlAttributes: StyledHTMLAttributes = [ .BodyAttribute: attributes]

        let attributedText1 = NSAttributedString.attributedStringWithHTML(paragraph1, attributes: htmlAttributes)
        let attributedText2 = NSAttributedString(string: paragraph2, attributes: attributes)

        let combinedAttributedString = NSMutableAttributedString()
        combinedAttributedString.append(attributedText1)
        combinedAttributedString.append(NSAttributedString(string: "\n\r", attributes: attributes))
        combinedAttributedString.append(attributedText2)
        sectionThreeBody.attributedText = combinedAttributedString

        let contactButtonAttributes = [ NSFontAttributeName: UIFont.systemFont(ofSize: 17.0),
                                        NSForegroundColorAttributeName: WPStyleGuide.wordPressBlue(),
                                        NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue as AnyObject]
        supportButton.setAttributedTitle(NSAttributedString(string: NSLocalizedString("Contact Support", comment: "Button label for contacting support"), attributes: contactButtonAttributes),
                                         for: .normal)
    }

    /// One time setup of fourth section (delete button)
    ///
    fileprivate func setupDeleteButton() {
        let trashIcon = Gridicon.iconOfType(.trash)
        deleteSiteButton.setTitle(NSLocalizedString("Delete Site", comment: "Button label for deleting the current site"), for: .normal)
        deleteSiteButton.tintColor = WPStyleGuide.errorRed()
        deleteSiteButton.setImage(trashIcon, for: .normal)
    }

    // MARK: - Actions

    @IBAction func deleteSite(_ sender: Any) {
        tableView.deselectSelectedRowWithAnimation(true)
        present(confirmDeleteController(), animated: true, completion: nil)
    }

    @IBAction func contactSupport(_ sender: Any) {
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
                                    SVProgressHUD.showDismissibleSuccess(withStatus: status)

                                    self?.updateNavigationStackAfterSiteDeletion()

                                    let accountService = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext)
                                    accountService.updateUserDetails(for: (accountService.defaultWordPressComAccount()!), success: { _ in }, failure: { _ in })
            },
                                  failure: { error in
                                    DDLogError("Error deleting site: \(error.localizedDescription)")
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
