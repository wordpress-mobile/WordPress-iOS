class RevisionsTableViewController: UITableViewController {
    private var post: AbstractPost?
    private var manager: ShowRevisionsListManger!

    private lazy var tableViewHandler: WPTableViewHandler = {
        let tableViewHandler = WPTableViewHandler(tableView: self.tableView)
        tableViewHandler.cacheRowHeights = false
        tableViewHandler.delegate = self
        tableViewHandler.updateRowAnimation = .none
        return tableViewHandler
    }()
    private var revisionsSectionsCount: Int {
        return tableViewHandler.resultsController.sections?.count ?? 0
    }


    convenience init(post: AbstractPost) {
        self.init()
        self.post = post
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupPresenter()
        setupUI()

        tableViewHandler.refreshTableView()
        manager.getRevisions()
    }
}


private extension RevisionsTableViewController {
    private func setupUI() {
        navigationItem.title = NSLocalizedString("History", comment: "Title of the post history screen")

        let nibName = String(describing: RevisionsTableViewCell.self)
        let cellNib = UINib(nibName: nibName, bundle: Bundle(for: RevisionsTableViewCell.self))
        tableView.register(cellNib, forCellReuseIdentifier: RevisionsTableViewCell.reuseIdentifier)

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshRevisions), for: .valueChanged)
        tableView.addSubview(refreshControl)

        self.refreshControl = refreshControl

        WPStyleGuide.configureColors(for: view, andTableView: tableView)
    }

    private func setupPresenter() {
        manager = ShowRevisionsListManger(post: post, attach: self)
    }

    @objc private func refreshRevisions() {
        manager.getRevisions()
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
        cell.createdDate = revision.revisionDate.mediumStringWithTime()
        cell.modifiedDate = revision.revisionModifiedDate.toStringForPageSections()
    }

    func getRevision(at indexPath: IndexPath) -> Revision {
        guard let revision = tableViewHandler.resultsController.object(at: indexPath) as? Revision else {
            preconditionFailure("Expected a Revision object.")
        }

        return revision
    }


    // MARK: Override delegate methodds

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return Sizes.sectionHeaderHeight
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return (section != revisionsSectionsCount - 1) ? 0 : Sizes.sectionFooterHeight
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Sizes.cellEstimatedRowHeight
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let nibName = String(describing: RevisionsTableViewFooter.self)
        if let footerView = Bundle.main.loadNibNamed(nibName, owner: nil, options: nil)?.first as? RevisionsTableViewFooter,
            section == revisionsSectionsCount - 1 {
            footerView.setFooterText(post?.dateCreated?.mediumStringWithTime())
            return footerView
        }

        return UIView()
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let nibName = String(describing: PageListSectionHeaderView.self)
        guard let sectionInfo = tableViewHandler.resultsController.sections?[section],
            let headerView = Bundle.main.loadNibNamed(nibName, owner: nil, options: nil)?.first as? PageListSectionHeaderView else {
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
}


extension RevisionsTableViewController: RevisionsView {
    func stopLoading(success: Bool, error: Error?) {
        refreshControl?.endRefreshing()
        tableViewHandler.refreshTableView()
    }
}


private struct Sizes {
    static let sectionHeaderHeight = CGFloat(40.0)
    static let sectionFooterHeight = CGFloat(48.0)
    static let cellEstimatedRowHeight = CGFloat(60.0)
}
