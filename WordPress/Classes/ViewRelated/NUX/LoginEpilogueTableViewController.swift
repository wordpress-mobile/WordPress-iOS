import UIKit
import WordPressShared
import WordPressAuthenticator


// MARK: - LoginEpilogueTableViewController
//
class LoginEpilogueTableViewController: UITableViewController {

    /// TableView's Datasource
    ///
    private let blogDataSource = BlogListDataSource()

    /// Epilogue Metadata
    ///
    private var epilogueUserInfo: LoginEpilogueUserInfo? {
        didSet {
            tableView.reloadData()
        }
    }

    /// Site that was just connected to our awesome app.
    ///
    private var credentials: AuthenticatorCredentials?

    /// Closure to be executed when Connect Site is selected.
    ///
    private var onConnectSite: (() -> Void)?

    /// Flag indicating if the Connect Site option should be displayed.
    ///
    private var showConnectSite: Bool {
        guard let wpcom = credentials?.wpcom else {
            return true
        }

        return !wpcom.isJetpackLogin
    }

    private var tracker: AuthenticatorAnalyticsTracker {
        AuthenticatorAnalyticsTracker.shared
    }


    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        let headerNib = UINib(nibName: "EpilogueSectionHeaderFooter", bundle: nil)
        tableView.register(headerNib, forHeaderFooterViewReuseIdentifier: Settings.headerReuseIdentifier)

        let userInfoNib = UINib(nibName: "EpilogueUserInfoCell", bundle: nil)
        tableView.register(userInfoNib, forCellReuseIdentifier: Settings.userCellReuseIdentifier)

        tableView.register(LoginEpilogueConnectSiteCell.defaultNib,
                           forCellReuseIdentifier: LoginEpilogueConnectSiteCell.defaultReuseID)

        // Remove separator line on last row
        tableView.tableFooterView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 0, height: 1)))

        // To facilitate the button blur effect, the table is extended under the button view.
        // So the last cells can be seen when scrolled, move the content up above the button view.
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 100, right: 0)

        view.backgroundColor = .basicBackground
        tableView.backgroundColor = .basicBackground
    }

    /// Initializes the EpilogueTableView so that data associated with the specified Endpoint is displayed.
    ///
    func setup(with credentials: AuthenticatorCredentials, onConnectSite: (() -> Void)? = nil) {
        self.credentials = credentials
        self.onConnectSite = onConnectSite
        refreshInterface(for: credentials)
    }
}


// MARK: - UITableViewDataSource methods
//
extension LoginEpilogueTableViewController {

    override func numberOfSections(in tableView: UITableView) -> Int {

        // If a section is empty, don't show it.
        let numberOfSections = blogDataSource.numberOfSections(in: tableView)
        var adjustedNumberOfSections = numberOfSections

        for section in 0..<numberOfSections {
            if blogDataSource.tableView(tableView, numberOfRowsInSection: section) == 0 {
                adjustedNumberOfSections -= 1
            }
        }

        // Add one for Connect Site if there are no sites from blogDataSource.
        if adjustedNumberOfSections == 0 && showConnectSite {
            adjustedNumberOfSections += 1
        }

        // Add one for User Info
        return adjustedNumberOfSections + 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == Sections.userInfoSection {
            return 1
        }

        let correctedSection = section - 1
        let siteRows = blogDataSource.tableView(tableView, numberOfRowsInSection: correctedSection)

        // Add one for the Connect Site row if shown.
        return showConnectSite ? siteRows + 1 : siteRows
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // User Info Row
        if indexPath.section == Sections.userInfoSection {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: Settings.userCellReuseIdentifier) as? EpilogueUserInfoCell else {
                return UITableViewCell()
            }
            if let info = epilogueUserInfo {
                cell.stopSpinner()
                cell.configure(userInfo: info)
            } else {
                cell.startSpinner()
            }

            return cell
        }

        // Connect Site Row
        if indexPath.row == lastRowInSection(indexPath.section) && showConnectSite {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: LoginEpilogueConnectSiteCell.defaultReuseID) as? LoginEpilogueConnectSiteCell else {
                return UITableViewCell()
            }

            cell.configure(numberOfSites: numberOfWordPressComBlogs)
            return cell
        }

        // Site Rows
        let wrappedPath = IndexPath(row: indexPath.row, section: indexPath.section - 1)
        let cell = blogDataSource.tableView(tableView, cellForRowAt: wrappedPath)

        guard let loginCell = cell as? LoginEpilogueBlogCell else {
            return cell
        }

        loginCell.adjustSiteNameConstraint()
        return loginCell
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        // Don't show section header for User Info
        guard section != Sections.userInfoSection,
        let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: Settings.headerReuseIdentifier) as? EpilogueSectionHeaderFooter else {
            return nil
        }

        // Don't show section header if there are no sites.
        guard rowCount(forSection: section) > 0 else {
            return nil
        }

        cell.titleLabel?.text = title(for: section)

        cell.accessibilityIdentifier = "siteListHeaderCell"
        cell.accessibilityLabel = cell.titleLabel?.text
        cell.contentView.backgroundColor = .basicBackground
        cell.accessibilityHint = NSLocalizedString("A list of sites on this account.", comment: "Accessibility hint for My Sites list.")

        return cell
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.section == Sections.userInfoSection ? Settings.profileRowHeight : Settings.blogRowHeight
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return Settings.headerHeight
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {

        if section == Sections.userInfoSection {
            return 0
        }

        if rowCount(forSection: section) == 0 {
            tableView.separatorStyle = .none
            return 0
        }

        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section != Sections.userInfoSection,
            indexPath.row == lastRowInSection(indexPath.section) else {
            return
        }

        tracker.track(click: .connectSite)
        tracker.set(flow: .loginWithSiteAddress)
        onConnectSite?()
    }
}

// MARK: - Private Extension
//
private extension LoginEpilogueTableViewController {

    /// Returns the title for a given section.
    ///
    func title(for section: Int) -> String? {
        guard section != Sections.userInfoSection else {
            return nil
        }

        if rowCount(forSection: section) > 1 {
            return NSLocalizedString("My Sites", comment: "Header for list of multiple sites, shown after logging in").localizedUppercase
        }

        return NSLocalizedString("My Site", comment: "Header for a single site, shown after logging in").localizedUppercase
    }

    /// Returns the last row index for a given section.
    ///
    func lastRowInSection(_ section: Int) -> Int {
        return (tableView.numberOfRows(inSection: section) - 1)
    }

    /// Returns the number of WordPress.com sites.
    ///
    var numberOfWordPressComBlogs: Int {
        let context = ContextManager.sharedInstance().mainContext
        return (try? WPAccount.lookupDefaultWordPressComAccount(in: context)?.blogs.count) ?? 0
    }

    func rowCount(forSection section: Int) -> Int {
        return blogDataSource.tableView(tableView, numberOfRowsInSection: section - 1)
    }

    enum Sections {
        static let userInfoSection = 0
    }

    enum Settings {
        static let headerReuseIdentifier = "SectionHeader"
        static let userCellReuseIdentifier = "userInfo"
        static let profileRowHeight = CGFloat(180)
        static let blogRowHeight = CGFloat(60)
        static let headerHeight = CGFloat(50)
    }
}


// MARK: - Loading
//
private extension LoginEpilogueTableViewController {

    /// Refreshes the interface, so that the specified Endpoint's sites are displayed.
    ///
    func refreshInterface(for credentials: AuthenticatorCredentials) {
        if credentials.wpcom != nil {
            epilogueUserInfo = loadEpilogueForDotcom()
        } else if let wporg = credentials.wporg {
            blogDataSource.blog = loadBlog(username: wporg.username, xmlrpc: wporg.xmlrpc)

            loadEpilogueForSelfhosted(username: wporg.username, password: wporg.password, xmlrpc: wporg.xmlrpc) { [weak self] epilogueInfo in
                self?.epilogueUserInfo = epilogueInfo
            }
        }

        // Note: We do this at this point, since it causes the datasource to update it's internal model.
        blogDataSource.loggedIn = true
    }

    /// Loads the Blog for a given Username / XMLRPC, if any.
    ///
    func loadBlog(username: String, xmlrpc: String) -> Blog? {
        let context = ContextManager.sharedInstance().mainContext
        let service = BlogService(managedObjectContext: context)

        return service.findBlog(withXmlrpc: xmlrpc, andUsername: username)
    }

    /// The self-hosted flow sets user info, if no user info is set, assume a wpcom flow and try the default wp account.
    ///
    func loadEpilogueForDotcom() -> LoginEpilogueUserInfo {
        let context = ContextManager.sharedInstance().mainContext
        do {
            let account = try WPAccount.lookupDefaultWordPressComAccount(in: context)
            precondition(account != nil, "Account must be present for \(#function)")
            return LoginEpilogueUserInfo(account: account!)
        } catch let err {
            preconditionFailure(err.localizedDescription)
        }
    }

    /// Loads the EpilogueInfo for a SelfHosted site, with the specified credentials, at the given endpoint.
    ///
    func loadEpilogueForSelfhosted(username: String, password: String, xmlrpc: String, completion: @escaping (LoginEpilogueUserInfo?) -> ()) {
        guard let service = UsersService(username: username, password: password, xmlrpc: xmlrpc) else {
            completion(nil)
            return
        }

        /// Load: User's Profile
        ///
        service.fetchProfile { userProfile in
            guard let userProfile = userProfile else {
                completion(nil)
                return
            }

            var epilogueInfo = LoginEpilogueUserInfo(profile: userProfile)

            /// Load: Gravatar's Metadata
            ///
            let service = GravatarService()
            service.fetchProfile(email: userProfile.email) { gravatarProfile in
                if let gravatarProfile = gravatarProfile {
                    epilogueInfo.update(with: gravatarProfile)
                }

                completion(epilogueInfo)
            }
        }
    }
}
