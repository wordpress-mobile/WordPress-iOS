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
    @objc class func controller(_ blog: Blog) -> DeleteSiteViewController {
        let storyboard = UIStoryboard(name: "DeleteSite", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: "DeleteSiteViewController") as! DeleteSiteViewController
        controller.blog = blog
        return controller
    }

    // MARK: - Properties

    @objc var blog: Blog!

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
    @IBOutlet private var deleteButtonContainerView: UIView!

    // MARK: - View Lifecycle

    override open func viewDidLoad() {
        super.viewDidLoad()

        assert(blog != nil)
        title = NSLocalizedString("Delete Site", comment: "Title of settings page for deleting a site")
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 500.0
        WPStyleGuide.configureColors(view: view, tableView: tableView)
        setupHeaderSection()
        setupListSection()
        setupMainBodySection()
        setupDeleteButton()
    }

    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { _ in
            self.tableView.reloadData()
        })
    }

    // MARK: - Configuration

    /// One time setup of section one (header)
    ///
    fileprivate func setupHeaderSection() {
        let warningIcon = Gridicon.iconOfType(.notice, withSize: CGSize(width: 48.0, height: 48.0))
        warningImage.image = warningIcon
        warningImage.tintColor = UIColor.warning
        siteTitleLabel.textColor = .neutral(.shade70)
        siteTitleLabel.font = WPStyleGuide.fontForTextStyle(.footnote, fontWeight: .semibold)
        siteTitleLabel.text = blog.displayURL as String?
        siteTitleSubText.textColor = .neutral(.shade70)
        siteTitleSubText.text = NSLocalizedString("will be unavailable in the future.",
                                                  comment: "Second part of delete screen title stating [the site] will be unavailable in the future.")
    }

    /// One time setup of second section (list)
    ///
    fileprivate func setupListSection() {
        sectionTwoHeader.textColor = .neutral(.shade30)
        sectionTwoHeader.font = WPStyleGuide.fontForTextStyle(.footnote, fontWeight: .semibold)
        sectionTwoColumnItems.forEach({ $0.textColor = .neutral(.shade70) })

        sectionTwoHeader.text = NSLocalizedString("these items will be deleted:",
                                                  comment: "Header of delete screen section listing things that will be deleted.").localizedUppercase

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
        paragraphStyle.alignment = .natural

        let attributes: [NSAttributedString.Key: Any] = [.font: WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular),
                                                        .foregroundColor: UIColor.neutral(.shade70),
                                                        .paragraphStyle: paragraphStyle ]
        let htmlAttributes: StyledHTMLAttributes = [.BodyAttribute: attributes]

        let attributedText1 = NSAttributedString.attributedStringWithHTML(paragraph1, attributes: htmlAttributes)
        let attributedText2 = NSAttributedString(string: paragraph2, attributes: attributes)

        let combinedAttributedString = NSMutableAttributedString()
        combinedAttributedString.append(attributedText1)
        combinedAttributedString.append(NSAttributedString(string: "\n\r", attributes: attributes))
        combinedAttributedString.append(attributedText2)
        sectionThreeBody.attributedText = combinedAttributedString
        sectionThreeBody.textColor = .neutral(.shade70)

        let contactButtonAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.primary,
                                                                     .underlineStyle: NSUnderlineStyle.single.rawValue]
        supportButton.setAttributedTitle(NSAttributedString(string: NSLocalizedString("Contact Support",
                                                            comment: "Button label for contacting support"),
                                                            attributes: contactButtonAttributes),
                                                            for: .normal)

        supportButton.naturalContentHorizontalAlignment = .leading
    }

    /// One time setup of fourth section (delete button)
    ///
    fileprivate func setupDeleteButton() {
        deleteButtonContainerView.backgroundColor = .listForeground

        let trashIcon = Gridicon.iconOfType(.trash)
        deleteSiteButton.setTitle(NSLocalizedString("Delete Site", comment: "Button label for deleting the current site"), for: .normal)
        deleteSiteButton.tintColor = .error
        deleteSiteButton.setImage(trashIcon.imageWithTintColor(.error), for: .normal)
        deleteSiteButton.setImage(trashIcon.imageWithTintColor(.error(.shade70)), for: .highlighted)
        deleteSiteButton.setTitleColor(.error, for: .normal)
        deleteSiteButton.setTitleColor(.error(.shade70), for: .highlighted)
        deleteSiteButton.titleLabel?.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .semibold)
    }

    // MARK: - Actions

    @IBAction func deleteSite(_ sender: Any) {
        tableView.deselectSelectedRowWithAnimation(true)
        present(confirmDeleteController(), animated: true)
    }

    @IBAction func contactSupport(_ sender: Any) {
        tableView.deselectSelectedRowWithAnimation(true)

        WPAppAnalytics.track(.siteSettingsStartOverContactSupportClicked, with: blog)

        if ZendeskUtils.zendeskEnabled {
            ZendeskUtils.sharedInstance.showNewRequestIfPossible(from: self, with: .deleteSite)
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

        // Create atributed strings for URL and message body so we can wrap the URL byCharWrapping.
        let styledUrl: NSMutableAttributedString = NSMutableAttributedString(string: blog.displayURL! as String)
        let urlParagraphStyle = NSMutableParagraphStyle()
        urlParagraphStyle.lineBreakMode = .byCharWrapping
        styledUrl.addAttribute(.paragraphStyle, value: urlParagraphStyle, range: NSMakeRange(0, styledUrl.string.count - 1))

        let message = NSLocalizedString("\nTo confirm, please re-enter your site's address before deleting.\n\n",
                                             comment: "Message of Delete Site confirmation alert; substitution is site's host.")
        let styledMessage: NSMutableAttributedString = NSMutableAttributedString(string: message)
        styledMessage.append(styledUrl)

        // Create alert
        let confirmTitle = NSLocalizedString("Confirm Delete Site", comment: "Title of Delete Site confirmation alert")
        let alertController = UIAlertController(title: confirmTitle, message: nil, preferredStyle: .alert)
        alertController.setValue(styledMessage, forKey: "attributedMessage")

        let cancelTitle = NSLocalizedString("Cancel", comment: "Alert dismissal title")
        alertController.addCancelActionWithTitle(cancelTitle, handler: nil)

        let deleteTitle = NSLocalizedString("Permanently Delete Site", comment: "Delete Site confirmation action title")
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
    @objc func alertTextFieldDidChange(_ sender: UITextField) {
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
                                    accountService.updateUserDetails(for: (accountService.defaultWordPressComAccount()!),
                                                                     success: { () in },
                                                                     failure: { _ in })
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
                    WPStyleGuide.configureColors(view: emptyViewController.view, tableView: nil)

                    self.navigationController?.viewControllers = [emptyViewController]
                }
            }

            // Pop the primary navigation controller back to the sites list
            primaryNavigationController.popToRootViewController(animated: true)
        }
    }

}
