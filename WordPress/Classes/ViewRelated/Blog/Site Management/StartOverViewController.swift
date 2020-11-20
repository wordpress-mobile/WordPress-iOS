import UIKit
import MessageUI
import WordPressShared

 /// StartOverViewController allows user to trigger help session to remove site content.
 ///
open class StartOverViewController: UITableViewController, MFMailComposeViewControllerDelegate {
    // MARK: - Properties: must be set by creator

    /// The blog whose content we want to remove
    ///
    @objc var blog: Blog!

    // MARK: - Properties: table content

    @objc let headerView: TableViewHeaderDetailView = {
        let header = NSLocalizedString("Let Us Help", comment: "Heading for instructions on Start Over settings page")
        let detail1 = NSLocalizedString("If you want a site but do not want any of the posts and pages you have now, " +
                                        "our support team can delete your posts, pages, media, and comments for you.",
                                        comment: "Detailed instructions on Start Over settings page. This is the first paragraph.")
        let doubleNewline = "\n\n"
        let detail2 = NSLocalizedString("This will keep your site and URL active, " +
                                        "but give you a fresh start on your content creation. " +
                                        "Just contact us to have your current content cleared out.",
                                        comment: "Detailed instructions on Start Over settings page. This is the second paragraph.")
        let detail = String.localizedStringWithFormat("%@%@%@", detail1, doubleNewline, detail2)

       return TableViewHeaderDetailView(title: header, detail: detail)
    }()

    @objc let contactCell: UITableViewCell = {
        let contactTitle = NSLocalizedString("Contact Support", comment: "Button to contact support on Start Over settings page")

        let actionCell = WPTableViewCellDefault(style: .value1, reuseIdentifier: nil)
        actionCell.textLabel?.text = contactTitle
        WPStyleGuide.configureTableViewActionCell(actionCell)
        actionCell.textLabel?.textAlignment = .center

        return actionCell
    }()

    // MARK: - Initializer

    /// Preferred initializer for DeleteSiteViewController
    ///
    /// - Parameter blog: The Blog currently at the site
    ///
    @objc convenience init(blog: Blog) {
        self.init(style: .grouped)
        self.blog = blog
    }

    // MARK: - View Lifecycle

    override open func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Start Over", comment: "Title of Start Over settings page")

        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.estimatedSectionHeaderHeight = 100.0
        tableView.sectionHeaderHeight = UITableView.automaticDimension

        WPStyleGuide.configureColors(view: view, tableView: tableView)
    }

    // MARK: Table View Data Source

    override open func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return contactCell
    }

    // MARK: - Table View Delegate

    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        contactSupport()
    }

    override open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return headerView
    }

    // MARK: - Actions

    fileprivate func contactSupport() {
        tableView.deselectSelectedRowWithAnimation(true)

        WPAppAnalytics.track(.siteSettingsStartOverContactSupportClicked, with: blog)
        if MFMailComposeViewController.canSendMail() {
            showAppleMailComposer()
        } else if let googleMailURL = googleMailURL,
                UIApplication.shared.canOpenURL(googleMailURL) {
            showGoogleMailComposerForURL(googleMailURL)
        } else {
            showAlertToSendEmail()
        }
    }

    // Mark - Email handling

    @objc let mailRecipient = "help@wordpress.com"

    @objc var mailSubject: String {
        guard let displayURL = self.blog.displayURL else {
            return "Start over"
        }
        return "Start over with site \(displayURL)"
    }

    @objc var mailBody: String {
        guard let siteURL = self.blog.url else {
            return "I want to start over"
        }
        return "I want to start over with the site \(siteURL)"
    }

    @objc var googleMailURL: URL? {
        let googleMailString = "googlegmail:///co?to=\(mailRecipient)"
            + "&subject=\(mailSubject)&body=\(mailBody)"
        return URL(string: googleMailString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!)
    }

    @objc func showAppleMailComposer() {
        let mailComposeController = MFMailComposeViewController()
        mailComposeController.mailComposeDelegate = self
        mailComposeController.setToRecipients([mailRecipient])
        mailComposeController.setSubject(mailSubject)
        mailComposeController.setMessageBody(mailBody, isHTML: false)
        present(mailComposeController, animated: true)
    }

    @objc func showGoogleMailComposerForURL(_ url: URL ) {
        UIApplication.shared.open(url)
    }

    @objc func showAlertToSendEmail() {
        let title = String(format: NSLocalizedString("Contact us at %@", comment: "Alert title for contact us alert, placeholder for help email address, inserted at run time."), mailRecipient)
        let message = NSLocalizedString("\nPlease send us an email to have your content cleared out.", comment: "Message to ask the user to send us an email to clear their content.")

        let alertController =  UIAlertController(title: title,
                                                 message: message,
                                                 preferredStyle: .alert)
        alertController.addCancelActionWithTitle(NSLocalizedString("OK",
                                                 comment: "Button title. An acknowledgement of the message displayed in a prompt."))
        alertController.presentFromRootViewController()
    }


    // MARK: - MFMailComposeViewControllerDelegate Method

    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
        if let _ = error {
            showAlertToSendEmail()
        }
    }
}
