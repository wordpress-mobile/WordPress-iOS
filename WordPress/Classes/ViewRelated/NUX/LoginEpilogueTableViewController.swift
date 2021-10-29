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

    private var tracker: AuthenticatorAnalyticsTracker {
        AuthenticatorAnalyticsTracker.shared
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        let userInfoNib = UINib(nibName: "EpilogueUserInfoCell", bundle: nil)
        tableView.register(userInfoNib, forCellReuseIdentifier: Settings.userCellReuseIdentifier)
        tableView.register(LoginEpilogueChooseSiteTableViewCell.self, forCellReuseIdentifier: Settings.chooseSiteReuseIdentifier)

        // Remove separator line on last row
        tableView.tableFooterView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 0, height: 1)))

        view.backgroundColor = .basicBackground
        tableView.backgroundColor = .basicBackground
    }

    /// Initializes the EpilogueTableView so that data associated with the specified Endpoint is displayed.
    ///
    func setup(with credentials: AuthenticatorCredentials) {
        self.credentials = credentials
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

        // Add one for User Info
        return adjustedNumberOfSections + 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == Sections.userInfoSection {
            return 2
        }

        let correctedSection = section - 1
        let siteRows = blogDataSource.tableView(tableView, numberOfRowsInSection: correctedSection)

        if siteRows < 4, let parent = parent as? LoginEpilogueViewController {
            parent.hideButtonPanel()
        }

        return siteRows
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // User Info Row
        if indexPath.section == Sections.userInfoSection {
            if indexPath.row == 0 {
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
            } else if indexPath.row == 1 {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: Settings.chooseSiteReuseIdentifier, for: indexPath) as? LoginEpilogueChooseSiteTableViewCell else {
                    return UITableViewCell()
                }
                return cell
            }
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

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.section == Sections.userInfoSection ? Settings.profileRowHeight : Settings.blogRowHeight
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
}

// MARK: - Private Extension
//
private extension LoginEpilogueTableViewController {
    /// Returns the last row index for a given section.
    ///
    func lastRowInSection(_ section: Int) -> Int {
        return (tableView.numberOfRows(inSection: section) - 1)
    }

    /// Returns the number of WordPress.com sites.
    ///
    /*
    var numberOfWordPressComBlogs: Int {
        let context = ContextManager.sharedInstance().mainContext
        let service = AccountService(managedObjectContext: context)

        return service.defaultWordPressComAccount()?.blogs.count ?? 0
    }
    */

    func rowCount(forSection section: Int) -> Int {
        return blogDataSource.tableView(tableView, numberOfRowsInSection: section - 1)
    }

    enum Sections {
        static let userInfoSection = 0
    }

    enum Settings {
        static let headerReuseIdentifier = "SectionHeader"
        static let userCellReuseIdentifier = "userInfo"
        static let chooseSiteReuseIdentifier = "chooseSite"
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
        let service = AccountService(managedObjectContext: context)
        guard let account = service.defaultWordPressComAccount() else {
            fatalError()
        }

        return LoginEpilogueUserInfo(account: account)
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
