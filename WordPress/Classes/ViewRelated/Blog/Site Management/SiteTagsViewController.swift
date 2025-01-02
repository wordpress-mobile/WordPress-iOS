import UIKit
import SwiftUI
import Gridicons
import WordPressUI
import WordPressShared

final class SiteTagsViewController: UITableViewController {
    private struct TableConstants {
        static let cellIdentifier = "TitleBadgeDisclosureCell"
        static let accesibilityIdentifier = "SiteTagsList"
    }
    private let blog: Blog

    private var isSearching = false

    private lazy var context: NSManagedObjectContext = {
        return ContextManager.sharedInstance().mainContext
    }()

    private lazy var defaultPredicate: NSPredicate = {
        return NSPredicate(format: "blog.blogID = %@", blog.dotComID!)
    }()

    private let sortDescriptors: [NSSortDescriptor] = {
        return [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
    }()

    private lazy var resultsController: NSFetchedResultsController<NSFetchRequestResult> = {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "PostTag")
        request.sortDescriptors = self.sortDescriptors

        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.context, sectionNameKeyPath: nil, cacheName: nil)
        frc.delegate = self
        return frc
    }()

    private lazy var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.hidesNavigationBarDuringPresentation = false
        controller.obscuresBackgroundDuringPresentation = false
        controller.searchResultsUpdater = self
        controller.delegate = self
        return controller
    }()

    private var stateView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let stateView {
                tableView.addSubview(stateView)
                stateView.translatesAutoresizingMaskIntoConstraints = false
                tableView.pinSubviewToSafeArea(stateView)
            }
        }
    }

    private var isPerformingInitialSync = false

    @objc public init(blog: Blog) {
        self.blog = blog
        super.init(style: .plain)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Tags", comment: "Label for the Tags Section in the Blog Settings")
        setupTableView()
        refreshTags()
        refreshResultsController(predicate: defaultPredicate)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        refreshNoResultsView()
    }

    private func setupTableView() {
        tableView.accessibilityIdentifier = TableConstants.accesibilityIdentifier
        tableView.tableFooterView = UIView(frame: .zero)
        let nibName = UINib(nibName: TableConstants.cellIdentifier, bundle: nil)
        tableView.register(nibName, forCellReuseIdentifier: TableConstants.cellIdentifier)
        setupRefreshControl()
    }

    private func setupRefreshControl() {
        if refreshControl == nil {
            refreshControl = UIRefreshControl()
            refreshControl?.backgroundColor = .systemBackground
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
        }, failure: { [weak self] error in
            self?.tagsFailedLoading(error: error)
        })
    }

    private func showRightBarButton(_ show: Bool) {
        if show {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(createTag))
        } else {
            navigationItem.rightBarButtonItem = nil
        }
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
        resultsController.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        resultsController.sections?[section].numberOfObjects ?? 0
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
        resultsController.object(at: indexPath) as? PostTag
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
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
            self?.refreshNoResultsView()
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

            guard let tag else {
                return
            }

            self?.delete(tag)
        }

        tagDetailsView.setUpdate { [weak self] updatedData in
            guard let tag else {
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
        WPAnalytics.trackSettingsChange("site_tags", fieldName: "add_tag")
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
        WPAnalytics.trackSettingsChange("site_tags", fieldName: "edit_tag")
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

        let acceptTitle = SharedStrings.Button.ok
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
        let trashIcon = UIImage(systemName: "trash") ?? UIImage()

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
        stateView = UIHostingView(view: ProgressView())
        navigationItem.searchController = nil
    }

    func showEmptyResultsView() {
        stateView = UIHostingView(view: EmptyStateView(label: {
            Label(NoResultsText.noTagsTitle, image: "wp-illustration-empty-results")
        }, description: {
            Text(NoResultsText.noTagsMessage)
        }, actions: {
            Button(NoResultsText.createButtonTitle) { [weak self] in
                self?.createTag()
            }
            .buttonStyle(.primary)
        }))
        navigationItem.searchController = nil
    }

    func showNoSearchResultsView() {
        stateView = UIHostingView(view: VStack {
            EmptyStateView.search()
                .padding(.top, 50)
            Spacer()
        })
    }

    func hideNoResults() {
        stateView = nil
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        tableView.reloadData()
    }

    struct NoResultsText {
        static let noTagsTitle = NSLocalizedString("You don't have any tags", comment: "Empty state. Tags management (Settings > Writing > Tags)")
        static let noTagsMessage = NSLocalizedString("Tags created here can be quickly added to new posts", comment: "Displayed when the user views tags in blog settings and there are no tags")
        static let createButtonTitle = NSLocalizedString("Create a Tag", comment: "Title of the button in the placeholder for an empty list of blog tags.")
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
