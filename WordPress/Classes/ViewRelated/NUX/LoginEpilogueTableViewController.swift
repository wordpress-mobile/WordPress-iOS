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


    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        let headerNib = UINib(nibName: "EpilogueSectionHeaderFooter", bundle: nil)
        tableView.register(headerNib, forHeaderFooterViewReuseIdentifier: Settings.headerReuseIdentifier)

        let userInfoNib = UINib(nibName: "EpilogueUserInfoCell", bundle: nil)
        tableView.register(userInfoNib, forCellReuseIdentifier: Settings.userCellReuseIdentifier)

        view.backgroundColor = .listBackground
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

        return adjustedNumberOfSections + 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == Sections.userInfoSection {
            return 1
        }

        let correctedSection = section - 1
        return blogDataSource.tableView(tableView, numberOfRowsInSection: correctedSection)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section == Sections.userInfoSection else {
            let wrappedPath = IndexPath(row: indexPath.row, section: indexPath.section-1)
            return blogDataSource.tableView(tableView, cellForRowAt: wrappedPath)
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: Settings.userCellReuseIdentifier) as! EpilogueUserInfoCell
        if let info = epilogueUserInfo {
            cell.stopSpinner()
            cell.configure(userInfo: info)
        } else {
            cell.startSpinner()
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard cell is EpilogueUserInfoCell else {
            return
        }

        cell.contentView.backgroundColor = .listForeground
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: Settings.headerReuseIdentifier) as? EpilogueSectionHeaderFooter else {
            fatalError("Failed to get a section header cell")
        }

        cell.titleLabel?.text = title(for: section)
        cell.accessibilityIdentifier = "Login Cell"

        return cell
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return Settings.profileRowHeight
        }

        return Settings.blogRowHeight
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return Settings.headerHeight
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}


// MARK: - UITableViewDelegate methods
//
extension LoginEpilogueTableViewController {

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let headerView = view as? UITableViewHeaderFooterView else {
            return
        }

        headerView.textLabel?.font = UIFont.preferredFont(forTextStyle: .footnote)
        headerView.textLabel?.textColor = .neutral(.shade50)
        headerView.contentView.backgroundColor = .listBackground
    }
}


// MARK: - Private Methods
//
private extension LoginEpilogueTableViewController {

    /// Returns the title for the current section!.
    ///
    func title(for section: Int) -> String {
        if section == Sections.userInfoSection {
            return NSLocalizedString("Logged In As", comment: "Header for user info, shown after loggin in").localizedUppercase
        }

        let rowCount = blogDataSource.tableView(tableView, numberOfRowsInSection: section-1)
        if rowCount > 1 {
            return NSLocalizedString("My Sites", comment: "Header for list of multiple sites, shown after loggin in").localizedUppercase
        }

        return NSLocalizedString("My Site", comment: "Header for a single site, shown after loggin in").localizedUppercase
    }
}


// MARK: - Loading!
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
    private func loadBlog(username: String, xmlrpc: String) -> Blog? {
        let context = ContextManager.sharedInstance().mainContext
        let service = BlogService(managedObjectContext: context)

        return service.findBlog(withXmlrpc: xmlrpc, andUsername: username)
    }

    /// The self-hosted flow sets user info, if no user info is set, assume a wpcom flow and try the default wp account.
    ///
    private func loadEpilogueForDotcom() -> LoginEpilogueUserInfo {
        let context = ContextManager.sharedInstance().mainContext
        let service = AccountService(managedObjectContext: context)
        guard let account = service.defaultWordPressComAccount() else {
            fatalError()
        }

        return LoginEpilogueUserInfo(account: account)
    }

    /// Loads the EpilogueInfo for a SelfHosted site, with the specified credentials, at the given endpoint.
    ///
    private func loadEpilogueForSelfhosted(username: String, password: String, xmlrpc: String, completion: @escaping (LoginEpilogueUserInfo?) -> ()) {
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


// MARK: - UITableViewDelegate methods
//
private extension LoginEpilogueTableViewController {

    enum Sections {
        static let userInfoSection = 0
    }

    enum Settings {
        static let headerReuseIdentifier = "SectionHeader"
        static let userCellReuseIdentifier = "userInfo"
        static let profileRowHeight = CGFloat(140)
        static let blogRowHeight = CGFloat(52)
        static let headerHeight = CGFloat(50)
    }
}
