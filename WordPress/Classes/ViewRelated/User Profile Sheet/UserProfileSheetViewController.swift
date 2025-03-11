import WordPressUI

class UserProfileSheetViewController: UITableViewController {

    // MARK: - Properties

    private let user: LikeUser

    // Used for the `source` property in Stats when a Blog is previewed by URL (that is, in a WebView).
    var blogUrlPreviewedSource: String?

    private lazy var mainContext = {
        return ContextManager.shared.mainContext
    }()

    private lazy var contentCoordinator: ContentCoordinator = {
        return DefaultContentCoordinator(controller: self, context: mainContext)
    }()

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

        tableView.contentInset.top = 24 // For grabber and extra inset in popover
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        var size = tableView.contentSize
        size.height += tableView.contentInset.top
        preferredContentSize = size
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
        controller.statSource = ReaderStreamViewController.StatSource.notif_like_list_user_profile
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

        WPAnalytics.track(.blogUrlPreviewed, properties: ["source": blogUrlPreviewedSource as Any])
        contentCoordinator.displayWebViewWithURL(siteURL, source: blogUrlPreviewedSource ?? "user_profile_sheet")
    }

    func configureTable() {
        tableView.backgroundColor = .systemBackground
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
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
    }
}
