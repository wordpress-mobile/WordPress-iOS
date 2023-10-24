import Foundation
import CocoaLumberjack
import WordPressShared
import Gridicons
import UIKit

class PostListViewController: AbstractPostListViewController, UIViewControllerRestoration, InteractivePostViewDelegate {

    private let postCardRestoreCellIdentifier = "PostCardRestoreCellIdentifier"
    private let postCardRestoreCellNibName = "RestorePostTableViewCell"
    private let statsStoryboardName = "SiteStats"
    private let currentPostListStatusFilterKey = "CurrentPostListStatusFilterKey"

    static private let postsViewControllerRestorationKey = "PostsViewControllerRestorationKey"

    private let statsCacheInterval = TimeInterval(300) // 5 minutes

    private let postCardEstimatedRowHeight = CGFloat(300.0)
    private let postListHeightForFooterView = CGFloat(50.0)

    private lazy var _tableViewHandler: PostListTableViewHandler = {
        let tableViewHandler = PostListTableViewHandler(tableView: tableView)
        tableViewHandler.cacheRowHeights = false
        tableViewHandler.delegate = self
        tableViewHandler.updateRowAnimation = .none
        return tableViewHandler
    }()

    override var tableViewHandler: WPTableViewHandler {
        get {
            return _tableViewHandler
        } set {
            super.tableViewHandler = newValue
        }
    }

    private var showingJustMyPosts: Bool {
        return filterSettings.currentPostAuthorFilter() == .mine
    }

    /// If set, when the post list appear it will show the tab for this status
    var initialFilterWithPostStatus: BasePost.Status?

    // MARK: - Convenience constructors

    @objc class func controllerWithBlog(_ blog: Blog) -> PostListViewController {
        let vc = PostListViewController()
        vc.blog = blog
        vc.restorationClass = self
        return vc
    }

    static func showForBlog(_ blog: Blog, from sourceController: UIViewController, withPostStatus postStatus: BasePost.Status? = nil) {
        let controller = PostListViewController.controllerWithBlog(blog)
        controller.navigationItem.largeTitleDisplayMode = .never
        controller.initialFilterWithPostStatus = postStatus
        sourceController.navigationController?.pushViewController(controller, animated: true)

        QuickStartTourGuide.shared.visited(.blogDetailNavigation)
    }

    // MARK: - UIViewControllerRestoration

    class func viewController(withRestorationIdentifierPath identifierComponents: [String],
                              coder: NSCoder) -> UIViewController? {

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

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Posts", comment: "Title of the screen showing the list of posts for a blog.")

        configureInitialFilterIfNeeded()
        listenForAppComingToForeground()

        createButtonCoordinator.add(to: view, trailingAnchor: view.safeAreaLayoutGuide.trailingAnchor, bottomAnchor: view.safeAreaLayoutGuide.bottomAnchor)

        refreshNoResultsViewController = { [weak self] in
            self?.handleRefreshNoResultsViewController($0)
        }
    }

    private lazy var createButtonCoordinator: CreateButtonCoordinator = {
        var actions: [ActionSheetItem] = [
            PostAction(handler: { [weak self] in
                    self?.dismiss(animated: false, completion: nil)
                    self?.createPost()
            }, source: Constants.source)
        ]
        return CreateButtonCoordinator(self, actions: actions, source: Constants.source, blog: blog)
    }()

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if traitCollection.horizontalSizeClass == .compact {
            createButtonCoordinator.showCreateButton(for: blog)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        toggleCreateButton()
    }

    /// Shows/hides the create button based on the trait collection horizontal size class
    @objc
    private func toggleCreateButton() {
        if traitCollection.horizontalSizeClass == .compact {
            createButtonCoordinator.showCreateButton(for: blog)
        } else {
            createButtonCoordinator.hideCreateButton()
        }
    }

    // MARK: - Configuration

    override func heightForFooterView() -> CGFloat {
        return postListHeightForFooterView
    }

    override func configureTableView() {
        tableView.accessibilityIdentifier = "PostsTable"
        tableView.separatorStyle = .singleLine
        tableView.rowHeight = UITableView.automaticDimension

        let bundle = Bundle.main

        // Register the cells
        tableView.register(PostListCell.self, forCellReuseIdentifier: PostListCell.defaultReuseID)

        let postCardRestoreCellNib = UINib(nibName: postCardRestoreCellNibName, bundle: bundle)
        tableView.register(postCardRestoreCellNib, forCellReuseIdentifier: postCardRestoreCellIdentifier)

        let headerNib = UINib(nibName: ActivityListSectionHeaderView.identifier, bundle: nil)
        tableView.register(headerNib, forHeaderFooterViewReuseIdentifier: ActivityListSectionHeaderView.identifier)
    }

    private func configureInitialFilterIfNeeded() {
        guard let initialFilterWithPostStatus = initialFilterWithPostStatus else {
            return
        }

        filterSettings.setFilterWithPostStatus(initialFilterWithPostStatus)
    }

    /// Listens for the app coming to foreground in order to properly set the create button
    private func listenForAppComingToForeground() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(toggleCreateButton),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
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
            })
    }

    // MARK: - Sync Methods

    override func postTypeToSync() -> PostServiceType {
        return .post
    }

    override func lastSyncDate() -> Date? {
        return blog?.lastPostsSync
    }

    // MARK: - Data Model Interaction

    /// Retrieves the post object at the specified index path.
    ///
    /// - Parameter indexPath: the index path of the post object to retrieve.
    ///
    /// - Returns: the requested post.
    ///
    fileprivate func postAtIndexPath(_ indexPath: IndexPath) -> Post {
        guard let post = tableViewHandler.resultsController?.object(at: indexPath) as? Post else {
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

        let filterPredicate = filterSettings.currentPostListFilter().predicateForFetchRequest

        // If we have recently trashed posts, create an OR predicate to find posts matching the filter,
        // or posts that were recently deleted.
        if recentlyTrashedPostObjectIDs.count > 0 {
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

        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        return predicate
    }

    // MARK: - Table View Handling

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let post = postAtIndexPath(indexPath)

        guard post.status != .trash else {
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

        let post = postAtIndexPath(indexPath)

//        TODO: Remove later
//        guard let interactivePostView = cell as? InteractivePostView,
//            let configurablePostView = cell as? ConfigurablePostView else {
//                fatalError("Cell does not implement the required protocols")
//        }
//
//        interactivePostView.setInteractionDelegate(self)
//        interactivePostView.setActionSheetDelegate(self)
//
//        configurablePostView.configure(with: post)

        // TODO: Hide author if only showing my posts?
        guard let cell = cell as? PostListCell else {
            return
        }
        cell.configure(with: PostListItemViewModel(post: post), delegate: self)
    }

    fileprivate func cellIdentifierForPost(_ post: Post) -> String {
        var identifier: String

        if recentlyTrashedPostObjectIDs.contains(post.objectID) == true && filterSettings.currentPostListFilter().filterType != .trashed {
            identifier = postCardRestoreCellIdentifier
        } else {
            identifier = PostListCell.defaultReuseID
        }

        return identifier
    }

    // MARK: - Post Actions

    override func createPost() {
        let editor = EditPostViewController(blog: blog)
        editor.modalPresentationStyle = .fullScreen
        editor.entryPoint = .postsList
        present(editor, animated: false, completion: nil)
        WPAppAnalytics.track(.editorCreatedPost, withProperties: [WPAppAnalyticsKeyTapSource: "posts_view", WPAppAnalyticsKeyPostType: "post"], with: blog)
    }

    private func editPost(apost: AbstractPost) {
        guard let post = apost as? Post else {
            return
        }

        WPAppAnalytics.track(.postListEditAction, withProperties: propertiesForAnalytics(), with: post)
        PostListEditorPresenter.handle(post: post, in: self, entryPoint: .postsList)
    }

    private func editDuplicatePost(apost: AbstractPost) {
        guard let post = apost as? Post else {
            return
        }

        PostListEditorPresenter.handleCopy(post: post, in: self)
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

        // Push the Post Stats ViewController
        guard let postID = apost.postID as? Int else {
            return
        }

        SiteStatsInformation.sharedInstance.siteTimeZone = blog.timeZone
        SiteStatsInformation.sharedInstance.oauth2Token = blog.authToken
        SiteStatsInformation.sharedInstance.siteID = blog.dotComID

        let postURL = URL(string: apost.permaLink! as String)
        let postStatsTableViewController = PostStatsTableViewController.withJPBannerForBlog(postID: postID,
                                                                                            postTitle: apost.titleForDisplay(),
                                                                                            postURL: postURL)
        navigationController?.pushViewController(postStatsTableViewController, animated: true)
    }

    // MARK: - InteractivePostViewDelegate

    func edit(_ post: AbstractPost) {
        editPost(apost: post)
    }

    func view(_ post: AbstractPost) {
        viewPost(post)
    }

    func stats(for post: AbstractPost) {
        ReachabilityUtils.onAvailableInternetConnectionDo {
            viewStatsForPost(post)
        }
    }

    func duplicate(_ post: AbstractPost) {
        editDuplicatePost(apost: post)
    }

    func publish(_ post: AbstractPost) {
        publishPost(post) {

            BloggingRemindersFlow.present(from: self,
                                          for: post.blog,
                                          source: .publishFlow,
                                          alwaysShow: false)
        }
    }

    func copyLink(_ post: AbstractPost) {
        copyPostLink(post)
    }

    func trash(_ post: AbstractPost) {
        guard ReachabilityUtils.isInternetReachable() else {
            let offlineMessage = NSLocalizedString("Unable to trash posts while offline. Please try again later.", comment: "Message that appears when a user tries to trash a post while their device is offline.")
            ReachabilityUtils.showNoInternetConnectionNotice(message: offlineMessage)
            return
        }

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

    func restore(_ post: AbstractPost) {
        ReachabilityUtils.onAvailableInternetConnectionDo {
            restorePost(post)
        }
    }

    func draft(_ post: AbstractPost) {
        ReachabilityUtils.onAvailableInternetConnectionDo {
            moveToDraft(post)
        }
    }

    func retry(_ post: AbstractPost) {
        PostCoordinator.shared.save(post)
    }

    func cancelAutoUpload(_ post: AbstractPost) {
        PostCoordinator.shared.cancelAutoUploadOf(post)
    }

    func share(_ apost: AbstractPost, fromView view: UIView) {
        guard let post = apost as? Post else {
            return
        }

        WPAnalytics.track(.postListShareAction, properties: propertiesForAnalytics())

        let shareController = PostSharingController()
        shareController.sharePost(post, fromView: view, inViewController: self)
    }

    func blaze(_ post: AbstractPost) {
        BlazeEventsTracker.trackEntryPointTapped(for: .postsList)
        BlazeFlowCoordinator.presentBlaze(in: self, source: .postsList, blog: blog, post: post)
    }

    // MARK: - NetworkAwareUI

    override func noConnectionMessage() -> String {
        return NSLocalizedString("No internet connection. Some posts may be unavailable while offline.",
                                 comment: "Error message shown when the user is browsing Site Posts without an internet connection.")
    }

    private enum Constants {
        static let exhibitionModeKey = "showCompactPosts"
        static let card = "card"
        static let compact = "compact"
        static let source = "post_list"
    }
}

// MARK: - No Results Handling

private extension PostListViewController {

    func handleRefreshNoResultsViewController(_ noResultsViewController: NoResultsViewController) {

        guard connectionAvailable() else {
            noResultsViewController.configure(title: "", noConnectionTitle: NoResultsText.noConnectionTitle, buttonTitle: NoResultsText.buttonTitle, subtitle: nil, noConnectionSubtitle: NoResultsText.noConnectionSubtitle, attributedSubtitle: nil, attributedSubtitleConfiguration: nil, image: nil, subtitleImage: nil, accessoryView: nil)
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
        if syncHelper.isSyncing == true {
            return nil
        }

        let filterType = filterSettings.currentPostListFilter().filterType
        return filterType == .trashed ? nil : NoResultsText.buttonTitle
    }

    func noResultsTitle() -> String {
        if syncHelper.isSyncing == true {
            return NoResultsText.fetchingTitle
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
        case .allNonTrashed:
            return ""
        }
    }

    struct NoResultsText {
        static let buttonTitle = NSLocalizedString("Create Post", comment: "Button title, encourages users to create post on their blog.")
        static let fetchingTitle = NSLocalizedString("Fetching posts...", comment: "A brief prompt shown when the reader is empty, letting the user know the app is currently fetching new posts.")
        static let noDraftsTitle = NSLocalizedString("You don't have any draft posts", comment: "Displayed when the user views drafts in the posts list and there are no posts")
        static let noScheduledTitle = NSLocalizedString("You don't have any scheduled posts", comment: "Displayed when the user views scheduled posts in the posts list and there are no posts")
        static let noTrashedTitle = NSLocalizedString("You don't have any trashed posts", comment: "Displayed when the user views trashed in the posts list and there are no posts")
        static let noPublishedTitle = NSLocalizedString("You haven't published any posts yet", comment: "Displayed when the user views published posts in the posts list and there are no posts")
        static let noConnectionTitle: String = NSLocalizedString("Unable to load posts right now.", comment: "Title for No results full page screen displayedfrom post list when there is no connection")
        static let noConnectionSubtitle: String = NSLocalizedString("Check your network connection and try again. Or draft a post.", comment: "Subtitle for No results full page screen displayed from post list when there is no connection")
    }
}
