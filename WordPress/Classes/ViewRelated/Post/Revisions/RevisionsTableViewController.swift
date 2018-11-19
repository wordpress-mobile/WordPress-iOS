class RevisionsTableViewController: UITableViewController {
    private var post: AbstractPost?
    private var manager: ShowRevisionsListManger?

    private lazy var noResultsViewController: NoResultsViewController = {
        let noResultsViewController = NoResultsViewController.controller()
        noResultsViewController.delegate = self
        return noResultsViewController
    }()
    private lazy var tableViewHandler: WPTableViewHandler = {
        let tableViewHandler = WPTableViewHandler(tableView: self.tableView)
        tableViewHandler.cacheRowHeights = false
        tableViewHandler.delegate = self
        tableViewHandler.updateRowAnimation = .fade
        return tableViewHandler
    }()

    private lazy var tableViewFooter: RevisionsTableViewFooter = {
        let footerView = RevisionsTableViewFooter(frame: CGRect(origin: .zero,
                                                                size: CGSize(width: tableView.frame.width,
                                                                             height: Sizes.sectionFooterHeight)))
        footerView.setFooterText(post?.dateCreated?.mediumStringWithTime())
        return footerView
    }()

    private var sectionCount: Int {
        return tableViewHandler.resultsController.sections?.count ?? 0
    }

    private var postType: String {
        switch post {
        case _ as Page: return NSLocalizedString("page", comment: "No Result placeholder when an AbstractPost is a type: Page")
        default: return NSLocalizedString("post", comment: "No Result placeholder when an AbstractPost is a type: Post ")
        }
    }

    convenience init(post: AbstractPost) {
        self.init()
        self.post = post
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupManager()
        setupUI()

        tableViewHandler.refreshTableView()
        tableViewFooter.isHidden = sectionCount == 0
        refreshRevisions()
    }
}


private extension RevisionsTableViewController {
    private func setupUI() {
        navigationItem.title = NSLocalizedString("History", comment: "Title of the post history screen")

        let cellNib = UINib(nibName: RevisionsTableViewCell.classNameWithoutNamespaces(),
                            bundle: Bundle(for: RevisionsTableViewCell.self))
        tableView.register(cellNib, forCellReuseIdentifier: RevisionsTableViewCell.reuseIdentifier)
        tableView.cellLayoutMarginsFollowReadableWidth = true

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshRevisions), for: .valueChanged)
        self.refreshControl = refreshControl

        tableView.tableFooterView = tableViewFooter

        WPStyleGuide.configureColors(for: view, andTableView: tableView)
    }

    private func setupManager() {
        manager = ShowRevisionsListManger(post: post, attach: self)
    }

    private func getRevision(at indexPath: IndexPath) -> Revision {
        guard let revision = tableViewHandler.resultsController.object(at: indexPath) as? Revision else {
            preconditionFailure("Expected a Revision object.")
        }

        return revision
    }

    private func getAuthor(for id: NSNumber?) -> BlogAuthor? {
        let authors: [BlogAuthor]? = post?.blog.authors?.allObjects as? [BlogAuthor]
        return authors?.first { $0.userID == id }
    }

    @objc private func refreshRevisions() {
        if sectionCount == 0 {
            configureAndDisplayNoResults(title: String(format: NoResultsText.loadingTitle, postType),
                                         accessoryView: NoResultsViewController.loadingAccessoryView())
        }

        manager?.getRevisions()
    }

    private func configureAndDisplayNoResults(title: String,
                                      subtitle: String? = nil,
                                      buttonTitle: String? = nil,
                                      accessoryView: UIView? = nil) {

        noResultsViewController.configure(title: title,
                                          buttonTitle: buttonTitle,
                                          subtitle: subtitle,
                                          accessoryView: accessoryView)
        displayNoResults()
    }

    private func displayNoResults() {
        addChild(noResultsViewController)
        noResultsViewController.view.frame = tableView.frame
        noResultsViewController.view.frame.origin.y = 0

        tableView.addSubview(withFadeAnimation: noResultsViewController.view)
        noResultsViewController.didMove(toParent: self)
    }

    private func hideNoResults() {
        noResultsViewController.removeFromView()
        tableView.reloadData()
    }
}


extension RevisionsTableViewController: WPTableViewHandlerDelegate {
    func managedObjectContext() -> NSManagedObjectContext {
        return ContextManager.sharedInstance().mainContext
    }

    func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        guard let postId = post?.postID, let siteId = post?.blog.dotComID else {
            preconditionFailure("Expected a postId or a siteId")
        }

        let predicate = NSPredicate(format: "\(#keyPath(Revision.postId)) = %@ && \(#keyPath(Revision.siteId)) = %@", postId, siteId)
        let descriptor = NSSortDescriptor(key: #keyPath(Revision.postModifiedGmt), ascending: false)
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Revision.entityName())
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [descriptor]
        return fetchRequest
    }

    func sectionNameKeyPath() -> String {
        return #keyPath(Revision.revisionDateForSection)
    }

    func configureCell(_ cell: UITableViewCell, at indexPath: IndexPath) {
        guard let cell = cell as? RevisionsTableViewCell else {
            preconditionFailure("The cell should be of class \(String(describing: RevisionsTableViewCell.self))")
        }

        let revision = getRevision(at: indexPath)
        let authors = getAuthor(for: revision.postAuthorId)
        cell.title = revision.revisionDate.shortTimeString()
        cell.subtitle = authors?.username ?? revision.revisionDate.mediumString()
        cell.totalAdd = revision.diff?.totalAdditions.intValue
        cell.totalDel = revision.diff?.totalDeletions.intValue
        cell.avatarURL = authors?.avatarURL
    }

    func getRevisionState(at indexPath: IndexPath) -> RevisionBrowserState {
        let allRevisions = tableViewHandler.resultsController.fetchedObjects as? [Revision] ?? []
        let selectedRevision = getRevision(at: indexPath)
        let selectedIndex = allRevisions.index(of: selectedRevision) ?? 0

        return RevisionBrowserState(revisions: allRevisions, currentIndex: selectedIndex)
    }

    // MARK: Override delegate methodds

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return Sizes.sectionHeaderHeight
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Sizes.cellEstimatedRowHeight
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let sectionInfo = tableViewHandler.resultsController.sections?[section],
            let headerView = Bundle.main.loadNibNamed(PageListSectionHeaderView.classNameWithoutNamespaces(),
                                                      owner: nil,
                                                      options: nil)?.first as? PageListSectionHeaderView else {
                return UIView()
        }

        headerView.setTite(sectionInfo.name)
        return headerView
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: RevisionsTableViewCell.reuseIdentifier, for: indexPath) as? RevisionsTableViewCell else {
            preconditionFailure("The cell should be of class \(String(describing: RevisionsTableViewCell.self))")
        }

        configureCell(cell, at: indexPath)
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let state = getRevisionState(at: indexPath)

        let revisionsStoryboard = UIStoryboard(name: "Revisions", bundle: nil)
        guard let revisionsNC = revisionsStoryboard.instantiateInitialViewController() as? RevisionsNavigationController else {
            return
        }

        revisionsNC.revisionState = state
        present(revisionsNC, animated: true)
    }
}


extension RevisionsTableViewController: NoResultsViewControllerDelegate {
    func actionButtonPressed() {
        refreshRevisions()
    }
}


extension RevisionsTableViewController: RevisionsView {
    func stopLoading(success: Bool, error: Error?) {
        refreshControl?.endRefreshing()
        tableViewHandler.refreshTableView()
        tableViewFooter.isHidden = sectionCount == 0

        switch (success, sectionCount) {
        case (false, let count) where count == 0:
            // When the API call failed and there are no revisions saved yet
            //
            configureAndDisplayNoResults(title: NoResultsText.errorTitle,
                                         subtitle: String(format: NoResultsText.errorSubtitle, postType),
                                         buttonTitle: NoResultsText.reloadButtonTitle)
        case (true, let count) where count == 0:
            // When the API call successed but there are no revisions loaded
            // This is an edge cas. It shouldn't happen since we open the revisions list only if the post revisions array is not empty.
            configureAndDisplayNoResults(title: NoResultsText.noResultsTitle,
                                         subtitle: String(format: NoResultsText.noResultsSubtitle, postType))
        default:
            hideNoResults()
        }
    }
}


private struct Sizes {
    static let sectionHeaderHeight = CGFloat(40.0)
    static let sectionFooterHeight = CGFloat(48.0)
    static let cellEstimatedRowHeight = CGFloat(60.0)
}


private extension Date {
    private static let shortTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.doesRelativeDateFormatting = true
        formatter.timeStyle = .short
        return formatter
    }()

    func shortTimeString() -> String {
        return Date.shortTimeFormatter.string(from: self)
    }
}


struct NoResultsText {
    static let loadingTitle = NSLocalizedString("Loading %@ history...", comment: "Displayed while a call is loading the history. The placeholder might be 'post' or 'page'.")
    static let reloadButtonTitle = NSLocalizedString("Try again", comment: "Re-load the history again. It appears if the loading call fails.")
    static let noResultsTitle = NSLocalizedString("No history yet", comment: "Displayed when a call is made to load the revisions but there's no result or an error.")
    static let noResultsSubtitle = NSLocalizedString("When you make changes to your %@ you'll be able to see the history here", comment: "Displayed when a call is made to load the history but there's no result or an error. The placeholder might be 'post' or 'page'.")
    static let errorTitle = NSLocalizedString("Oops", comment: "Title for the view when there's an error loading the history")
    static let errorSubtitle = NSLocalizedString("There was an error loading the %@ history", comment: "Text displayed when there is a failure loading the history. The placeholder might be 'post' or 'page'.")
}
