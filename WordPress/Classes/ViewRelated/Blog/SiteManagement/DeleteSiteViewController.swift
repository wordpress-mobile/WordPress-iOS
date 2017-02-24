import UIKit
import WordPressShared

/// DeleteSiteViewController allows user delete their site.
///
open class DeleteSiteViewController: UITableViewController {

    // MARK: - Properties

    fileprivate var blog: Blog!

    // MARK: - Properties: table content

    let headerView: TableViewHeaderDetailView = {
        let header = NSLocalizedString("Delete Site", comment: "Heading for instructions on Delete Site settings page")
        let detail = NSLocalizedString("This action can not be undone. Deleting the site will remove all content, " +
                                       "contributors, domains, and upgrades from the site.\n\n" +
                                       "It you're unsure about what will be deleted or need any help, not to worry, " +
                                       "our support team is here to answer any questions you may have.",
                                       comment: "Detailed instructions on Delete Site settings page")

       return TableViewHeaderDetailView(title: header, detail: detail)
    }()

    let contactCell: UITableViewCell = {
        let contactTitle = NSLocalizedString("Contact Support", comment: "Button title for contacting support on Delete Site settings page")

        let actionCell = WPTableViewCellDefault(style: .value1, reuseIdentifier: nil)
        actionCell.textLabel?.text = contactTitle
        WPStyleGuide.configureTableViewActionCell(actionCell)
        actionCell.textLabel?.textAlignment = .center

        return actionCell
    }()

    let deleteCell: UITableViewCell = {
        let deleteTitle = NSLocalizedString("Delete Site", comment: "Button title to delete your site on the Delete Site settings page")

        let actionCell = WPTableViewCellDefault(style: .value1, reuseIdentifier: nil)
        actionCell.textLabel?.text = deleteTitle
        WPStyleGuide.configureTableViewActionCell(actionCell)
        actionCell.textLabel?.textAlignment = .center
        actionCell.textLabel?.textColor = .red

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

        title = NSLocalizedString("Delete Site", comment: "Title of settings page for deleting a site")

        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.estimatedSectionHeaderHeight = 100.0
        tableView.sectionHeaderHeight = UITableViewAutomaticDimension

        WPStyleGuide.configureColors(for: view, andTableView: tableView)
    }

    // MARK: - Actions

    fileprivate func deleteSite() {
        tableView.deselectSelectedRowWithAnimation(true)
        // TODO: Fill this in
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

// MARK: - UITableViewDelegate

extension DeleteSiteViewController {
    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        deleteSite()
    }

    override open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return headerView
    }
}

// MARK: - UITableViewDataSource

extension DeleteSiteViewController {
    override open func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            return contactCell
        default:
            return deleteCell
        }
    }
}
