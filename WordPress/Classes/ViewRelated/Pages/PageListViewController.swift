import Foundation
import CocoaLumberjack
import WordPressShared
import WordPressFlux
import UIKit

class PageListViewController: AbstractPostListViewController, UIViewControllerRestoration {
    private struct Constant {
        struct Size {
            static let pageCellEstimatedRowHeight = CGFloat(44.0)
            static let pageListTableViewCellLeading = CGFloat(16.0)
        }

        struct Identifiers {
            static let pagesViewControllerRestorationKey = "PagesViewControllerRestorationKey"
            static let pageCellIdentifier = "PageCellIdentifier"
            static let templatePageCellIdentifier = "TemplatePageCellIdentifier"
        }

        struct Events {
            static let source = "page_list"
            static let pagePostType = "page"
            static let editHomepageSource = "page_list_edit_homepage"
        }

        static let editorUrl = "site-editor.php?canvas=edit"
    }

    private enum Section: Int {
        case templates = 0
        case pages = 1
    }

    private lazy var homepageSettingsService = {
        HomepageSettingsService(blog: blog, coreDataStack: ContextManager.shared)
    }()

    private lazy var createButtonCoordinator: CreateButtonCoordinator = {
        let action = PageAction(handler: { [weak self] in
            self?.createPost()
        }, source: Constant.Events.source)
        return CreateButtonCoordinator(self, actions: [action], source: Constant.Events.source)
    }()

    var showEditorHomepage: Bool {
        guard RemoteFeatureFlag.siteEditorMVP.enabled() else {
            return false
        }
        let isFSETheme = blog.blockEditorSettings?.isFSETheme ?? false
        return isFSETheme && filterSettings.currentPostListFilter().filterType == .published
    }

    private lazy var editorSettingsService = {
        return BlockEditorSettingsService(blog: blog, coreDataStack: ContextManager.shared)
    }()

    private var pages: [Page] = []

    // MARK: - Convenience constructors

    @objc class func controllerWithBlog(_ blog: Blog) -> PageListViewController {
        let vc = PageListViewController()
        vc.blog = blog
        vc.restorationClass = self
        if QuickStartTourGuide.shared.isCurrentElement(.pages) {
            vc.filterSettings.setFilterWithPostStatus(BasePost.Status.publish)
        }
        return vc
    }

    static func showForBlog(_ blog: Blog, from sourceController: UIViewController) {
        let controller = PageListViewController.controllerWithBlog(blog)
        controller.navigationItem.largeTitleDisplayMode = .never
        sourceController.navigationController?.pushViewController(controller, animated: true)

        QuickStartTourGuide.shared.visited(.pages)
    }

    // MARK: - UIViewControllerRestoration

    class func viewController(withRestorationIdentifierPath identifierComponents: [String],
                              coder: NSCoder) -> UIViewController? {

        let context = ContextManager.sharedInstance().mainContext

        guard let blogID = coder.decodeObject(forKey: Constant.Identifiers.pagesViewControllerRestorationKey) as? String,
            let objectURL = URL(string: blogID),
            let objectID = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: objectURL),
            let restoredBlog = try? context.existingObject(with: objectID) as? Blog else {

                return nil
        }

        return controllerWithBlog(restoredBlog)
    }

    // MARK: - UIStateRestoring

    override func encodeRestorableState(with coder: NSCoder) {

        let objectString = blog?.objectID.uriRepresentation().absoluteString

        coder.encode(objectString, forKey: Constant.Identifiers.pagesViewControllerRestorationKey)

        super.encodeRestorableState(with: coder)
    }

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        if QuickStartTourGuide.shared.isCurrentElement(.newPage) {
            updateFilterWithPostStatus(.publish)
        }

        super.updateAndPerformFetchRequest()

        title = NSLocalizedString("Pages", comment: "Title of the screen showing the list of pages for a blog.")

        createButtonCoordinator.add(to: view, trailingAnchor: view.safeAreaLayoutGuide.trailingAnchor, bottomAnchor: view.safeAreaLayoutGuide.bottomAnchor)

        refreshNoResultsViewController = { [weak self] in
            self?.handleRefreshNoResultsViewController($0)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if traitCollection.horizontalSizeClass == .compact {
            createButtonCoordinator.showCreateButton(for: blog)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        QuickStartTourGuide.shared.endCurrentTour()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.horizontalSizeClass == .compact {
            createButtonCoordinator.showCreateButton(for: blog)
        } else {
            createButtonCoordinator.hideCreateButton()
        }
    }

    // MARK: - Configuration

    override func configureTableView() {
        super.configureTableView()

        tableView.accessibilityIdentifier = "PagesTable"
        tableView.estimatedRowHeight = Constant.Size.pageCellEstimatedRowHeight

        tableView.register(PageListCell.self, forCellReuseIdentifier: Constant.Identifiers.pageCellIdentifier)
        tableView.register(TemplatePageTableViewCell.self, forCellReuseIdentifier: Constant.Identifiers.templatePageCellIdentifier)
    }

    fileprivate func beginRefreshingManually() {
        refreshControl.beginRefreshing()
        tableView.setContentOffset(CGPoint(x: 0, y: tableView.contentOffset.y - refreshControl.frame.size.height), animated: true)
    }

    // MARK: - Sync Methods

    override internal func postTypeToSync() -> PostServiceType {
        return .page
    }

    override func syncHelper(_ syncHelper: WPContentSyncHelper, syncContentWithUserInteraction userInteraction: Bool, success: ((Bool) -> ())?, failure: ((NSError) -> ())?) {
        // The success and failure blocks are called in the parent class `AbstractPostListViewController` by the `syncPosts` method. Since that class is
        // used by both this one and the "Posts" screen, making changes to the sync helper is tough. To get around that, we make the fetch settings call
        // async and then just await it before calling either the final success or failure block. This ensures that both the `syncPosts` call in the parent
        // and the `fetchSettings` call here finish before calling the final success or failure block.
        let (wrappedSuccess, wrappedFailure) = fetchEditorSettings(success: success, failure: failure)
        super.syncHelper(syncHelper, syncContentWithUserInteraction: userInteraction, success: wrappedSuccess, failure: wrappedFailure)
    }

    private func fetchEditorSettings(success: ((Bool) -> ())?, failure: ((NSError) -> ())?) -> (success: (_ hasMore: Bool) -> (), failure: (NSError) -> ()) {
        let fetchTask = Task { @MainActor [weak self] in
            guard RemoteFeatureFlag.siteEditorMVP.enabled(),
                  let result = await self?.editorSettingsService?.fetchSettings() else {
                return
            }
            switch result {
            case .success(let serviceResult):
                if serviceResult.hasChanges {
                    self?.tableView.reloadData()
                }
            case .failure(let error):
                DDLogError("Error fetching editor settings: \(error)")
            }
        }

        let wrappedSuccess: (_ hasMore: Bool) -> () = { hasMore in
            Task { @MainActor in
                await fetchTask.value
                success?(hasMore)
            }
        }

        let wrappedFailure: (NSError) -> () = { error in
            Task { @MainActor in
                await fetchTask.value
                failure?(error)
            }
        }

        return (success: wrappedSuccess, failure: wrappedFailure)
    }

    override internal func lastSyncDate() -> Date? {
        return blog?.lastPagesSync
    }

    override func updateAndPerformFetchRequest() {
        super.updateAndPerformFetchRequest()

        reloadPages()
    }

    private func reloadPages() {
        let status = filterSettings.currentPostListFilter().filterType
        let pages = (fetchResultsController.fetchedObjects ?? []) as! [Page]
        if status == .published {
            self.pages = pages.setHomePageFirst().hierarchySort()
        } else {
            self.pages = pages
        }
    }

    override func syncContentEnded(_ syncHelper: WPContentSyncHelper) {
        guard syncHelper.hasMoreContent else {
            super.syncContentEnded(syncHelper)
            return
        }
    }

    // MARK: - NSFetchedResultsControllerDelegate

    override func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // Do nothing
    }

    override func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        // Do nothing, refresh all
    }

    override func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        reloadPages()
        tableView.reloadData()
        refreshResults()
    }

    // MARK: - TableView Handler Delegate Methods

    override func entityName() -> String {
        return String(describing: Page.self)
    }

    override func predicateForFetchRequest() -> NSPredicate {
        var predicates = [NSPredicate]()

        if let blog = blog {
            let basePredicate = NSPredicate(format: "blog = %@ && revision = nil", blog)
            predicates.append(basePredicate)
        }

        if filterSettings.shouldShowOnlyMyPosts() {
            let myAuthorID = blogUserID() ?? 0

            // Brand new local drafts have an authorID of 0.
            let authorPredicate = NSPredicate(format: "authorID = %@ || authorID = 0", myAuthorID)
            predicates.append(authorPredicate)
        }

        let filterPredicate = filterSettings.currentPostListFilter().predicateForFetchRequest
        predicates.append(filterPredicate)

        if filterSettings.shouldShowOnlyMyPosts() {
            let myAuthorID = blogUserID() ?? 0

            // Brand new local drafts have an authorID of 0.
            let authorPredicate = NSPredicate(format: "authorID = %@ || authorID = 0", myAuthorID)
            predicates.append(authorPredicate)
        }

        if RemoteFeatureFlag.siteEditorMVP.enabled(),
                   blog.blockEditorSettings?.isFSETheme ?? false,
                   let homepageID = blog.homepagePageID,
                   let homepageType = blog.homepageType,
           homepageType == .page {
            predicates.append(NSPredicate(format: "postID != %i", homepageID))
        }

        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        return predicate
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch Section(rawValue: indexPath.section)! {
        case .templates:
            WPAnalytics.track(.pageListEditHomepageTapped)
            guard let editorUrl = URL(string: blog.adminUrl(withPath: Constant.editorUrl)) else {
                return
            }

            let webViewController = WebViewControllerFactory.controller(url: editorUrl,
                                                                        blog: blog,
                                                                        source: Constant.Events.editHomepageSource)
            let navigationController = UINavigationController(rootViewController: webViewController)
            present(navigationController, animated: true)
        case .pages:
            let page = pages[indexPath.row]
            edit(page)
        }
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .templates:
            return showEditorHomepage ? 1 : 0
        case .pages:
            return pages.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {
        case .templates:
            let identifier = Constant.Identifiers.templatePageCellIdentifier
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
            return cell
        case .pages:
            let cell = tableView.dequeueReusableCell(withIdentifier: Constant.Identifiers.pageCellIdentifier, for: indexPath) as! PageListCell
            let page = pages[indexPath.row]
            let indentation = getIndentationLevel(at: indexPath)
            let isFirstSubdirectory = getIndentationLevel(at: IndexPath(row: indexPath.row - 1, section: indexPath.section)) == (indentation - 1)
            let viewModel = PageListItemViewModel(page: page, indexPath: indexPath)
            cell.configure(with: viewModel, indentation: indentation, isFirstSubdirectory: isFirstSubdirectory, delegate: self)
            return cell
        }
    }

    private func getIndentationLevel(at indexPath: IndexPath) -> Int {
        guard filterSettings.currentPostListFilter().filterType == .published,
              indexPath.row > 0 else {
            return 0
        }
        return pages[indexPath.row].hierarchyIndex
    }

    // MARK: - Post Actions

    override func createPost() {
        WPAppAnalytics.track(.editorCreatedPost, withProperties: [WPAppAnalyticsKeyTapSource: Constant.Events.source, WPAppAnalyticsKeyPostType: Constant.Events.pagePostType], with: blog)

        PageCoordinator.showLayoutPickerIfNeeded(from: self, forBlog: blog) { [weak self] (selectedLayout) in
            self?.createPage(selectedLayout)
        }
    }

    private func createPage(_ starterLayout: PageTemplateLayout?) {
        let editorViewController = EditPageViewController(blog: blog, postTitle: starterLayout?.title, content: starterLayout?.content, appliedTemplate: starterLayout?.slug)
        present(editorViewController, animated: false)

        QuickStartTourGuide.shared.visited(.newPage)
    }

    // MARK: - Cell Action Handling

    func setParentPage(for page: Page, at index: IndexPath?) {
        let request = NSFetchRequest<Page>(entityName: Page.entityName())
        let filter = PostListFilter.publishedFilter()
        request.predicate = filter.predicate(for: blog, author: .everyone)
        request.sortDescriptors = filter.sortDescriptors
        do {
            var pages = try managedObjectContext()
                .fetch(request)
                .setHomePageFirst()
                .hierarchySort()
            if let index = pages.firstIndex(of: page) {
                pages = pages.remove(from: index)
            }
            let viewController = ParentPageSettingsViewController.navigationController(with: pages, selectedPage: page, onClose: { [weak self] in
                self?.updateAndPerformFetchRequestRefreshingResults()
            }, onSuccess: { [weak self] in
                self?.handleSetParentSuccess()
            } )
            present(viewController, animated: true)
        } catch {
            assertionFailure("Failed to fetch pages: \(error)") // This should never happen
        }
    }

    private func handleSetParentSuccess() {
        let setParentSuccefullyNotice =  NSLocalizedString("Parent page successfully updated.", comment: "Message informing the user that their pages parent has been set successfully")
        let notice = Notice(title: setParentSuccefullyNotice, feedbackType: .success)
        ActionDispatcher.global.dispatch(NoticeAction.post(notice))
    }

    func setPageAsHomepage(_ page: Page) {
        guard let pageID = page.postID?.intValue else { return }

        beginRefreshingManually()
        WPAnalytics.track(.postListSetHomePageAction)
        homepageSettingsService?.setHomepageType(.page, homePageID: pageID, success: { [weak self] in
            self?.refreshAndReload()
            self?.handleHomepageSettingsSuccess()
        }, failure: { [weak self] error in
            self?.refreshControl.endRefreshing()
            self?.handleHomepageSettingsFailure()
        })
    }

    func setPageAsPostsPage(_ page: Page) {
        guard let pageID = page.postID?.intValue else { return }

        beginRefreshingManually()
        WPAnalytics.track(.postListSetAsPostsPageAction)
        homepageSettingsService?.setHomepageType(.page, withPostsPageID: pageID, success: { [weak self] in
            self?.refreshAndReload()
            self?.handleHomepagePostsPageSettingsSuccess()
        }, failure: { [weak self] error in
            self?.refreshControl.endRefreshing()
            self?.handleHomepageSettingsFailure()
        })
    }

    private func handleHomepageSettingsSuccess() {
        let notice = Notice(title: HomepageSettingsText.updateHomepageSuccessTitle, feedbackType: .success)
        ActionDispatcher.global.dispatch(NoticeAction.post(notice))
    }

    private func handleHomepagePostsPageSettingsSuccess() {
        let notice = Notice(title: HomepageSettingsText.updatePostsPageSuccessTitle, feedbackType: .success)
        ActionDispatcher.global.dispatch(NoticeAction.post(notice))
    }

    private func handleHomepageSettingsFailure() {
        let notice = Notice(title: HomepageSettingsText.updateErrorTitle, message: HomepageSettingsText.updateErrorMessage, feedbackType: .error)
        ActionDispatcher.global.dispatch(NoticeAction.post(notice))
    }

    private func handleTrashPage(_ post: AbstractPost) {
        guard ReachabilityUtils.isInternetReachable() else {
            let offlineMessage = NSLocalizedString("Unable to trash pages while offline. Please try again later.", comment: "Message that appears when a user tries to trash a page while their device is offline.")
            ReachabilityUtils.showNoInternetConnectionNotice(message: offlineMessage)
            return
        }

        let cancelText = NSLocalizedString("Cancel", comment: "Cancels an Action")
        let deleteText: String
        let messageText: String
        let titleText: String

        if post.status == .trash {
            deleteText = NSLocalizedString("Delete Permanently", comment: "Delete option in the confirmation alert when deleting a page from the trash.")
            titleText = NSLocalizedString("Delete Permanently?", comment: "Title of the confirmation alert when deleting a page from the trash.")
            messageText = NSLocalizedString("Are you sure you want to permanently delete this page?", comment: "Message of the confirmation alert when deleting a page from the trash.")
        } else {
            deleteText = NSLocalizedString("Move to Trash", comment: "Trash option in the trash page confirmation alert.")
            titleText = NSLocalizedString("Trash this page?", comment: "Title of the trash page confirmation alert.")
            messageText = NSLocalizedString("Are you sure you want to trash this page?", comment: "Message of the trash page confirmation alert.")
        }

        let alertController = UIAlertController(title: titleText, message: messageText, preferredStyle: .alert)

        alertController.addCancelActionWithTitle(cancelText)
        alertController.addDestructiveActionWithTitle(deleteText) { [weak self] action in
            self?.deletePost(post)
        }
        alertController.presentFromRootViewController()
    }

    // MARK: - NetworkAwareUI

    override func noConnectionMessage() -> String {
        return NSLocalizedString("No internet connection. Some pages may be unavailable while offline.",
                                 comment: "Error message shown when the user is browsing Site Pages without an internet connection.")
    }

    struct HomepageSettingsText {
        static let updateErrorTitle = NSLocalizedString("Unable to update homepage settings", comment: "Error informing the user that their homepage settings could not be updated")
        static let updateErrorMessage = NSLocalizedString("Please try again later.", comment: "Prompt for the user to retry a failed action again later")
        static let updateHomepageSuccessTitle = NSLocalizedString("Homepage successfully updated", comment: "Message informing the user that their static homepage page was set successfully")
        static let updatePostsPageSuccessTitle = NSLocalizedString("Posts page successfully updated", comment: "Message informing the user that their static homepage for posts was set successfully")
    }
}

// MARK: - No Results Handling

private extension PageListViewController {

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
        return "pages-no-results"
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
        static let buttonTitle = NSLocalizedString("Create Page", comment: "Button title, encourages users to create their first page on their blog.")
        static let fetchingTitle = NSLocalizedString("Fetching pages...", comment: "A brief prompt shown when the reader is empty, letting the user know the app is currently fetching new pages.")
        static let noDraftsTitle = NSLocalizedString("You don't have any draft pages", comment: "Displayed when the user views drafts in the pages list and there are no pages")
        static let noScheduledTitle = NSLocalizedString("You don't have any scheduled pages", comment: "Displayed when the user views scheduled pages in the pages list and there are no pages")
        static let noTrashedTitle = NSLocalizedString("You don't have any trashed pages", comment: "Displayed when the user views trashed in the pages list and there are no pages")
        static let noPublishedTitle = NSLocalizedString("You haven't published any pages yet", comment: "Displayed when the user views published pages in the pages list and there are no pages")
        static let noConnectionTitle: String = NSLocalizedString("Unable to load pages right now.", comment: "Title for No results full page screen displayedfrom pages list when there is no connection")
        static let noConnectionSubtitle: String = NSLocalizedString("Check your network connection and try again. Or draft a page.", comment: "Subtitle for No results full page screen displayed from pages list when there is no connection")
    }
}
