import UIKit

final class SiteTagsViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    private struct TableConstants {
        static let cellIdentifier = "TagsAdminCell"
        static let accesibilityIdentifier = "SiteTagsList"
        static let numberOfSections = 1
    }
    private let blog: Blog

    fileprivate let noResultsView = WPNoResultsView()

    fileprivate lazy var context: NSManagedObjectContext = {
        return ContextManager.sharedInstance().newMainContextChildContext()
    }()

    fileprivate lazy var predicate: NSPredicate = {
        return NSPredicate(format: "blog.blogID = %@", blog.dotComID!)
    }()

    fileprivate var sortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
    }

    fileprivate lazy var resultsController: NSFetchedResultsController<NSFetchRequestResult> = {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "PostTag")
        request.predicate = self.predicate
        request.sortDescriptors = self.sortDescriptors

        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.context, sectionNameKeyPath: nil, cacheName: nil)
        frc.delegate = self
        return frc
    }()

    @objc
    public init(blog: Blog) {
        self.blog = blog
        super.init(style: .grouped)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setAccessibilityIdentifier()
        applyStyleGuide()
        applyTitle()
        configureTable()
        configureNavigationBar()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshResultsController()
        refreshTags()
        refreshNoResultsView()
    }

    private func setAccessibilityIdentifier() {
        tableView.accessibilityIdentifier = TableConstants.accesibilityIdentifier
    }

    private func applyStyleGuide() {
        WPStyleGuide.configureColors(for: view, andTableView: tableView)
        WPStyleGuide.configureAutomaticHeightRows(for: tableView)
    }

    private func applyTitle() {
        title = NSLocalizedString("Tags", comment: "Label for the Tags Section in the Blog Settings")
    }

    private func configureTable() {
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.register(WPTableViewCell.classForCoder(), forCellReuseIdentifier: TableConstants.cellIdentifier)
        setupRefreshControl()
    }

    private func setupRefreshControl() {
        if refreshControl == nil {
            refreshControl = UIRefreshControl()
            refreshControl?.addTarget(self, action: #selector(refreshTags), for: .valueChanged)
        }
    }

    @objc private func refreshResultsController() {
        resultsController.fetchRequest.predicate = predicate
        resultsController.fetchRequest.sortDescriptors = sortDescriptors
        do {
            try resultsController.performFetch()

            tableView.reloadData()
        } catch {
            DDLogError("Error fetching PostTags: \(error)")
        }
    }

    @objc private func refreshTags() {
        let tagsService = PostTagService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        refreshControl?.beginRefreshing()
        tagsService.syncTags(for: blog, success: { [weak self] tags in
            self?.refreshControl?.endRefreshing()
        }) { [weak self] error in
            self?.tagsFailedLoading(error: error)
        }
    }

    private func configureNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                            target: self,
                                                            action: #selector(createTag))
    }

    @objc private func createTag() {
        let emptyTag = PostTag()
        navigate(to: emptyTag)
    }

    private func refreshNoResultsView() {

        print(" fecthedObjects ", resultsController.fetchedObjects)
        print(" count " , resultsController.fetchedObjects?.count)

        if resultsController.fetchedObjects != nil && resultsController.fetchedObjects?.count != 0 {
            noResultsView.removeFromSuperview()
            return
        }

//        if resultsController.fetchedObjects?.count != 0 {
//            noResultsView.removeFromSuperview()
//            return
//        }

        noResultsView.accessoryView = noResultsAccessoryView()
        noResultsView.titleText = noResultsTitle()
        noResultsView.messageText = noResultsMessage()
        noResultsView.buttonTitle = noResultsButtonTitle()
        noResultsView.button.addTarget(self, action: #selector(createTag), for: .touchUpInside)

        if noResultsView.superview == nil {
            tableView.addSubview(withFadeAnimation: noResultsView)
        }
    }

    func tagsFailedLoading(error: Error) {
        DDLogError("Tag management. Error loading tags for \(String(describing: blog.url)): \(error)")
    }
}

// MARK: - Table view datasource
extension SiteTagsViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return resultsController.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultsController.sections?[section].numberOfObjects ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TableConstants.cellIdentifier, for: indexPath)

        guard let tag = tagAtIndexPath(indexPath) else {
            return UITableViewCell()
        }

        cell.textLabel?.text = tag.name

        return cell
    }

    fileprivate func tagAtIndexPath(_ indexPath: IndexPath) -> PostTag? {
        return resultsController.object(at: indexPath) as? PostTag
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        refreshNoResultsView()
        //tableView.reloadData()
    }
}

// MARK: - Table view delegate
extension SiteTagsViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let selectedTag = tagAtIndexPath(indexPath) else {
            return
        }

        navigate(to: selectedTag)
    }
}

// MARK: - Navigation
extension SiteTagsViewController {
    fileprivate func navigate(to tag: PostTag) {
        let singleTag = SiteTagViewController(blog: blog, tag: tag)
        navigationController?.pushViewController(singleTag, animated: true)
    }
}

// MARK: - Empty state placeholder
extension SiteTagsViewController {
    fileprivate func noResultsTitle() -> String {
        return NSLocalizedString("No Tags Yet", comment: "Empty state. Tags management (Settings > Writing > Tags)")
    }

    fileprivate func noResultsMessage() -> String {
        return NSLocalizedString("Would you like to create one?", comment: "Displayed when the user views tags in blog settings and there are no tags")
    }

    fileprivate func noResultsAccessoryView() -> UIView {
        return UIImageView(image: UIImage(named: "illustration-posts"))
    }

    fileprivate func noResultsButtonTitle() -> String {
        return NSLocalizedString("Add New Tag", comment: "Title of the button in the placeholder for an empty list of blog tags.")
    }
}
