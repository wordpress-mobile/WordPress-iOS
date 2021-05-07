class UserProfileSheetViewController: UITableViewController {

    // MARK: - Properties

    private let user: LikeUser

    private lazy var mainContext = {
        return ContextManager.sharedInstance().mainContext
    }()

    private lazy var contentCoordinator: ContentCoordinator = {
        return DefaultContentCoordinator(controller: self, context: mainContext)
    }()

    private let contentSizeKeyPath = "contentSize"

    // MARK: - Init

    init(user: LikeUser) {
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

        tableView.addObserver(self, forKeyPath: contentSizeKeyPath, options: .new, context: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        tableView.removeObserver(self, forKeyPath: contentSizeKeyPath)
        super.viewWillDisappear(animated)
    }

    // Update preferredContentSize when the table size changes
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath == contentSizeKeyPath else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }

        guard !UIDevice.isPad(),
              let newSize = change?[.newKey] as? CGSize else {
            return
        }

        preferredContentSize = newSize
        presentedVC?.presentedView?.layoutIfNeeded()
    }

    // We are using intrinsicHeight as the view's collapsedHeight which is calculated from the preferredContentSize.
    override var preferredContentSize: CGSize {
        set {
            // no-op, but is needed to override the property.
        }
        get {
            return UIDevice.isPad() ? Constants.iPadPreferredContentSize : tableView.contentSize
        }
    }

}

// MARK: - DrawerPresentable Extension

extension UserProfileSheetViewController: DrawerPresentable {

    var collapsedHeight: DrawerHeight {
        if traitCollection.verticalSizeClass == .compact {
            return .maxHeight
        }

        tableView.layoutIfNeeded()
        return .intrinsicHeight
    }

    var scrollableView: UIScrollView? {
        return tableView
    }

}

// MARK: - UITableViewDataSource methods

extension UserProfileSheetViewController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        return user.preferredBlog != nil ? 2 : 1
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
        return section == Constants.userInfoSection ? 0 : UITableView.automaticDimension
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

        guard let blog = user.preferredBlog else {
            return
        }

        guard blog.blogID > 0 else {
            showSiteWebView(withUrl: blog.blogUrl)
            return
        }

        showSiteTopicWithID(NSNumber(value: blog.blogID))

    }

    func showSiteTopicWithID(_ siteID: NSNumber) {
        let controller = ReaderStreamViewController.controllerWithSiteID(siteID, isFeed: false)
        controller.statSource = ReaderStreamViewController.StatSource.user_profile
        let navController = UINavigationController(rootViewController: controller)
        present(navController, animated: true)
    }

    func showSiteWebView(withUrl url: String?) {

        guard let urlString = url,
              !urlString.isEmpty,
              let siteURL = URL(string: urlString) else {
            DDLogError("User Profile: Error creating URL from site string.")
            return
        }

    contentCoordinator.displayWebViewWithURL(siteURL)
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: UserProfileSiteCell.defaultReuseID) as? UserProfileSiteCell,
              let blog = user.preferredBlog else {
            return UITableViewCell()
        }

        cell.configure(withBlog: blog)
        return cell
    }

    enum Constants {
        static let userInfoSection = 0
        static let siteSectionTitle = NSLocalizedString("Site", comment: "Header for a single site, shown in Notification user profile.").localizedUppercase
        static let iPadPreferredContentSize = CGSize(width: 300.0, height: 270.0)
    }

}
