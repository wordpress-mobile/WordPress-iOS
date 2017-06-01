import Foundation
import WordPressComAnalytics
import WordPressComStatsiOS
import WordPressShared
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class PostListViewController: AbstractPostListViewController, UIViewControllerRestoration, InteractivePostViewDelegate {

    static fileprivate let postCardTextCellIdentifier = "PostCardTextCellIdentifier"
    static fileprivate let postCardImageCellIdentifier = "PostCardImageCellIdentifier"
    static fileprivate let postCardRestoreCellIdentifier = "PostCardRestoreCellIdentifier"
    static fileprivate let postCardTextCellNibName = "PostCardTextCell"
    static fileprivate let postCardImageCellNibName = "PostCardImageCell"
    static fileprivate let postCardRestoreCellNibName = "RestorePostTableViewCell"
    static fileprivate let postsViewControllerRestorationKey = "PostsViewControllerRestorationKey"
    static fileprivate let statsStoryboardName = "SiteStats"
    static fileprivate let currentPostListStatusFilterKey = "CurrentPostListStatusFilterKey"

    static fileprivate let statsCacheInterval = TimeInterval(300) // 5 minutes

    static fileprivate let postCardEstimatedRowHeight = CGFloat(300.0)
    static fileprivate let postListHeightForFooterView = CGFloat(34.0)

    @IBOutlet fileprivate weak var authorFilterSegmentedControl: UISegmentedControl!

    @IBOutlet var authorsFilterView: UIView!
    @IBOutlet var searchWrapperView: UIView!
    @IBOutlet var headerStackView: UIStackView!

    // MARK: - GUI

    fileprivate let animatedBox = WPAnimatedBox()

    // MARK: - Convenience constructors

    class func controllerWithBlog(_ blog: Blog) -> PostListViewController {

        let storyBoard = UIStoryboard(name: "Posts", bundle: Bundle.main)
        let controller = storyBoard.instantiateViewController(withIdentifier: "PostListViewController") as! PostListViewController

        controller.blog = blog
        controller.restorationClass = self

        return controller
    }

    // MARK: - UIViewControllerRestoration

    class func viewController(withRestorationIdentifierPath identifierComponents: [Any], coder: NSCoder) -> UIViewController? {

        let context = ContextManager.sharedInstance().mainContext

        guard let blogID = coder.decodeObject(forKey: postsViewControllerRestorationKey) as? String,
            let objectURL = URL(string: blogID),
            let objectID = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: objectURL),
            let restoredBlog = (try? context.existingObject(with: objectID)) as? Blog else {

            return nil
        }

        return self.controllerWithBlog(restoredBlog)
    }

    // MARK: - UIStateRestoring

    override func encodeRestorableState(with coder: NSCoder) {

        let objectString = blog?.objectID.uriRepresentation().absoluteString

        coder.encode(objectString, forKey: type(of: self).postsViewControllerRestorationKey)

        super.encodeRestorableState(with: coder)
    }

    // MARK: - UIViewController

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        precondition(segue.destination is UITableViewController)

        super.refreshNoResultsView = { [weak self] noResultsView in
            self?.handleRefreshNoResultsView(noResultsView)
        }
        super.tableViewController = (segue.destination as! UITableViewController)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Posts", comment: "Tile of the screen showing the list of posts for a blog.")
    }

    // MARK: - Configuration

    override func heightForFooterView() -> CGFloat {
        return type(of: self).postListHeightForFooterView
    }

    override func configureTableView() {

        tableView.accessibilityIdentifier = "PostsTable"
        tableView.isAccessibilityElement = true
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = type(of: self).postCardEstimatedRowHeight
        tableView.rowHeight = UITableViewAutomaticDimension

        let bundle = Bundle.main

        // Register the cells
        let postCardTextCellNib = UINib(nibName: type(of: self).postCardTextCellNibName, bundle: bundle)
        tableView.register(postCardTextCellNib, forCellReuseIdentifier: type(of: self).postCardTextCellIdentifier)

        let postCardImageCellNib = UINib(nibName: type(of: self).postCardImageCellNibName, bundle: bundle)
        tableView.register(postCardImageCellNib, forCellReuseIdentifier: type(of: self).postCardImageCellIdentifier)

        let postCardRestoreCellNib = UINib(nibName: type(of: self).postCardRestoreCellNibName, bundle: bundle)
        tableView.register(postCardRestoreCellNib, forCellReuseIdentifier: type(of: self).postCardRestoreCellIdentifier)
    }

    override func configureSearchController() {
        super.configureSearchController()

        searchWrapperView.addSubview(searchController.searchBar)
        tableView.tableHeaderView = headerStackView

        tableView.scrollIndicatorInsets.top = searchController.searchBar.bounds.height
    }

    fileprivate func noResultsTitles() -> [PostListFilter.Status: String] {
        if isSearching() {
            return noResultsTitlesWhenSearching()
        } else {
            return noResultsTitlesWhenFiltering()
        }
    }

    fileprivate func noResultsTitlesWhenSearching() -> [PostListFilter.Status: String] {
        let draftMessage = String(format: NSLocalizedString("No drafts match your search for %@", comment: "The '%@' is a placeholder for the search term."), currentSearchTerm()!)
        let scheduledMessage = String(format: NSLocalizedString("No scheduled posts match your search for %@", comment: "The '%@' is a placeholder for the search term."), currentSearchTerm()!)
        let trashedMessage = String(format: NSLocalizedString("No trashed posts match your search for %@", comment: "The '%@' is a placeholder for the search term."), currentSearchTerm()!)
        let publishedMessage = String(format: NSLocalizedString("No posts match your search for %@", comment: "The '%@' is a placeholder for the search term."), currentSearchTerm()!)

        return noResultsTitles(draftMessage, scheduled: scheduledMessage, trashed: trashedMessage, published: publishedMessage)
    }

    fileprivate func noResultsTitlesWhenFiltering() -> [PostListFilter.Status: String] {
        let draftMessage = NSLocalizedString("You don't have any drafts.", comment: "Displayed when the user views drafts in the posts list and there are no posts")
        let scheduledMessage = NSLocalizedString("You don't have any scheduled posts.", comment: "Displayed when the user views scheduled posts in the posts list and there are no posts")
        let trashedMessage = NSLocalizedString("You don't have any posts in your trash folder.", comment: "Displayed when the user views trashed in the posts list and there are no posts")
        let publishedMessage = NSLocalizedString("You haven't published any posts yet.", comment: "Displayed when the user views published posts in the posts list and there are no posts")

        return noResultsTitles(draftMessage, scheduled: scheduledMessage, trashed: trashedMessage, published: publishedMessage)
    }

    fileprivate func noResultsTitles(_ draft: String, scheduled: String, trashed: String, published: String) -> [PostListFilter.Status: String] {
        return [.draft: draft,
                .scheduled: scheduled,
                .trashed: trashed,
                .published: published]
    }

    override func configureAuthorFilter() {
        let onlyMe = NSLocalizedString("Only Me", comment: "Label for the post author filter. This fliter shows posts only authored by the current user.")
        let everyone = NSLocalizedString("Everyone", comment: "Label for the post author filter. This filter shows posts for all users on the blog.")

        WPStyleGuide.applyPostAuthorFilterStyle(authorFilterSegmentedControl)

        authorFilterSegmentedControl.setTitle(onlyMe, forSegmentAt: 0)
        authorFilterSegmentedControl.setTitle(everyone, forSegmentAt: 1)

        authorsFilterView?.backgroundColor = WPStyleGuide.lightGrey()

        if !filterSettings.canFilterByAuthor() {
            authorsFilterView.removeFromSuperview()

            headerStackView.frame.size.height = searchController.searchBar.frame.height

            // Required to update the size of the table header view
            tableView.tableHeaderView = headerStackView
        }

        if filterSettings.currentPostAuthorFilter() == .mine {
            authorFilterSegmentedControl.selectedSegmentIndex = 0
        } else {
            authorFilterSegmentedControl.selectedSegmentIndex = 1
        }
    }

    // Mark - Layout Methods

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        // Need to reload the table alongside a traitCollection change.
        // This is mainly because we target Reg W and Any H vs all other size classes.
        // If we transition between the two, the tableView may not update the cell heights accordingly.
        // Brent C. Aug 3/2016
        coordinator.animate(alongsideTransition: { context in
            if self.isViewLoaded {
                self.tableView.reloadData()
            }
            }, completion: nil)
    }

    // MARK: - Sync Methods

    override func postTypeToSync() -> PostServiceType {
        return PostServiceTypePost as PostServiceType
    }

    override func lastSyncDate() -> Date? {
        return blog?.lastPostsSync
    }

    // MARK: - Actions

    @IBAction func handleAuthorFilterChanged(_ sender: AnyObject) {
        var authorFilter = PostListFilterSettings.AuthorFilter.everyone
        if authorFilterSegmentedControl.selectedSegmentIndex == 0 {
            authorFilter = .mine
        }
        filterSettings.setCurrentPostAuthorFilter(authorFilter)
        refreshAndReload()
        syncItemsWithUserInteraction(false)
    }

    // MARK: - Data Model Interaction

    /// Retrieves the post object at the specified index path.
    ///
    /// - Parameter indexPath: the index path of the post object to retrieve.
    ///
    /// - Returns: the requested post.
    ///
    fileprivate func postAtIndexPath(_ indexPath: IndexPath) -> Post {
        guard let post = tableViewHandler.resultsController.object(at: indexPath) as? Post else {
            // Retrieving anything other than a post object means we have an App with an invalid
            // state.  Ignoring this error would be counter productive as we have no idea how this
            // can affect the App.  This controlled interruption is intentional.
            //
            // - Diego Rey Mendez, May 18 2016
            //
            fatalError("Expected a post object.")
        }

        return post
    }

    // MARK: - TableViewHandler

    override func entityName() -> String {
        return String(describing: Post.self)
    }

    override func predicateForFetchRequest() -> NSPredicate {
        var predicates = [NSPredicate]()

        if let blog = blog {
            // Show all original posts without a revision & revision posts.
            let basePredicate = NSPredicate(format: "blog = %@ && revision = nil", blog)
            predicates.append(basePredicate)
        }

        let typePredicate = NSPredicate(format: "postType = %@", postTypeToSync())
        predicates.append(typePredicate)

        let searchText = currentSearchTerm()
        let filterPredicate = filterSettings.currentPostListFilter().predicateForFetchRequest

        // If we have recently trashed posts, create an OR predicate to find posts matching the filter,
        // or posts that were recently deleted.
        if searchText?.characters.count == 0 && recentlyTrashedPostObjectIDs.count > 0 {
            let trashedPredicate = NSPredicate(format: "SELF IN %@", recentlyTrashedPostObjectIDs)

            predicates.append(NSCompoundPredicate(orPredicateWithSubpredicates: [filterPredicate, trashedPredicate]))
        } else {
            predicates.append(filterPredicate)
        }

        if filterSettings.shouldShowOnlyMyPosts() {
            let myAuthorID = blogUserID() ?? 0

            // Brand new local drafts have an authorID of 0.
            let authorPredicate = NSPredicate(format: "authorID = %@ || authorID = 0", myAuthorID)
            predicates.append(authorPredicate)
        }

        if let searchText = searchText, searchText.characters.count > 0 {
            let searchPredicate = NSPredicate(format: "postTitle CONTAINS[cd] %@", searchText)
            predicates.append(searchPredicate)
        }

        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        return predicate
    }

    // MARK: - Table View Handling

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let post = postAtIndexPath(indexPath)

        if post.remoteStatus == .pushing {
            // Don't allow editing while pushing changes
            return
        }

        if post.status == .trash {
            // No editing posts that are trashed.
            return
        }

        editPost(apost: post)
    }

    func tableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell {
        if let windowlessCell = dequeCellForWindowlessLoadingIfNeeded(tableView) {
            return windowlessCell
        }

        let post = postAtIndexPath(indexPath)
        let identifier = cellIdentifierForPost(post)
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)

        configureCell(cell, at: indexPath)

        return cell
    }

    override func configureCell(_ cell: UITableViewCell, at indexPath: IndexPath) {
        cell.accessoryType = .none
        cell.selectionStyle = .none

        let post = postAtIndexPath(indexPath)

        guard let interactivePostView = cell as? InteractivePostView,
            let configurablePostView = cell as? ConfigurablePostView else {

            fatalError("Cell does not implement the required protocols")
        }

        interactivePostView.setInteractionDelegate(self)

        configurablePostView.configure(with: post)
    }

    fileprivate func cellIdentifierForPost(_ post: Post) -> String {
        var identifier: String

        if recentlyTrashedPostObjectIDs.contains(post.objectID) == true && filterSettings.currentPostListFilter().filterType != .trashed {
            identifier = type(of: self).postCardRestoreCellIdentifier
        } else if post.pathForDisplayImage?.characters.count > 0 {
            identifier = type(of: self).postCardImageCellIdentifier
        } else {
            identifier = type(of: self).postCardTextCellIdentifier
        }

        return identifier
    }

    // MARK: - Post Actions

    override func createPost() {
        let editor = EditPostViewController(blog: blog)
        editor.onClose = { [weak self] changesSaved in
            if changesSaved {
                if let postStatus = editor.post?.status {
                    self?.updateFilterWithPostStatus(postStatus)
                }
            }
        }
        editor.modalPresentationStyle = .fullScreen
        present(editor, animated: false, completion: { [weak self] in
            self?.updateFilterWithPostStatus(.draft)
        })
        WPAppAnalytics.track(.editorCreatedPost, withProperties: ["tap_source": "posts_view"], with: blog)
    }

    private func editPost(apost: AbstractPost) {
        guard let post = apost as? Post else {
            return
        }
        let editor = EditPostViewController(post: post)
        editor.onClose = { [weak self] changesSaved in
            if changesSaved {
                if let postStatus = editor.post?.status {
                    self?.updateFilterWithPostStatus(postStatus)
                }
            }
        }
        editor.modalPresentationStyle = .fullScreen
        present(editor, animated: false, completion: nil)
        WPAnalytics.track(.postListEditAction, withProperties: propertiesForAnalytics())
    }

    override func promptThatPostRestoredToFilter(_ filter: PostListFilter) {
        var message = NSLocalizedString("Post Restored to Drafts", comment: "Prompts the user that a restored post was moved to the drafts list.")

        switch filter.filterType {
        case .published:
            message = NSLocalizedString("Post Restored to Published", comment: "Prompts the user that a restored post was moved to the published list.")
            break
        case .scheduled:
            message = NSLocalizedString("Post Restored to Scheduled", comment: "Prompts the user that a restored post was moved to the scheduled list.")
            break
        default:
            break
        }

        let alertCancel = NSLocalizedString("OK", comment: "Title of an OK button. Pressing the button acknowledges and dismisses a prompt.")

        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertController.addCancelActionWithTitle(alertCancel, handler: nil)
        alertController.presentFromRootViewController()
    }

    fileprivate func viewStatsForPost(_ apost: AbstractPost) {
        // Check the blog
        let blog = apost.blog

        guard blog.supports(.stats) else {
            // Needs Jetpack.
            return
        }

        WPAnalytics.track(.postListStatsAction, withProperties: propertiesForAnalytics())

        // Push the Stats Post Details ViewController
        let identifier = NSStringFromClass(StatsPostDetailsTableViewController.self)
        let service = BlogService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        let statsBundle = Bundle(for: WPStatsViewController.self)
        let statsStoryboard = UIStoryboard(name: type(of: self).statsStoryboardName, bundle: statsBundle)
        let viewControllerObject = statsStoryboard.instantiateViewController(withIdentifier: identifier)

        assert(viewControllerObject is StatsPostDetailsTableViewController)
        guard let viewController = viewControllerObject as? StatsPostDetailsTableViewController else {
            DDLogSwift.logError("\(#file): \(#function) [\(#line)] - The stat details view controller is not of the expected class.")
            return
        }

        viewController.postID = apost.postID
        viewController.postTitle = apost.titleForDisplay()
        viewController.statsService = WPStatsService(siteId: blog.dotComID, siteTimeZone: service.timeZone(for: blog), oauth2Token: blog.authToken, andCacheExpirationInterval: type(of: self).statsCacheInterval)

        navigationController?.pushViewController(viewController, animated: true)
    }

    // MARK: - InteractivePostViewDelegate

    func cell(_ cell: UITableViewCell, handleEdit post: AbstractPost) {
        editPost(apost: post)
    }

    func cell(_ cell: UITableViewCell, handleViewPost post: AbstractPost) {
        viewPost(post)
    }

    func cell(_ cell: UITableViewCell, handleStatsFor post: AbstractPost) {
        ReachabilityUtils.onAvailableInternetConnectionDo {
            viewStatsForPost(post)
        }
    }

    func cell(_ cell: UITableViewCell, handlePublishPost post: AbstractPost) {
        ReachabilityUtils.onAvailableInternetConnectionDo {
            publishPost(post)
        }
    }

    func cell(_ cell: UITableViewCell, handleSchedulePost post: AbstractPost) {
        ReachabilityUtils.onAvailableInternetConnectionDo {
            schedulePost(post)
        }
    }

    func cell(_ cell: UITableViewCell, handleTrashPost post: AbstractPost) {
        ReachabilityUtils.onAvailableInternetConnectionDo {
            if (post.status == .trash) {

                let cancelText = NSLocalizedString("Cancel", comment: "Cancels an Action")
                let deleteText = NSLocalizedString("Delete", comment: "Deletes post permanently")
                let messageText = NSLocalizedString("Delete this post permanently?", comment: "Deletes post permanently")
                let alertController = UIAlertController(title: nil, message: messageText, preferredStyle: .alert)

                alertController.addCancelActionWithTitle(cancelText)
                alertController.addDestructiveActionWithTitle(deleteText) { [weak self] action in
                    self?.deletePost(post)
                }
                alertController.presentFromRootViewController()

            } else {
                deletePost(post)
            }
        }
    }

    func cell(_ cell: UITableViewCell, handleRestore post: AbstractPost) {
        ReachabilityUtils.onAvailableInternetConnectionDo {
            restorePost(post)
        }
    }

    // MARK: - Refreshing noResultsView

    fileprivate func handleRefreshNoResultsView(_ noResultsView: WPNoResultsView) {
        noResultsView.titleText = noResultsTitle()
        noResultsView.messageText = noResultsMessage()
        noResultsView.accessoryView = noResultsAccessoryView()
        noResultsView.buttonTitle = noResultsButtonTitle()
    }

    // MARK: - NoResultsView Customizer helpers

    fileprivate func noResultsAccessoryView() -> UIView {
        if syncHelper.isSyncing {
            animatedBox.animate(afterDelay: 0.1)
            return animatedBox
        }

        return UIImageView(image: UIImage(named: "illustration-posts"))
    }

    func noResultsButtonTitle() -> String {
        if syncHelper.isSyncing == true || isSearching() {
            return ""
        }

        let filterType = filterSettings.currentPostListFilter().filterType

        switch filterType {
        case .trashed:
            return ""
        default:
            return NSLocalizedString("Start a Post", comment: "Button title, encourages users to create their first post on their blog.")
        }
    }

    func noResultsTitle() -> String {
        if syncHelper.isSyncing == true {
            return NSLocalizedString("Fetching posts...", comment: "A brief prompt shown when the reader is empty, letting the user know the app is currently fetching new posts.")
        }

        let filter = filterSettings.currentPostListFilter()
        let titles = noResultsTitles()
        let title = titles[filter.filterType]

        return title ?? ""
    }

    func noResultsMessage() -> String {
        if syncHelper.isSyncing == true || isSearching() {
            return ""
        }

        let filterType = filterSettings.currentPostListFilter().filterType

        switch filterType {
        case .draft:
            return NSLocalizedString("Would you like to create one?", comment: "Displayed when the user views drafts in the posts list and there are no posts")
        case .scheduled:
            return NSLocalizedString("Would you like to create one?", comment: "Displayed when the user views scheduled posts in the posts list and there are no posts")
        case .trashed:
            return NSLocalizedString("Everything you write is solid gold.", comment: "Displayed when the user views trashed posts in the posts list and there are no posts")
        default:
            return NSLocalizedString("Would you like to publish your first post?", comment: "Displayed when the user views published posts in the posts list and there are no posts")
        }
    }
}
