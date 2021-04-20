class UserProfileSheetViewController: UITableViewController {

    // MARK: - Properties

    private let user: RemoteUser

    private lazy var mainContext = {
        return ContextManager.sharedInstance().mainContext
    }()

    private lazy var contentCoordinator: ContentCoordinator = {
        return DefaultContentCoordinator(controller: self, context: mainContext)
    }()

    // MARK: - Init

    init(user: RemoteUser) {
        self.user = user
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTable()
        registerTableCells()
    }

    // We are using intrinsicHeight as the view's collapsedHeight which is calculated from the preferredContentSize.
    override var preferredContentSize: CGSize {
        set {
            // no-op, but is needed to override the property.
        }
        get {
            return UIDevice.isPad() ? Constants.iPadPreferredContentSize :
                                      Constants.iPhonePreferredContentSize
        }
    }

}

// MARK: - DrawerPresentable Extension

extension UserProfileSheetViewController: DrawerPresentable {

    var collapsedHeight: DrawerHeight {
        if traitCollection.verticalSizeClass == .compact {
            return .maxHeight
        }

        return .intrinsicHeight
    }

    var scrollableView: UIScrollView? {
        return tableView
    }

}

// MARK: - UITableViewDataSource methods

extension UserProfileSheetViewController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        // TODO: if no site, return 1.
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case Constants.userInfoSection:
            return userInfoCell()
        default:
            return siteCell()
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        // Don't show section header for User Info
        guard section != Constants.userInfoSection,
              let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: UserProfileSectionHeader.defaultReuseID) as? UserProfileSectionHeader else {
            return nil
        }

        // TODO: Don't show section header if there are no sites.

        header.titleLabel.text = Constants.siteSectionTitle
        return header
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.section == Constants.userInfoSection ? UserProfileUserInfoCell.estimatedRowHeight :
                                                                UserProfileSiteCell.estimatedRowHeight
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {

        // TODO: return 0 if there are no sites.
        if section == Constants.userInfoSection {
            return 0
        }

        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section != Constants.userInfoSection else {
            return
        }

        showSite()
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - Private Extension

private extension UserProfileSheetViewController {

    func showSite() {
        WPAnalytics.track(.userProfileSheetSiteShown)

        // TODO: Remove. For testing only. Use siteID from user object.
        var stubbySiteID: NSNumber?
        // use this to test external site
        stubbySiteID = nil
        // use this to test internal site
        // stubbySiteID = NSNumber(value: 9999999999)

        guard let siteID = stubbySiteID else {
            showSiteWebView()
            return
        }

        showSiteTopicWithID(siteID)
    }

    func showSiteTopicWithID(_ siteID: NSNumber) {
        let controller = ReaderStreamViewController.controllerWithSiteID(siteID, isFeed: false)
        controller.statSource = ReaderStreamViewController.StatSource.user_profile
        let navController = UINavigationController(rootViewController: controller)
        present(navController, animated: true)
    }

    func showSiteWebView() {
        // TODO: Remove. For testing only. Use URL from user object.
        let siteUrl = "https://www.funnycatpix.com/"

        guard let url = URL(string: siteUrl) else {
            DDLogError("User Profile: Error creating URL from site string.")
            return
        }

        contentCoordinator.displayWebViewWithURL(url)
    }

    func configureTable() {
        tableView.backgroundColor = .basicBackground
        tableView.separatorStyle = .none
    }

    func registerTableCells() {
        tableView.register(UserProfileUserInfoCell.defaultNib,
                           forCellReuseIdentifier: UserProfileUserInfoCell.defaultReuseID)

        tableView.register(UserProfileSiteCell.defaultNib,
                           forCellReuseIdentifier: UserProfileSiteCell.defaultReuseID)

        tableView.register(UserProfileSectionHeader.defaultNib,
                           forHeaderFooterViewReuseIdentifier: UserProfileSectionHeader.defaultReuseID)
    }

    func userInfoCell() -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: UserProfileUserInfoCell.defaultReuseID) as? UserProfileUserInfoCell else {
            return UITableViewCell()
        }

        cell.configure(withUser: user)
        return cell
    }

    func siteCell() -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: UserProfileSiteCell.defaultReuseID) as? UserProfileSiteCell else {
            return UITableViewCell()
        }

        cell.configure()
        return cell
    }

    enum Constants {
        static let userInfoSection = 0
        static let siteSectionTitle = NSLocalizedString("Site", comment: "Header for a single site, shown in Notification user profile.").localizedUppercase
        static let iPadPreferredContentSize = CGSize(width: 300.0, height: 270.0)
        static let iPhonePreferredContentSize = CGSize(width: UIScreen.main.bounds.width, height: 280.0)
    }

}
