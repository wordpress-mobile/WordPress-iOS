import Foundation
import CocoaLumberjack
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

    @IBOutlet var searchWrapperView: UIView!
    @IBOutlet weak var filterTabBarTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var filterTabBariOS10TopConstraint: NSLayoutConstraint!
    @IBOutlet weak var filterTabBarBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableViewTopConstraint: NSLayoutConstraint!

    // MARK: - Convenience constructors

    @objc class func controllerWithBlog(_ blog: Blog) -> PostListViewController {

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

        super.refreshNoResultsViewController = { [weak self] noResultsViewController in
            self?.handleRefreshNoResultsViewController(noResultsViewController)
        }

        super.tableViewController = (segue.destination as! UITableViewController)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Blog Posts", comment: "Title of the screen showing the list of posts for a blog.")

        configureFilterBarTopConstraint()
    }

    // MARK: - Configuration

    override func heightForFooterView() -> CGFloat {
        return type(of: self).postListHeightForFooterView
    }

    private func configureFilterBarTopConstraint() {
        // Not an ideal solution, but fixes an issue where the filter bar
        // wasn't showing up on iOS 10: https://github.com/wordpress-mobile/WordPress-iOS/issues/8937
        if #available(iOS 11.0, *) {
            filterTabBariOS10TopConstraint.isActive = false
        } else {
            extendedLayoutIncludesOpaqueBars = false
            edgesForExtendedLayout = []

            filterTabBarTopConstraint.isActive = false

            view.layoutIfNeeded()
        }
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

    override func configureAuthorFilter() {
        guard filterSettings.canFilterByAuthor() else {
            return
        }

        let authorFilter = AuthorFilterButton()
        authorFilter.addTarget(self, action: #selector(showAuthorSelectionPopover(_:)), for: .touchUpInside)
        filterTabBar.accessoryView = authorFilter

        updateAuthorFilter()
    }

    override func configureSearchController() {
        super.configureSearchController()

        searchWrapperView.addSubview(searchController.searchBar)

        tableView.scrollIndicatorInsets.top = searchController.searchBar.bounds.height

        updateTableHeaderSize()
    }

    fileprivate func updateTableHeaderSize() {
        if searchController.isActive {
            // Account for the search bar being moved to the top of the screen.
            if #available(iOS 11.0, *) {
                searchWrapperView.frame.size.height = (searchController.searchBar.bounds.height + searchController.searchBar.frame.origin.y) - topLayoutGuide.length
            } else {
                searchWrapperView.frame.size.height = (searchController.searchBar.bounds.height + searchController.searchBar.frame.origin.y)
            }
        } else {
            searchWrapperView.frame.size.height = searchController.searchBar.bounds.height
        }

        // Resetting the tableHeaderView is necessary to get the new height to take effect
        tableView.tableHeaderView = searchWrapperView
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
        return .post
    }

    override func lastSyncDate() -> Date? {
        return blog?.lastPostsSync
    }

    // MARK: - Actions

    @objc
    private func showAuthorSelectionPopover(_ sender: UIView) {
        let filterController = AuthorFilterViewController(initialSelection: filterSettings.currentPostAuthorFilter(),
                                                          gravatarEmail: blog.account?.email) { [weak self] filter in
                                                            if filter != self?.filterSettings.currentPostAuthorFilter() {
                                                                UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, sender)
                                                            }

                                                            self?.filterSettings.setCurrentPostAuthorFilter(filter)
                                                            self?.updateAuthorFilter()
                                                            self?.refreshAndReload()
                                                            self?.syncItemsWithUserInteraction(false)
                                                            self?.dismiss(animated: true, completion: nil)
        }

        ForcePopoverPresenter.configurePresentationControllerForViewController(filterController, presentingFromView: sender)
        filterController.popoverPresentationController?.permittedArrowDirections = .up

        present(filterController, animated: true)
    }

    private func updateAuthorFilter() {
        guard let accessoryView = filterTabBar.accessoryView as? AuthorFilterButton else {
            return
        }

        if filterSettings.currentPostAuthorFilter() == .everyone {
            accessoryView.filterType = .everyone
        } else {
            accessoryView.filterType = .user(gravatarEmail: blog.account?.email)
        }
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

        let typePredicate = NSPredicate(format: "postType = %@", postTypeToSync().rawValue)
        predicates.append(typePredicate)

        let searchText = currentSearchTerm()
        let filterPredicate = filterSettings.currentPostListFilter().predicateForFetchRequest

        // If we have recently trashed posts, create an OR predicate to find posts matching the filter,
        // or posts that were recently deleted.
        if searchText?.count == 0 && recentlyTrashedPostObjectIDs.count > 0 {
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

        if let searchText = searchText, searchText.count > 0 {
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

        if post.status == .trash {
            // No editing posts that are trashed.
            return
        }

        editPost(apost: post)
    }

    @objc func tableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell {
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
        } else if post.featuredImageURLForDisplay() != nil {
            identifier = type(of: self).postCardImageCellIdentifier
        } else {
            identifier = type(of: self).postCardTextCellIdentifier
        }

        return identifier
    }

    // MARK: - Post Actions

    override func createPost() {
        let filterIndex = filterSettings.currentFilterIndex()
        let editor = EditPostViewController(blog: blog)
        editor.onClose = { [weak self] changesSaved in
            if changesSaved {
                if let postStatus = editor.post?.status {
                    self?.updateFilterWithPostStatus(postStatus)
                }
            } else {
                self?.updateFilter(index: filterIndex)
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
        guard !PostCoordinator.shared.isUploading(post: post) else {
            presentAlertForPostBeingUploaded()
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
        WPAppAnalytics.track(.postListEditAction, withProperties: propertiesForAnalytics(), with: apost)
    }

    func presentAlertForPostBeingUploaded() {
        let message = NSLocalizedString("This post is currently uploading. It won't take long – try again soon and you'll be able to edit it.", comment: "Prompts the user that the post is being uploaded and cannot be edited while that process is ongoing.")

        let alertCancel = NSLocalizedString("OK", comment: "Title of an OK button. Pressing the button acknowledges and dismisses a prompt.")

        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertController.addCancelActionWithTitle(alertCancel, handler: nil)
        alertController.presentFromRootViewController()
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
            DDLogError("\(#file): \(#function) [\(#line)] - The stat details view controller is not of the expected class.")
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
            let cancelText: String
            let deleteText: String
            let messageText: String
            let titleText: String

            if post.status == .trash {
                cancelText = NSLocalizedString("Cancel", comment: "Cancels an Action")
                deleteText = NSLocalizedString("Delete Permanently", comment: "Delete option in the confirmation alert when deleting a post from the trash.")
                titleText = NSLocalizedString("Delete Permanently?", comment: "Title of the confirmation alert when deleting a post from the trash.")
                messageText = NSLocalizedString("Are you sure you want to permanently delete this post?", comment: "Message of the confirmation alert when deleting a post from the trash.")
            } else {
                cancelText = NSLocalizedString("Cancel", comment: "Cancels an Action")
                deleteText = NSLocalizedString("Move to Trash", comment: "Trash option in the trash confirmation alert.")
                titleText = NSLocalizedString("Trash this post?", comment: "Title of the trash confirmation alert.")
                messageText = NSLocalizedString("Are you sure you want to trash this post?", comment: "Message of the trash confirmation alert.")
            }

            let alertController = UIAlertController(title: titleText, message: messageText, preferredStyle: .alert)

            alertController.addCancelActionWithTitle(cancelText)
            alertController.addDestructiveActionWithTitle(deleteText) { [weak self] action in
                self?.deletePost(post)
            }
            alertController.presentFromRootViewController()
        }
    }

    func cell(_ cell: UITableViewCell, handleRestore post: AbstractPost) {
        ReachabilityUtils.onAvailableInternetConnectionDo {
            restorePost(post)
        }
    }

    // MARK: - UISearchControllerDelegate

    override func willPresentSearchController(_ searchController: UISearchController) {
        super.willPresentSearchController(searchController)

        self.filterTabBar.alpha = WPAlphaZero
        filterTabBarBottomConstraint.isActive = false
        tableViewTopConstraint.isActive = true
    }

    func didPresentSearchController(_ searchController: UISearchController) {
        if #available(iOS 11.0, *) {
            updateTableHeaderSize()

            tableView.scrollIndicatorInsets.top = searchWrapperView.bounds.height
            tableView.contentInset.top = 0
        }
    }

    func didDismissSearchController(_ searchController: UISearchController) {
        updateTableHeaderSize()

        tableViewTopConstraint.isActive = false
        filterTabBarBottomConstraint.isActive = true

        UIView.animate(withDuration: Animations.searchDismissDuration) {
            self.filterTabBar.alpha = WPAlphaFull
        }
    }

    enum Animations {
        static let searchDismissDuration: TimeInterval = 0.3
    }
}

// MARK: - No Results Handling

private extension PostListViewController {

    func handleRefreshNoResultsViewController(_ noResultsViewController: NoResultsViewController) {

        guard connectionAvailable() else {
            noResultsViewController.configure(title: noConnectionMessage(),
                                              image: noResultsImageName)
            return
        }

        let accessoryView = syncHelper.isSyncing ? NoResultsViewController.loadingAccessoryView() : nil

        noResultsViewController.configure(title: noResultsTitle(),
                                          buttonTitle: noResultsButtonTitle(),
                                          image: noResultsImageName,
                                          accessoryView: accessoryView)
    }

    var noResultsImageName: String {
        return "posts-no-results"
    }

    func noResultsButtonTitle() -> String? {
        if syncHelper.isSyncing == true || isSearching() {
            return nil
        }

        let filterType = filterSettings.currentPostListFilter().filterType
        return filterType == .trashed ? nil : NoResultsText.buttonTitle
    }

    func noResultsTitle() -> String {
        if syncHelper.isSyncing == true {
            return NoResultsText.fetchingTitle
        }

        if isSearching() {
            return NoResultsText.noMatchesTitle
        }

        return noResultsFilteredTitle()
    }

    func noResultsFilteredTitle() -> String {
        let filterType = filterSettings.currentPostListFilter().filterType
        switch filterType {
        case .draft:
            return NoResultsText.noDraftsTitle
        case .scheduled:
            return NoResultsText.noScheduledTitle
        case .trashed:
            return NoResultsText.noTrashedTitle
        case .published:
            return NoResultsText.noPublishedTitle
        }
    }

    struct NoResultsText {
        static let buttonTitle = NSLocalizedString("Create a Post", comment: "Button title, encourages users to create their first post on their blog.")
        static let fetchingTitle = NSLocalizedString("Fetching posts...", comment: "A brief prompt shown when the reader is empty, letting the user know the app is currently fetching new posts.")
        static let noMatchesTitle = NSLocalizedString("No posts matching your search", comment: "Displayed when the user is searching the posts list and there are no matching posts")
        static let noDraftsTitle = NSLocalizedString("You don't have any draft posts", comment: "Displayed when the user views drafts in the posts list and there are no posts")
        static let noScheduledTitle = NSLocalizedString("You don't have any scheduled posts", comment: "Displayed when the user views scheduled posts in the posts list and there are no posts")
        static let noTrashedTitle = NSLocalizedString("You don't have any trashed posts", comment: "Displayed when the user views trashed in the posts list and there are no posts")
        static let noPublishedTitle = NSLocalizedString("You haven't published any posts yet", comment: "Displayed when the user views published posts in the posts list and there are no posts")
    }

}
