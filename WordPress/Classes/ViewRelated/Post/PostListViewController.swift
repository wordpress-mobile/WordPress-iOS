import Foundation
import CocoaLumberjack
import WordPressShared
import Gridicons
import UIKit

final class PostListViewController: AbstractPostListViewController, UIViewControllerRestoration, InteractivePostViewDelegate {
    static private let postsViewControllerRestorationKey = "PostsViewControllerRestorationKey"

    /// If set, when the post list appear it will show the tab for this status
    private var initialFilterWithPostStatus: BasePost.Status?

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

    class func viewController(withRestorationIdentifierPath identifierComponents: [String], coder: NSCoder) -> UIViewController? {
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

        NotificationCenter.default.addObserver(self, selector: #selector(postCoordinatorDidUpdate), name: .postCoordinatorDidUpdate, object: nil)
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
    @objc private func toggleCreateButton() {
        if traitCollection.horizontalSizeClass == .compact {
            createButtonCoordinator.showCreateButton(for: blog)
        } else {
            createButtonCoordinator.hideCreateButton()
        }
    }

    // MARK: - Notifications

    @objc private func postCoordinatorDidUpdate(_ notification: Foundation.Notification) {
        guard let updatedObjects = (notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject>) else {
            return
        }
        let updatedIndexPaths = (tableView.indexPathsForVisibleRows ?? []).filter {
            let post = fetchResultsController.object(at: $0)
            return updatedObjects.contains(post)
        }
        if !updatedIndexPaths.isEmpty {
            tableView.beginUpdates()
            tableView.reloadRows(at: updatedIndexPaths, with: .automatic)
            tableView.endUpdates()
        }
    }

    // MARK: - Configuration

    override func configureTableView() {
        super.configureTableView()

        tableView.accessibilityIdentifier = "PostsTable"
        tableView.register(PostListCell.self, forCellReuseIdentifier: PostListCell.defaultReuseID)
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

    // MARK: - Sync Methods

    override func postTypeToSync() -> PostServiceType {
        return .post
    }

    // MARK: - Data Model Interaction

    private func postAtIndexPath(_ indexPath: IndexPath) -> Post {
        guard let post = fetchResultsController.object(at: indexPath) as? Post else {
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
        predicates.append(filterPredicate)

        if filterSettings.shouldShowOnlyMyPosts() {
            let myAuthorID = blogUserID() ?? 0

            // Brand new local drafts have an authorID of 0.
            let authorPredicate = NSPredicate(format: "authorID = %@ || authorID = 0", myAuthorID)
            predicates.append(authorPredicate)
        }

        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        return predicate
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PostListCell.defaultReuseID, for: indexPath) as! PostListCell
        let post = postAtIndexPath(indexPath)
        cell.accessoryType = .none
        cell.configure(with: PostListItemViewModel(post: post, shouldHideAuthor: shouldHideAuthor), delegate: self)
        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let post = postAtIndexPath(indexPath)

        guard post.status != .trash else {
            // No editing posts that are trashed.
            return
        }

        editPost(post)
    }

    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            guard let self else { return nil }
            let post = self.postAtIndexPath(indexPath)
            let cell = self.tableView.cellForRow(at: indexPath)
            return AbstractPostMenuHelper(post).makeMenu(presentingView: cell ?? UIView(), delegate: self)
        }
    }

    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let actions = AbstractPostHelper.makeLeadingContextualActions(for: postAtIndexPath(indexPath), delegate: self)
        return UISwipeActionsConfiguration(actions: actions)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let actions = AbstractPostHelper.makeTrailingContextualActions(for: postAtIndexPath(indexPath), delegate: self)
        return UISwipeActionsConfiguration(actions: actions)
    }

    // MARK: - Post Actions

    override func createPost() {
        let editor = EditPostViewController(blog: blog)
        editor.modalPresentationStyle = .fullScreen
        editor.entryPoint = .postsList
        present(editor, animated: false, completion: nil)
        WPAppAnalytics.track(.editorCreatedPost, withProperties: [WPAppAnalyticsKeyTapSource: "posts_view", WPAppAnalyticsKeyPostType: "post"], with: blog)
    }

    private func editPost(_ post: AbstractPost) {
        guard let post = post as? Post else {
            return
        }
        WPAppAnalytics.track(.postListEditAction, withProperties: propertiesForAnalytics(), with: post)
        PostListEditorPresenter.handle(post: post, in: self, entryPoint: .postsList)
    }

    private func editDuplicatePost(_ post: AbstractPost) {
        guard let post = post as? Post else {
            return
        }
        PostListEditorPresenter.handleCopy(post: post, in: self)
    }

    fileprivate func viewStatsForPost(_ post: AbstractPost) {
        // Check the blog
        let blog = post.blog

        guard blog.supports(.stats) else {
            // Needs Jetpack.
            return
        }

        WPAnalytics.track(.postListStatsAction, withProperties: propertiesForAnalytics())

        // Push the Post Stats ViewController
        guard let postID = post.postID as? Int else {
            return
        }

        SiteStatsInformation.sharedInstance.siteTimeZone = blog.timeZone
        SiteStatsInformation.sharedInstance.oauth2Token = blog.authToken
        SiteStatsInformation.sharedInstance.siteID = blog.dotComID

        let postURL = URL(string: post.permaLink! as String)
        let postStatsTableViewController = PostStatsTableViewController.withJPBannerForBlog(postID: postID,
                                                                                            postTitle: post.titleForDisplay(),
                                                                                            postURL: postURL)
        navigationController?.pushViewController(postStatsTableViewController, animated: true)
    }

    // MARK: - InteractivePostViewDelegate

    func edit(_ post: AbstractPost) {
        editPost(post)
    }

    func view(_ post: AbstractPost) {
        viewPost(post)
    }

    func stats(for post: AbstractPost) {
        viewStatsForPost(post)
    }

    func duplicate(_ post: AbstractPost) {
        editDuplicatePost(post)
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

    func trash(_ post: AbstractPost, completion: @escaping () -> Void) {
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

        alertController.addCancelActionWithTitle(cancelText) { _ in
            completion()
        }
        alertController.addDestructiveActionWithTitle(deleteText) { [weak self] action in
            self?.deletePost(post)
            completion()
        }
        alertController.presentFromRootViewController()
    }

    func draft(_ post: AbstractPost) {
        moveToDraft(post)
    }

    func retry(_ post: AbstractPost) {
        PostCoordinator.shared.save(post)
    }

    func cancelAutoUpload(_ post: AbstractPost) {
        PostCoordinator.shared.cancelAutoUploadOf(post)
    }

    func share(_ post: AbstractPost, fromView view: UIView) {
        guard let post = post as? Post else {
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

    func comments(_ post: AbstractPost) {
        WPAnalytics.track(.postListCommentsAction, properties: propertiesForAnalytics())
        let contentCoordinator = DefaultContentCoordinator(controller: self, context: ContextManager.sharedInstance().mainContext)
        try? contentCoordinator.displayCommentsWithPostId(post.postID, siteID: blog.dotComID, commentID: nil, source: .postsList)
    }

    func showSettings(for post: AbstractPost) {
        WPAnalytics.track(.postListSettingsAction, properties: propertiesForAnalytics())
        PostSettingsViewController.showStandaloneEditor(for: post, from: self)
    }

    // MARK: - NetworkAwareUI

    override func noConnectionMessage() -> String {
        return NSLocalizedString("No internet connection. Some posts may be unavailable while offline.",
                                 comment: "Error message shown when the user is browsing Site Posts without an internet connection.")
    }

    private enum Constants {
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
