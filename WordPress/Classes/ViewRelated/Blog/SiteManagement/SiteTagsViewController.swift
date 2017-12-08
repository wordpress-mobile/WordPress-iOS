import UIKit

final class SiteTagsViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    private struct TableConstants {
        static let cellIdentifier = "TitleBadgeDisclosureCell"
        static let accesibilityIdentifier = "SiteTagsList"
        static let numberOfSections = 1
    }
    private let blog: Blog

    fileprivate let noResultsView = WPNoResultsView()

    fileprivate lazy var context: NSManagedObjectContext = {
        return ContextManager.sharedInstance().mainContext
    }()

    fileprivate lazy var defaultPredicate: NSPredicate = {
        return NSPredicate(format: "blog.blogID = %@", blog.dotComID!)
    }()

    private let sortDescriptors: [NSSortDescriptor] = {
        return [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
    }()

    fileprivate lazy var resultsController: NSFetchedResultsController<NSFetchRequestResult> = {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "PostTag")
        request.sortDescriptors = self.sortDescriptors

        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.context, sectionNameKeyPath: nil, cacheName: nil)
        frc.delegate = self
        return frc
    }()

    fileprivate lazy var searchController: UISearchController = {
        let returnValue = UISearchController(searchResultsController: nil)
        returnValue.hidesNavigationBarDuringPresentation = false
        returnValue.dimsBackgroundDuringPresentation = false
        returnValue.searchResultsUpdater = self
        self.definesPresentationContext = true

        WPStyleGuide.configureSearchBar(returnValue.searchBar)
        return returnValue
    }()

    private var isSyncing = false

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
        setupTable()
        setupNavigationBar()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshResultsController(predicate: defaultPredicate)
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

    private func setupTable() {
        tableView.tableFooterView = UIView(frame: .zero)
        let nibName = UINib(nibName: TableConstants.cellIdentifier, bundle: nil)
        tableView.register(nibName, forCellReuseIdentifier: TableConstants.cellIdentifier)
        setupRefreshControl()
    }

    private func setupRefreshControl() {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(refreshTags), for: .valueChanged)
        refreshControl = control
    }

    @objc private func refreshResultsController(predicate: NSPredicate) {
        resultsController.fetchRequest.predicate = predicate
        resultsController.fetchRequest.sortDescriptors = sortDescriptors
        do {
            try resultsController.performFetch()

            tableView.reloadData()
        } catch {
            tagsFailedLoading(error: error)
        }
    }

    @objc private func refreshTags() {
        isSyncing = true
        let tagsService = PostTagService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        tagsService.syncTags(for: blog, success: { [weak self] tags in
            self?.isSyncing = false
            self?.refreshControl?.endRefreshing()
            self?.refreshNoResultsView()
        }) { [weak self] error in
            self?.tagsFailedLoading(error: error)
        }
    }

    private func setupNavigationBar() {
        configureRightButton()
    }

    private func configureRightButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                            target: self,
                                                            action: #selector(createTag))
    }

    private func setupSearchBar() {
       tableView.tableHeaderView = searchController.searchBar
    }

    private func removeSearchBar() {
        tableView.tableHeaderView = nil
    }

    @objc private func createTag() {
        navigate(toTag: nil)
    }

    private func refreshNoResultsView() {
        guard resultsController.fetchedObjects?.count == 0 else {
            noResultsView.removeFromSuperview()
            setupSearchBar()
            tableView.reloadData()
            return
        }

        if isSyncing {
            setupLoadingView()
        } else {
            setupEmptyResultsView()
        }

        if noResultsView.superview == nil {
            tableView.addSubview(withFadeAnimation: noResultsView)
        }

        removeSearchBar()
    }

    private func setupLoadingView() {
        noResultsView.accessoryView = nil
        noResultsView.titleText = loadingMessage()
        noResultsView.messageText = ""
        noResultsView.buttonTitle = ""
    }

    private func setupEmptyResultsView() {
        noResultsView.accessoryView = noResultsAccessoryView()
        noResultsView.titleText = noResultsTitle()
        noResultsView.messageText = noResultsMessage()
        noResultsView.buttonTitle = noResultsButtonTitle()
        noResultsView.button.addTarget(self, action: #selector(createTag), for: .touchUpInside)
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TableConstants.cellIdentifier, for: indexPath) as? TitleBadgeDisclosureCell, let tag = tagAtIndexPath(indexPath) else {
            return TitleBadgeDisclosureCell()
        }

        cell.name = tag.name

        if let count = tag.postCount?.intValue, count > 0 {
            cell.count = count
        }

        cell.setBadgeTap { [weak self] in
            self?.showPostList(indexPath)
        }

        return cell
    }

    fileprivate func tagAtIndexPath(_ indexPath: IndexPath) -> PostTag? {
        return resultsController.object(at: indexPath) as? PostTag
    }

    private func showPostList(_ indexPath: IndexPath) {
        print("showing post list for index path ", indexPath)
        guard let tag = tagAtIndexPath(indexPath) else {
            return
        }

        navigate(toPosts: tag)
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        refreshNoResultsView()
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        guard let selectedTag = tagAtIndexPath(indexPath) else {
            return
        }

        delete(selectedTag)
    }

    private func delete(_ tag: PostTag) {
        let tagsService = PostTagService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        tagsService.delete(tag, for: blog)
    }

    private func save(_ tag: PostTag) {
        let tagsService = PostTagService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        tagsService.commit(tag, for: blog)
    }
}

// MARK: - Table view delegate
extension SiteTagsViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let selectedTag = tagAtIndexPath(indexPath) else {
            return
        }

        navigate(toTag: selectedTag)
    }
}

// MARK: - Navigation to Tag details
extension SiteTagsViewController {
    fileprivate func navigate(toTag details: PostTag?) {
        let data = SettingsTitleSubtitleController.Data(title: details?.name, subtitle: details?.tagDescription)
        let confirmationStrings = confirmation()
        let singleTag = SettingsTitleSubtitleController(data: data, confirmation: confirmationStrings)

        singleTag.setAction { updatedData in
            self.navigationController?.popViewController(animated: true)

            guard let tag = details else {
                return
            }

            self.delete(tag)
        }

        singleTag.setUpdate { updatedData in
            guard let tag = details else {
                self.addTag(data: updatedData)
                return
            }

            tag.name = updatedData.title
            tag.tagDescription = updatedData.subtitle

            self.save(tag)
        }

        navigationController?.pushViewController(singleTag, animated: true)
    }

    private func addTag(data: SettingsTitleSubtitleController.Data) {
        guard let newTag = NSEntityDescription.insertNewObject(forEntityName: "PostTag", into: ContextManager.sharedInstance().mainContext) as? PostTag else {
            return
        }

        newTag.name = data.title
        newTag.tagDescription = data.subtitle

        self.save(newTag)
    }

    private func confirmation() -> SettingsTitleSubtitleController.Confirmation {
        let confirmationTitle = NSLocalizedString("Delete this tag", comment: "Delete Tag confirmation action title")
        let confirmationSubtitle = NSLocalizedString("Are you sure you want to delete this tag?", comment: "Message asking for confirmation on tag deletion")
        let actionTitle = NSLocalizedString("Delete", comment: "Delete")
        let cancelTitle = NSLocalizedString("Cancel", comment: "Alert dismissal title")

        return SettingsTitleSubtitleController.Confirmation(title: confirmationTitle,
                                                            subtitle: confirmationSubtitle,
                                                            actionTitle: actionTitle,
                                                            cancelTitle: cancelTitle)
    }
}

// MARK: - Navigate to post list
extension SiteTagsViewController {
    fileprivate func navigate(toPosts tag: PostTag?) {
        guard let tag = tag, let tagName = tag.name else {
            return
        }

        let postList = PostListViewController.controllerWithBlog(blog)
        let matchingTagPredicated = NSPredicate(format: "tags contains %@", tagName)
        let decoratedFilters = DecoratedPostListFilterSettings(blog: blog, postType: .post, predicate: matchingTagPredicated)
        postList.filterSettings = decoratedFilters
        navigationController?.pushViewController(postList, animated: true)
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

    fileprivate func loadingMessage() -> String {
        return NSLocalizedString("Loading...", comment: "Loading tags.")
    }
}

// MARK: - SearchResultsUpdater
extension SiteTagsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text, text != "" else {
            refreshResultsController(predicate: defaultPredicate)

            return
        }

        let filterPredicate = NSPredicate(format: "blog.blogID = %@ AND name contains [cd] %@", blog.dotComID!, text)
        refreshResultsController(predicate: filterPredicate)
    }
}
