import Foundation
import WordPressShared
import Gridicons
import UIKit
import WordPressUI

final class PostListViewController: AbstractPostListViewController, InteractivePostViewDelegate {
    /// If set, when the post list appear it will show the tab for this status
    private var initialFilterWithPostStatus: BasePost.Status?

    // MARK: - Convenience constructors

    class func controllerWithBlog(_ blog: Blog) -> PostListViewController {
        let vc = PostListViewController()
        vc.blog = blog
        return vc
    }

    static func showForBlog(_ blog: Blog, from sourceController: UIViewController, withPostStatus postStatus: BasePost.Status? = nil) {
        let controller = PostListViewController.controllerWithBlog(blog)
        controller.navigationItem.largeTitleDisplayMode = .never
        controller.initialFilterWithPostStatus = postStatus
        sourceController.navigationController?.pushViewController(controller, animated: true)
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

        createButtonCoordinator.showCreateButton(for: blog)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        toggleCreateButton()
    }

    /// Shows/hides the create button based on the trait collection horizontal size class
    @objc private func toggleCreateButton() {
        createButtonCoordinator.showCreateButton(for: blog)
    }

    // MARK: - Configuration

    override func configureTableView() {
        super.configureTableView()

        tableView.accessibilityIdentifier = "PostsTable"
        tableView.register(PostListCell.self, forCellReuseIdentifier: PostListCell.defaultReuseID)
    }

    private func configureInitialFilterIfNeeded() {
        guard let initialFilterWithPostStatus else {
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

        if let blog {
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

        WPAnalytics.track(.postListItemSelected, properties: propertiesForAnalytics())
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
        WPAppAnalytics.track(.editorCreatedPost, properties: [WPAppAnalyticsKeyTapSource: "posts_view", WPAppAnalyticsKeyPostType: "post"], blog: blog)
    }

    private func editPost(_ post: AbstractPost) {
        guard let post = post as? Post else {
            return
        }
        PostListEditorPresenter.handle(post: post, in: self, entryPoint: .postsList)
    }

    private func editDuplicatePost(_ post: AbstractPost) {
        guard let post = post.latest() as? Post else {
            return wpAssertionFailure("unexpected post type")
        }
        PostListEditorPresenter.handleCopy(post: post, in: self)
    }

    // MARK: - InteractivePostViewDelegate

    func edit(_ post: AbstractPost) {
        editPost(post)
    }

    func view(_ post: AbstractPost) {
        viewPost(post)
    }

    func duplicate(_ post: AbstractPost) {
        editDuplicatePost(post)
    }

    func draft(_ post: AbstractPost) {
        moveToDraft(post)
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
        WPAnalytics.track(.postListBlazeAction, properties: propertiesForAnalytics())
        BlazeEventsTracker.trackEntryPointTapped(for: .postsList)
        BlazeFlowCoordinator.presentBlaze(in: self, source: .postsList, blog: blog, post: post)
    }

    func comments(_ post: AbstractPost) {
        WPAnalytics.track(.postListCommentsAction, properties: propertiesForAnalytics())
        let contentCoordinator = DefaultContentCoordinator(controller: self, context: ContextManager.shared.mainContext)
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
            noResultsViewController.configure(title: "", noConnectionTitle: NoResultsText.noConnectionTitle, buttonTitle: nil, subtitle: nil, noConnectionSubtitle: NoResultsText.noConnectionSubtitle, attributedSubtitle: nil, attributedSubtitleConfiguration: nil, image: nil, subtitleImage: nil, accessoryView: nil)
            return
        }

        let accessoryView = syncHelper.isSyncing ? NoResultsViewController.loadingAccessoryView() : nil

        noResultsViewController.configure(title: noResultsTitle(),
                                          buttonTitle: nil,
                                          image: noResultsImageName,
                                          accessoryView: accessoryView)
    }

    var noResultsImageName: String {
        return "posts-no-results"
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
        static let fetchingTitle = NSLocalizedString("Fetching posts...", comment: "A brief prompt shown when the reader is empty, letting the user know the app is currently fetching new posts.")
        static let noDraftsTitle = NSLocalizedString("You don't have any draft posts", comment: "Displayed when the user views drafts in the posts list and there are no posts")
        static let noScheduledTitle = NSLocalizedString("You don't have any scheduled posts", comment: "Displayed when the user views scheduled posts in the posts list and there are no posts")
        static let noTrashedTitle = NSLocalizedString("You don't have any trashed posts", comment: "Displayed when the user views trashed in the posts list and there are no posts")
        static let noPublishedTitle = NSLocalizedString("You haven't published any posts yet", comment: "Displayed when the user views published posts in the posts list and there are no posts")
        static let noConnectionTitle: String = NSLocalizedString("Unable to load posts right now.", comment: "Title for No results full page screen displayedfrom post list when there is no connection")
        static let noConnectionSubtitle: String = NSLocalizedString("Check your network connection and try again. Or draft a post.", comment: "Subtitle for No results full page screen displayed from post list when there is no connection")
    }
}
