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

    private lazy var _tableViewHandler: PageListTableViewHandler = {
        let tableViewHandler = PageListTableViewHandler(tableView: self.tableView, blog: self.blog)
        tableViewHandler.cacheRowHeights = false
        tableViewHandler.delegate = self
        tableViewHandler.listensForContentChanges = false
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

    private lazy var homepageSettingsService = {
        HomepageSettingsService(blog: blog, coreDataStack: ContextManager.shared)
    }()

    private lazy var createButtonCoordinator: CreateButtonCoordinator = {
        let action = PageAction(handler: { [weak self] in
            self?.createPost()
        }, source: Constant.Events.source)
        return CreateButtonCoordinator(self, actions: [action], source: Constant.Events.source)
    }()

    private lazy var editorSettingsService = {
        return BlockEditorSettingsService(blog: blog, coreDataStack: ContextManager.shared)
    }()

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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        _tableViewHandler.status = filterSettings.currentPostListFilter().filterType
        _tableViewHandler.refreshTableView()
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
        tableView.accessibilityIdentifier = "PagesTable"
        tableView.estimatedRowHeight = Constant.Size.pageCellEstimatedRowHeight
        tableView.rowHeight = UITableView.automaticDimension

        let bundle = Bundle.main

        // Register the cells
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

    override func selectedFilterDidChange(_ filterBar: FilterTabBar) {
        filterSettings.setCurrentFilterIndex(filterBar.selectedIndex)
        _tableViewHandler.status = filterSettings.currentPostListFilter().filterType
        _tableViewHandler.refreshTableView()

        super.selectedFilterDidChange(filterBar)
    }

    override func updateFilterWithPostStatus(_ status: BasePost.Status) {
        filterSettings.setFilterWithPostStatus(status)
        _tableViewHandler.status = filterSettings.currentPostListFilter().filterType
        _tableViewHandler.refreshTableView()
        super.updateFilterWithPostStatus(status)
    }

    override func updateAndPerformFetchRequest() {
        super.updateAndPerformFetchRequest()

        _tableViewHandler.refreshTableView()
    }

    override func syncContentEnded(_ syncHelper: WPContentSyncHelper) {
        guard syncHelper.hasMoreContent else {
            super.syncContentEnded(syncHelper)
            return
        }
    }

    // MARK: - Model Interaction

    /// Retrieves the page object at the specified index path.
    ///
    /// - Parameter indexPath: the index path of the page object to retrieve.
    ///
    /// - Returns: the requested page.
    ///
    fileprivate func pageAtIndexPath(_ indexPath: IndexPath) -> Page {
        if _tableViewHandler.showEditorHomepage {
            // Since we're adding a fake homepage cell, we need to adjust the index path to match
            let adjustedIndexPath = IndexPath(row: indexPath.row - 1, section: indexPath.section)
            return _tableViewHandler.page(at: adjustedIndexPath)
        }
        return _tableViewHandler.page(at: indexPath)
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

    // MARK: - Table View Handling

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.row == 0 && _tableViewHandler.showEditorHomepage {
            WPAnalytics.track(.pageListEditHomepageTapped)
            guard let editorUrl = URL(string: blog.adminUrl(withPath: Constant.editorUrl)) else {
                return
            }

            let webViewController = WebViewControllerFactory.controller(url: editorUrl,
                                                                        blog: blog,
                                                                        source: Constant.Events.editHomepageSource)
            let navigationController = UINavigationController(rootViewController: webViewController)
            present(navigationController, animated: true)
        } else {
            let page = pageAtIndexPath(indexPath)
            edit(page)
        }
    }

    @objc func tableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 && _tableViewHandler.showEditorHomepage {
            let identifier = Constant.Identifiers.templatePageCellIdentifier
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: Constant.Identifiers.pageCellIdentifier, for: indexPath) as! PageListCell
        let page = pageAtIndexPath(indexPath)
        let indentation = getIndentationLevel(at: indexPath)
        let isFirstSubdirectory = getIndentationLevel(at: IndexPath(row: indexPath.row - 1, section: indexPath.section)) == (indentation - 1)
        let viewModel = PageListItemViewModel(page: page, homepageType: blog.homepageType)
        cell.configure(with: viewModel, indentation: indentation, isFirstSubdirectory: isFirstSubdirectory, delegate: self)
        return cell
    }

    private func getIndentationLevel(at indexPath: IndexPath) -> Int {
        guard filterSettings.currentPostListFilter().filterType == .published else {
            return 0
        }
        let lowerBound = _tableViewHandler.showEditorHomepage ? 1 : 0
        guard indexPath.row > lowerBound else {
            return 0
        }
        return pageAtIndexPath(indexPath).hierarchyIndex
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

    private func blazePage(_ page: AbstractPost) {
        BlazeEventsTracker.trackEntryPointTapped(for: .pagesList)
        BlazeFlowCoordinator.presentBlaze(in: self, source: .pagesList, blog: blog, post: page)
    }

    fileprivate func copyPage(_ page: Page) {
        // Analytics
        WPAnalytics.track(.postListDuplicateAction, withProperties: propertiesForAnalytics())
        // Copy Page
        let newPage = page.blog.createDraftPage()
        newPage.postTitle = page.postTitle
        newPage.content = page.content
        // Open Editor
        let editorViewController = EditPageViewController(page: newPage)
        present(editorViewController, animated: false)
    }

    fileprivate func copyLink(_ page: Page) {
        let pasteboard = UIPasteboard.general
        guard let link = page.permaLink else { return }
        pasteboard.string = link as String
        let noticeTitle = NSLocalizedString("Link Copied to Clipboard", comment: "Link copied to clipboard notice title")
        let notice = Notice(title: noticeTitle, feedbackType: .success)
        ActionDispatcher.dispatch(NoticeAction.dismiss) // Dismiss any old notices
        ActionDispatcher.dispatch(NoticeAction.post(notice))
    }

    fileprivate func retryPage(_ apost: AbstractPost) {
        PostCoordinator.shared.save(apost)
    }

    fileprivate func draftPage(_ apost: AbstractPost, at indexPath: IndexPath?) {
        WPAnalytics.track(.postListDraftAction, withProperties: propertiesForAnalytics())

        let repository = PostRepository(coreDataStack: ContextManager.shared)
        Task { @MainActor [weak self] in
            do {
                try await repository.restore(TaggedManagedObjectID(apost), to: .draft)
                self?._tableViewHandler.refreshTableView(at: indexPath)
            } catch {
                WPError.showXMLRPCErrorAlert(error)
            }
        }
    }

    // MARK: - Cell Action Handling

    fileprivate func handleMenuAction(fromCell cell: UITableViewCell, fromButton button: UIButton, forPage page: AbstractPost) {
        let objectID = page.objectID

        let retryButtonTitle = NSLocalizedString("Retry", comment: "Label for a button that attempts to re-upload a page that previously failed to upload.")
        let viewButtonTitle = NSLocalizedString("View", comment: "Label for a button that opens the page when tapped.")
        let draftButtonTitle = NSLocalizedString("Move to Draft", comment: "Label for a button that moves a page to the draft folder")
        let publishButtonTitle = NSLocalizedString("Publish Immediately", comment: "Label for a button that moves a page to the published folder, publishing with the current date/time.")
        let trashButtonTitle = NSLocalizedString("Move to Trash", comment: "Label for a button that moves a page to the trash folder")
        let cancelButtonTitle = NSLocalizedString("Cancel", comment: "Label for a cancel button")
        let deleteButtonTitle = NSLocalizedString("Delete Permanently", comment: "Label for a button permanently deletes a page.")

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addCancelActionWithTitle(cancelButtonTitle, handler: nil)

        let indexPath = tableView.indexPath(for: cell)

        let filter = filterSettings.currentPostListFilter().filterType
        let isHomepage = ((page as? Page)?.isSiteHomepage ?? false)
        if filter == .trashed {
            alertController.addActionWithTitle(draftButtonTitle, style: .default, handler: { [weak self] (action) in
                guard let strongSelf = self,
                    let page = strongSelf.pageForObjectID(objectID) else {
                        return
                }

                strongSelf.draftPage(page, at: indexPath)
            })

            alertController.addActionWithTitle(deleteButtonTitle, style: .destructive, handler: { [weak self] (action) in
                guard let strongSelf = self,
                    let page = strongSelf.pageForObjectID(objectID) else {
                        return
                }

                strongSelf.handleTrashPage(page)
            })
        } else if filter == .published {
            if page.isFailed {
                alertController.addActionWithTitle(retryButtonTitle, style: .default, handler: { [weak self] (action) in
                    guard let strongSelf = self,
                        let page = strongSelf.pageForObjectID(objectID) else {
                            return
                    }

                    strongSelf.retryPage(page)
                })
            } else {
                addEditAction(to: alertController, for: page)

                alertController.addActionWithTitle(viewButtonTitle, style: .default, handler: { [weak self] (action) in
                    guard let strongSelf = self,
                        let page = strongSelf.pageForObjectID(objectID) else {
                            return
                    }

                    strongSelf.viewPost(page)
                })

                addBlazeAction(to: alertController, for: page)
                addSetParentAction(to: alertController, for: page, at: indexPath)
                addSetHomepageAction(to: alertController, for: page, at: indexPath)
                addSetPostsPageAction(to: alertController, for: page, at: indexPath)
                addDuplicateAction(to: alertController, for: page)

                if !isHomepage {
                    alertController.addActionWithTitle(draftButtonTitle, style: .default, handler: { [weak self] (action) in
                        guard let strongSelf = self,
                              let page = strongSelf.pageForObjectID(objectID) else {
                            return
                        }

                        strongSelf.draftPage(page, at: indexPath)
                    })
                }
            }

            addCopyLinkAction(to: alertController, for: page)

            if !isHomepage {
                alertController.addActionWithTitle(trashButtonTitle, style: .destructive, handler: { [weak self] (action) in
                    guard let strongSelf = self,
                          let page = strongSelf.pageForObjectID(objectID) else {
                        return
                    }

                    strongSelf.handleTrashPage(page)
                })
            }
        } else {
            if page.isFailed {
                alertController.addActionWithTitle(retryButtonTitle, style: .default, handler: { [weak self] (action) in
                    guard let strongSelf = self,
                        let page = strongSelf.pageForObjectID(objectID) else {
                            return
                    }

                    strongSelf.retryPage(page)
                })
            } else {
                addEditAction(to: alertController, for: page)

                alertController.addActionWithTitle(viewButtonTitle, style: .default, handler: { [weak self] (action) in
                    guard let strongSelf = self,
                        let page = strongSelf.pageForObjectID(objectID) else {
                            return
                    }

                    strongSelf.viewPost(page)
                })

                addSetParentAction(to: alertController, for: page, at: indexPath)
                addDuplicateAction(to: alertController, for: page)

                alertController.addActionWithTitle(publishButtonTitle, style: .default, handler: { [weak self] (action) in
                    guard let strongSelf = self,
                        let page = strongSelf.pageForObjectID(objectID) else {
                            return
                    }

                    strongSelf.publishPost(page)
                })
            }

            addCopyLinkAction(to: alertController, for: page)

            alertController.addActionWithTitle(trashButtonTitle, style: .destructive, handler: { [weak self] (action) in
                guard let strongSelf = self,
                    let page = strongSelf.pageForObjectID(objectID) else {
                        return
                }

                strongSelf.handleTrashPage(page)
            })
        }

        WPAnalytics.track(.postListOpenedCellMenu, withProperties: propertiesForAnalytics())

        alertController.modalPresentationStyle = .popover
        present(alertController, animated: true)

        if let presentationController = alertController.popoverPresentationController {
            presentationController.permittedArrowDirections = .any
            presentationController.sourceView = button
            presentationController.sourceRect = button.bounds
        }
    }

    private func addBlazeAction(to controller: UIAlertController, for page: AbstractPost) {
        guard BlazeHelper.isBlazeFlagEnabled() && page.canBlaze else {
            return
        }

        let buttonTitle = NSLocalizedString("pages.blaze.actionTitle", value: "Promote with Blaze", comment: "Promote the page with Blaze.")
        controller.addActionWithTitle(buttonTitle, style: .default, handler: { [weak self] _ in
            self?.blazePage(page)
        })

        BlazeEventsTracker.trackEntryPointDisplayed(for: .pagesList)
    }

    private func addEditAction(to controller: UIAlertController, for page: AbstractPost) {
        guard let page = page as? Page else { return }

        if page.status == .trash || page.isSitePostsPage {
            return
        }

        let buttonTitle = NSLocalizedString("Edit", comment: "Label for a button that opens the Edit Page view controller")
        controller.addActionWithTitle(buttonTitle, style: .default, handler: { [weak self] _ in
            if let page = self?.pageForObjectID(page.objectID) {
                self?.edit(page)
            }
        })
    }

    private func addDuplicateAction(to controller: UIAlertController, for page: AbstractPost) {
        if page.status != .publish && page.status != .draft {
            return
        }

        let buttonTitle = NSLocalizedString("Duplicate", comment: "Label for page duplicate option. Tapping creates a copy of the page.")
        controller.addActionWithTitle(buttonTitle, style: .default, handler: { [weak self] _ in
            if let page = self?.pageForObjectID(page.objectID) {
                self?.copyPage(page)
            }
        })
    }

    private func addCopyLinkAction(to controller: UIAlertController, for page: AbstractPost) {
        let buttonTitle = NSLocalizedString("Copy Link", comment: "Label for page copy link. Tapping copy the url of page")
        controller.addActionWithTitle(buttonTitle, style: .default) { [weak self] _ in
            if let page = self?.pageForObjectID(page.objectID) {
                self?.copyLink(page)
            }
        }
    }

    private func addSetParentAction(to controller: UIAlertController, for page: AbstractPost, at index: IndexPath?) {
        /// This button is disabled for trashed pages
        //
        if page.status == .trash {
            return
        }

        let objectID = page.objectID
        let setParentButtonTitle = NSLocalizedString("Set Parent", comment: "Label for a button that opens the Set Parent options view controller")
        controller.addActionWithTitle(setParentButtonTitle, style: .default, handler: { [weak self] _ in
            if let page = self?.pageForObjectID(objectID) {
                self?.setParent(for: page, at: index)
            }
        })
    }

    private func setParent(for page: Page, at index: IndexPath?) {
        guard let index = index else {
            return
        }

        let selectedPage = pageAtIndexPath(index)
        let newIndex = _tableViewHandler.index(for: selectedPage)
        let pages = _tableViewHandler.removePage(from: newIndex)
        let parentPageNavigationController = ParentPageSettingsViewController.navigationController(with: pages, selectedPage: selectedPage, onClose: { [weak self] in
            self?._tableViewHandler.refreshTableView(at: index)
        }, onSuccess: { [weak self] in
            self?.handleSetParentSuccess()
        } )
        present(parentPageNavigationController, animated: true)
    }

    private func handleSetParentSuccess() {
        let setParentSuccefullyNotice =  NSLocalizedString("Parent page successfully updated.", comment: "Message informing the user that their pages parent has been set successfully")
        let notice = Notice(title: setParentSuccefullyNotice, feedbackType: .success)
        ActionDispatcher.global.dispatch(NoticeAction.post(notice))
    }

    fileprivate func pageForObjectID(_ objectID: NSManagedObjectID) -> Page? {

        var pageManagedOjbect: NSManagedObject

        do {
            pageManagedOjbect = try managedObjectContext().existingObject(with: objectID)

        } catch let error as NSError {
            DDLogError("\(NSStringFromClass(type(of: self))), \(#function), \(error)")
            return nil
        } catch _ {
            DDLogError("\(NSStringFromClass(type(of: self))), \(#function), Could not find Page with ID \(objectID)")
            return nil
        }

        let page = pageManagedOjbect as? Page
        return page
    }

    private func addSetHomepageAction(to controller: UIAlertController, for page: AbstractPost, at index: IndexPath?) {
        let objectID = page.objectID

        /// This button is enabled if
        /// - Page is not trashed
        /// - The site's homepage type is .page
        /// - The page isn't currently the homepage
        //
        guard page.status != .trash,
            let homepageType = blog.homepageType,
            homepageType == .page,
            let page = pageForObjectID(objectID),
            page.isSiteHomepage == false else {
            return
        }

        let setHomepageButtonTitle = NSLocalizedString("Set as Homepage", comment: "Label for a button that sets the selected page as the site's Homepage")
        controller.addActionWithTitle(setHomepageButtonTitle, style: .default, handler: { [weak self] _ in
            if let pageID = page.postID?.intValue {
                self?.beginRefreshingManually()
                WPAnalytics.track(.postListSetHomePageAction)
                self?.homepageSettingsService?.setHomepageType(.page,
                                                               homePageID: pageID, success: {
                                                                self?.refreshAndReload()
                                                                self?.handleHomepageSettingsSuccess()
                }, failure: { error in
                    self?.refreshControl.endRefreshing()
                    self?.handleHomepageSettingsFailure()
                })
            }
        })
    }

    private func addSetPostsPageAction(to controller: UIAlertController, for page: AbstractPost, at index: IndexPath?) {
        let objectID = page.objectID

        /// This button is enabled if
        /// - Page is not trashed
        /// - The site's homepage type is .page
        /// - The page isn't currently the posts page
        //
        guard page.status != .trash,
            let homepageType = blog.homepageType,
            homepageType == .page,
            let page = pageForObjectID(objectID),
            page.isSitePostsPage == false else {
            return
        }

        let setPostsPageButtonTitle = NSLocalizedString("Set as Posts Page", comment: "Label for a button that sets the selected page as the site's Posts page")
        controller.addActionWithTitle(setPostsPageButtonTitle, style: .default, handler: { [weak self] _ in
            if let pageID = page.postID?.intValue {
                self?.beginRefreshingManually()
                WPAnalytics.track(.postListSetAsPostsPageAction)
                self?.homepageSettingsService?.setHomepageType(.page,
                                                               withPostsPageID: pageID, success: {
                                                                self?.refreshAndReload()
                                                                self?.handleHomepagePostsPageSettingsSuccess()
                }, failure: { error in
                    self?.refreshControl.endRefreshing()
                    self?.handleHomepageSettingsFailure()
                })
            }
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
            Task { await self?.deletePost(post) }
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
