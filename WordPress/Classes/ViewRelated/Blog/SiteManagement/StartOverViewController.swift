import UIKit
import WordPressShared

 /// StartOverViewController allows user to trigger help session to remove site content.
 ///
open class StartOverViewController: UITableViewController {
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
            "Source": "Start Over" as AnyObject,
            "Blog": blog.logDescription() as AnyObject,
            HelpshiftSupportTagsKey: tags as AnyObject
            ]

        return [HelpshiftSupportCustomMetadataKey: options]
    }
}
