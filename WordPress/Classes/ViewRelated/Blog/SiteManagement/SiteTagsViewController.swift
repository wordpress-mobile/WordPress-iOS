import UIKit
import Gridicons

final class SiteTagsViewController: UITableViewController {
    private struct TableConstants {
        static let cellIdentifier = "TitleBadgeDisclosureCell"
        static let accesibilityIdentifier = "SiteTagsList"
        static let numberOfSections = 1
    }
    private let blog: Blog

    private lazy var noResultsViewController = NoResultsViewController.controller()
    private var isSearching = false

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
        returnValue.delegate = self

        WPStyleGuide.configureSearchBar(returnValue.searchBar)
        return returnValue
    }()

    private var isPerformingInitialSync = false

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

        noResultsViewController.delegate = self

        setAccessibilityIdentifier()
        applyStyleGuide()
        applyTitle()
        setupTable()

        refreshTags()
        refreshResultsController(predicate: defaultPredicate)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        searchController.searchBar.isHidden = false
        refreshNoResultsView()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // HACK: Normally, to hide the scroll bars we'd define a presentation context.
        // This is impacting layout when navigating back from a detail. As a work
        // around we can simply hide the search bar.
        if searchController.isActive {
            searchController.searchBar.isHidden = true
        }
    }

    private func setAccessibilityIdentifier() {
        tableView.accessibilityIdentifier = TableConstants.accesibilityIdentifier
    }

    private func applyStyleGuide() {
        WPStyleGuide.configureColors(view: view, tableView: tableView)
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
        if refreshControl == nil {
            refreshControl = UIRefreshControl()
            refreshControl?.backgroundColor = .basicBackground
            refreshControl?.addTarget(self, action: #selector(refreshTags), for: .valueChanged)
        }
    }

    private func deactivateRefreshControl() {
        refreshControl = nil
    }

    @objc private func refreshResultsController(predicate: NSPredicate) {
        resultsController.fetchRequest.predicate = predicate
        resultsController.fetchRequest.sortDescriptors = sortDescriptors
        do {
            try resultsController.performFetch()
            tableView.reloadData()
            refreshNoResultsView()
        } catch {
            tagsFailedLoading(error: error)
        }
    }

    @objc private func refreshTags() {
        isPerformingInitialSync = true
        let tagsService = PostTagService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        tagsService.syncTags(for: blog, success: { [weak self] tags in
            self?.isPerformingInitialSync = false
            self?.refreshControl?.endRefreshing()
            self?.refreshNoResultsView()
        }) { [weak self] error in
            self?.tagsFailedLoading(error: error)
        }
    }

    private func showRightBarButton(_ show: Bool) {
        if show {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                                target: self,
                                                                action: #selector(createTag))
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }

    private func setupSearchBar() {
        guard tableView.tableHeaderView == nil else {
            return
        }
       tableView.tableHeaderView = searchController.searchBar
    }

    private func removeSearchBar() {
        tableView.tableHeaderView = nil
    }

    @objc private func createTag() {
        navigate(to: nil)
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

        cell.name = tag.name?.stringByDecodingXMLCharacters()

        if let count = tag.postCount?.intValue, count > 0 {
            cell.count = count
        }

        return cell
    }

    fileprivate func tagAtIndexPath(_ indexPath: IndexPath) -> PostTag? {
        return resultsController.object(at: indexPath) as? PostTag
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard let selectedTag = tagAtIndexPath(indexPath) else {
            return
        }

        delete(selectedTag)
    }

    private func delete(_ tag: PostTag) {
        let tagsService = PostTagService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        refreshControl?.beginRefreshing()
        tagsService.delete(tag, for: blog, success: { [weak self] in
            self?.refreshControl?.endRefreshing()
            self?.tableView.reloadData()
        }, failure: { [weak self] error in
            self?.refreshControl?.endRefreshing()
        })
    }

    private func save(_ tag: PostTag) {
        let tagsService = PostTagService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        refreshControl?.beginRefreshing()
        tagsService.save(tag, for: blog, success: { [weak self] tag in
            self?.refreshControl?.endRefreshing()
            self?.tableView.reloadData()
        }, failure: { error in
                self.refreshControl?.endRefreshing()
        })
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

// MARK: - Fetched results delegate
extension SiteTagsViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        refreshNoResultsView()
    }
}

// MARK: - Navigation to Tag details
extension SiteTagsViewController {
    fileprivate func navigate(to tag: PostTag?) {
        let titleSectionHeader = NSLocalizedString("Tag", comment: "Section header for tag name in Tag Details View.")
        let subtitleSectionHeader = NSLocalizedString("Description", comment: "Section header for tag name in Tag Details View.")
        let titleErrorFooter = NSLocalizedString("Name Required", comment: "Error to be displayed when a tag is empty")
        let content = SettingsTitleSubtitleController.Content(title: tag?.name,
                                                              subtitle: tag?.tagDescription,
                                                              titleHeader: titleSectionHeader,
                                                              subtitleHeader: subtitleSectionHeader,
                                                              titleErrorFooter: titleErrorFooter)
        let confirmationContent = confirmation()
        let tagDetailsView = SettingsTitleSubtitleController(content: content, confirmation: confirmationContent)

        tagDetailsView.setAction { [weak self] updatedData in
            self?.navigationController?.popViewController(animated: true)

            guard let tag = tag else {
                return
            }

            self?.delete(tag)
        }

        tagDetailsView.setUpdate { [weak self] updatedData in
            guard let tag = tag else {
                self?.addTag(data: updatedData)
                return
            }

            guard self?.tagWasUpdated(tag: tag, updatedTag: updatedData) == true else {
                return
            }

            self?.updateTag(tag, updatedData: updatedData)

        }

        navigationController?.pushViewController(tagDetailsView, animated: true)
    }

    private func addTag(data: SettingsTitleSubtitleController.Content) {
        if let existingTag = existingTagForData(data) {
            displayAlertForExistingTag(existingTag)
            return
        }
        guard let newTag = NSEntityDescription.insertNewObject(forEntityName: "PostTag", into: ContextManager.sharedInstance().mainContext) as? PostTag else {
            return
        }

        newTag.name = data.title
        newTag.tagDescription = data.subtitle

        save(newTag)
    }

    private func updateTag(_ tag: PostTag, updatedData: SettingsTitleSubtitleController.Content) {
        // Lets check that we are not updating a tag to a name that already exists
        if let existingTag = existingTagForData(updatedData),
            existingTag != tag {
            displayAlertForExistingTag(existingTag)
            return
        }

        tag.name = updatedData.title
        tag.tagDescription = updatedData.subtitle

        save(tag)
    }

    private func existingTagForData(_ data: SettingsTitleSubtitleController.Content) -> PostTag? {
        guard let title = data.title else {
            return nil
        }
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "PostTag")
        request.predicate = NSPredicate(format: "blog.blogID = %@ AND name = %@", blog.dotComID!, title)
        request.fetchLimit = 1
        guard let results = (try? context.fetch(request)) as? [PostTag] else {
            return nil
        }
        return results.first
    }

    fileprivate func displayAlertForExistingTag(_ tag: PostTag) {
        let title =  NSLocalizedString("Tag already exists",
                                       comment: "Title of the alert indicating that a tag with that name already exists.")
        let tagName = tag.name ?? ""
        let message = String(format: NSLocalizedString("A tag named '%@' already exists.",
                                                       comment: "Message of the alert indicating that a tag with that name already exists. The placeholder is the name of the tag"),
                             tagName)

        let acceptTitle = NSLocalizedString("OK", comment: "Alert dismissal title")
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addDefaultActionWithTitle(acceptTitle)
        present(alertController, animated: true)
    }

    private func tagWasUpdated(tag: PostTag, updatedTag: SettingsTitleSubtitleController.Content) -> Bool {
        if tag.name == updatedTag.title && tag.tagDescription == updatedTag.subtitle {
            return false
        }

        return true
    }

    private func confirmation() -> SettingsTitleSubtitleController.Confirmation {
        let confirmationTitle = NSLocalizedString("Delete this tag", comment: "Delete Tag confirmation action title")
        let confirmationSubtitle = NSLocalizedString("Are you sure you want to delete this tag?", comment: "Message asking for confirmation on tag deletion")
        let actionTitle = NSLocalizedString("Delete", comment: "Delete")
        let cancelTitle = NSLocalizedString("Cancel", comment: "Alert dismissal title")
        let trashIcon = Gridicon.iconOfType(.trash)

        return SettingsTitleSubtitleController.Confirmation(title: confirmationTitle,
                                                            subtitle: confirmationSubtitle,
                                                            actionTitle: actionTitle,
                                                            cancelTitle: cancelTitle,
                                                            icon: trashIcon,
                                                            isDestructiveAction: true)
    }
}

// MARK: - Empty state handling

private extension SiteTagsViewController {

    func refreshNoResultsView() {
        let noResults = resultsController.fetchedObjects?.count == 0
        showRightBarButton(!noResults)

        if noResults {
            showNoResults()
        } else {
            hideNoResults()
        }
    }

    func showNoResults() {

        if isSearching {
            showNoSearchResultsView()
            return
        }

        if isPerformingInitialSync {
            showLoadingView()
            return
        }

        showEmptyResultsView()
    }

    func showLoadingView() {
        configureAndDisplayNoResults(title: NoResultsText.loadingTitle, accessoryView: NoResultsViewController.loadingAccessoryView())
        removeSearchBar()
    }

    func showEmptyResultsView() {
        configureAndDisplayNoResults(title: NoResultsText.noTagsTitle, subtitle: NoResultsText.noTagsMessage, buttonTitle: NoResultsText.createButtonTitle)
        removeSearchBar()
    }

    func showNoSearchResultsView() {

        // If already shown, don't show again. To prevent the view from "flashing" as the user types.
        guard !noResultsShown else {
            return
        }

        configureAndDisplayNoResults(title: NoResultsText.noResultsTitle, forNoSearchResults: true)
    }

    func configureAndDisplayNoResults(title: String,
                                      subtitle: String? = nil,
                                      buttonTitle: String? = nil,
                                      accessoryView: UIView? = nil,
                                      forNoSearchResults: Bool = false) {

        if forNoSearchResults {
            noResultsViewController.configureForNoSearchResults(title: title)
        } else {
            noResultsViewController.configure(title: title, buttonTitle: buttonTitle, subtitle: subtitle, accessoryView: accessoryView)
        }

        displayNoResults()
    }

    func displayNoResults() {
        addChild(noResultsViewController)
        noResultsViewController.view.frame = tableView.frame

        // Since the tableView doesn't always start at the top, adjust the NRV accordingly.
        if isSearching {
            noResultsViewController.view.frame.origin.y = searchController.searchBar.frame.height
        } else {
            noResultsViewController.view.frame.origin.y = 0
        }

        tableView.addSubview(withFadeAnimation: noResultsViewController.view)
        noResultsViewController.didMove(toParent: self)
    }

    func hideNoResults() {
        noResultsViewController.removeFromView()
        setupSearchBar()
        tableView.reloadData()
    }

    var noResultsShown: Bool {
        return noResultsViewController.parent != nil
    }

    struct NoResultsText {
        static let noTagsTitle = NSLocalizedString("You don't have any tags", comment: "Empty state. Tags management (Settings > Writing > Tags)")
        static let noTagsMessage = NSLocalizedString("Tags created here can be quickly added to new posts", comment: "Displayed when the user views tags in blog settings and there are no tags")
        static let createButtonTitle = NSLocalizedString("Create a Tag", comment: "Title of the button in the placeholder for an empty list of blog tags.")
        static let loadingTitle = NSLocalizedString("Loading...", comment: "Loading tags.")
        static let noResultsTitle = NSLocalizedString("No tags matching your search", comment: "Displayed when the user is searching site tags and there are no matches.")
    }

}

// MARK: - NoResultsViewControllerDelegate

extension SiteTagsViewController: NoResultsViewControllerDelegate {
    func actionButtonPressed() {
        createTag()
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

// MARK: - UISearchControllerDelegate Conformance
extension SiteTagsViewController: UISearchControllerDelegate {
    func willPresentSearchController(_ searchController: UISearchController) {
        isSearching = true
        deactivateRefreshControl()
    }

    func willDismissSearchController(_ searchController: UISearchController) {
        isSearching = false
        setupRefreshControl()
    }
}
