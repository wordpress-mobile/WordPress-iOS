import UIKit
import MessageUI
import WordPressShared

 /// StartOverViewController allows user to trigger help session to remove site content.
 ///
open class StartOverViewController: UITableViewController, MFMailComposeViewControllerDelegate {
    // MARK: - Properties: must be set by creator

    /// The blog whose content we want to remove
    ///
    var blog: Blog!

    // MARK: - Properties: table content

    let headerView: TableViewHeaderDetailView = {
        let header = NSLocalizedString("Let Us Help", comment: "Heading for instructions on Start Over settings page")
        let detail = NSLocalizedString("If you want a site but don't want any of the posts and pages you have now, our support team can delete your posts, pages, media, and comments for you.\n\nThis will keep your site and URL active, but give you a fresh start on your content creation. Just contact us to have your current content cleared out.", comment: "Detail for instructions on Start Over settings page")

       return TableViewHeaderDetailView(title: header, detail: detail)
    }()

    let contactCell: UITableViewCell = {
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
    convenience init(blog: Blog) {
        self.init(style: .grouped)
        self.blog = blog
    }

    // MARK: - View Lifecycle

    override open func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Start Over", comment: "Title of Start Over settings page")

        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.estimatedSectionHeaderHeight = 100.0
        tableView.sectionHeaderHeight = UITableViewAutomaticDimension

        WPStyleGuide.configureColors(for: view, andTableView: tableView)
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
        } else if let googleMailURL = googleMailURL(),
                UIApplication.shared.canOpenURL(googleMailURL) {
            showGoogleMailComposerForURL(googleMailURL)
        } else {
            showAlertToSendEmail()
        }
    }

    // Mark - Email handling

    func mailRecipient() -> String {
        return "help@wordpress.com"
    }

    func mailSubject() -> String {
        guard let siteUrl = self.blog.url else {
            return "Start over"
        }
        return "Start over with site \(siteUrl)"

    }

    func mailBody() -> String {
        guard let siteUrl = self.blog.url else {
            return "I want to start over"
        }
        return "I want to start over with the site \(siteUrl)"
    }

    func showAppleMailComposer() {
        let mailComposeController = MFMailComposeViewController()
        mailComposeController.mailComposeDelegate = self
        mailComposeController.setToRecipients([mailRecipient()])
        mailComposeController.setSubject(mailSubject())
        mailComposeController.setMessageBody(mailBody(), isHTML: false)
        self.present(mailComposeController, animated: true, completion: nil)
    }

    func showGoogleMailComposerForURL(_ url: URL ) {
        UIApplication.shared.open(url)
    }

    func googleMailURL() -> URL? {
        let googleMailString = "googlegmail:///co?to=\(mailRecipient())"
                               + "&subject=\(mailSubject())&body=\(mailBody())"
        return URL(string: googleMailString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!)
    }

    func showAlertToSendEmail() {
        let title = NSLocalizedString("Contact us at \(mailRecipient())",
                                      comment: "Alert title for contact us alert, placeholder for help email address.")
        let message = NSLocalizedString("\nPlease send us an email to have your content cleared out.",
                                        comment: "Message to ask the user to send us an email to clear their content.")
        let alertController =  UIAlertController(title: title,
                                                 message: message,
                                                 preferredStyle: UIAlertControllerStyle.alert)
        alertController.addCancelActionWithTitle(NSLocalizedString("OK",
                                                 comment: "Button title. An acknowledgement of the message displayed in a prompt."))
        alertController.presentFromRootViewController()
    }


    // MARK: - MFMailComposeViewControllerDelegate Method

    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
        if let _ = error {
            showAlertToSendEmail()
        }
    }
}
