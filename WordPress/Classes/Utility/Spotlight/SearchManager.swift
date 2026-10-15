import UIKit
import CoreSpotlight
import MobileCoreServices
import WordPressData

/// Adopted by `SearchManager` in the Jetpack app (in a Jetpack-only file) to
/// associate App Intents entities with the Spotlight items it indexes. The
/// WordPress app exposes no App Intents entities, so the conformance does not
/// exist there and indexing proceeds without associations.
protocol SearchableItemEntityAssociating {
    func associateAppEntities(from item: SearchableItemConvertable, to searchableItem: CSSearchableItem)
}

/// Encapsulates CoreSpotlight operations for WPiOS
///
@objc class SearchManager: NSObject {

    /// Where a request to open an indexed item came from. Spotlight analytics
    /// only fire for Spotlight-initiated opens.
    enum ItemSource {
        case spotlight
        case appIntent

        /// The analytics source passed to the post preview screen.
        var previewAnalyticsSource: String {
            switch self {
            case .spotlight:
                return "spotlight_preview_post"
            case .appIntent:
                return "app_intent_preview_post"
            }
        }
    }

    // MARK: - Singleton

    @objc static let shared = SearchManager()
    private override init() {}

    // MARK: - Indexing

    /// Index an item to the on-device index
    ///
    /// - Parameters:
    ///   - item: the item to be indexed
    ///
    @objc func indexItem(_ item: SearchableItemConvertable) {
        indexItems([item])
    }

    /// Index items to the on-device index
    ///
    /// - Parameters:
    ///   - items: the items to be indexed
    ///
    @objc func indexItems(_ items: [SearchableItemConvertable]) {
        let associating = (self as AnyObject) as? SearchableItemEntityAssociating
        let items = items.compactMap { item -> CSSearchableItem? in
            guard let searchableItem = item.indexableItem() else {
                return nil
            }
            associating?.associateAppEntities(from: item, to: searchableItem)
            return searchableItem
        }
        guard !items.isEmpty else {
            return
        }

        CSSearchableIndex.default()
            .indexSearchableItems(
                items,
                completionHandler: { (error: Error?) -> Void in
                    guard let error else {
                        return
                    }
                    DDLogError("Could not index post. Error: \(error.localizedDescription)")
                }
            )
    }

    // MARK: - Removal

    /// Remove an item from the on-device index
    ///
    /// - Parameters:
    ///   - item: item to remove
    ///
    @objc func deleteSearchableItem(_ item: SearchableItemConvertable) {
        deleteSearchableItems([item])
    }

    /// Remove items from the on-device index
    ///
    /// - Parameters:
    ///   - items: items to remove
    ///
    @objc func deleteSearchableItems(_ items: [SearchableItemConvertable]) {
        let ids = items.map({ $0.uniqueIdentifier }).compactMap({ $0 })
        guard !ids.isEmpty else {
            return
        }

        CSSearchableIndex.default()
            .deleteSearchableItems(
                withIdentifiers: ids,
                completionHandler: { (error: Error?) -> Void in
                    guard let error else {
                        return
                    }
                    DDLogError("Could not delete CSSearchableItem item. Error: \(error.localizedDescription)")
                }
            )
    }

    /// Removes all items with the given domain identifier from the on-device index
    ///
    /// - Parameters:
    ///   - domain: the domain identifier
    ///
    @objc func deleteAllSearchableItemsFromDomain(_ domain: String) {
        deleteAllSearchableItemsFromDomains([domain])
    }

    /// Removes all items with the given domain identifiers from the on-device index
    ///
    /// - Parameters:
    ///   - domains: the domain identifiers
    ///
    @objc func deleteAllSearchableItemsFromDomains(_ domains: [String]) {
        guard !domains.isEmpty else {
            return
        }

        CSSearchableIndex.default()
            .deleteSearchableItems(
                withDomainIdentifiers: domains,
                completionHandler: { (error: Error?) -> Void in
                    guard let error else {
                        return
                    }
                    DDLogError(
                        "Could not delete CSSearchableItem items for domains: \(domains.joined(separator: ", ")). Error: \(error.localizedDescription)"
                    )
                }
            )
    }

    /// Removes *all* items from the on-device, CoreSpotlight index.
    ///
    /// Note: This clears the entire index for CoreSpotlight only! NSUserActivity indexing will *not* be cleared
    /// if this function is called (each indexed activity item will expire automatically based on the original expiration date).
    ///
    @objc func deleteAllSearchableItems() {
        CSSearchableIndex.default()
            .deleteAllSearchableItems(completionHandler: { (error: Error?) -> Void in
                guard let error else {
                    return
                }
                DDLogError("Could not delete all CSSearchableItem items. Error: \(error.localizedDescription)")
            })
    }

    // MARK: - NSUserActivity Handling

    /// Handle a NSUserAcitivity for both CoreSpotlight and NSUSerActivity indexing within the WPiOS
    ///
    /// - Parameter activity: NSUserActivity that opened the app
    /// - Returns: true if it was handled correctly and activitytype was `CSSearchableItemActionType`, otherwise false
    ///
    @discardableResult
    @objc func handle(activity: NSUserActivity?) -> Bool {
        guard let activity else {
            return false
        }

        switch activity.activityType {
        case CSSearchableItemActionType:
            // This activityType is related to a CoreSpotlight search (SearchableItemConvertable)
            return handleCoreSpotlightSearchableActivityType(activity: activity)
        case WPActivityType.siteList.rawValue:
            WPAppAnalytics.track(.spotlightSearchOpenedApp, withProperties: ["via": WPActivityType.siteList.rawValue])
            return openMySitesTab()
        case WPActivityType.siteDetails.rawValue:
            WPAppAnalytics.track(
                .spotlightSearchOpenedApp,
                withProperties: ["via": WPActivityType.siteDetails.rawValue]
            )
            return handleSite(activity: activity)
        case WPActivityType.reader.rawValue:
            WPAppAnalytics.track(.spotlightSearchOpenedApp, withProperties: ["via": WPActivityType.reader.rawValue])
            return openReaderTab()
        case WPActivityType.me.rawValue:
            WPAppAnalytics.track(.spotlightSearchOpenedApp, withProperties: ["via": WPActivityType.me.rawValue])
            return openMeTab()
        case WPActivityType.appSettings.rawValue:
            WPAppAnalytics.track(
                .spotlightSearchOpenedApp,
                withProperties: ["via": WPActivityType.appSettings.rawValue]
            )
            return openAppSettingsScreen()
        case WPActivityType.notificationSettings.rawValue:
            WPAppAnalytics.track(
                .spotlightSearchOpenedApp,
                withProperties: ["via": WPActivityType.notificationSettings.rawValue]
            )
            return openNotificationSettingsScreen()
        case WPActivityType.support.rawValue:
            WPAppAnalytics.track(.spotlightSearchOpenedApp, withProperties: ["via": WPActivityType.support.rawValue])
            return openSupportScreen()
        case WPActivityType.notifications.rawValue:
            WPAppAnalytics.track(
                .spotlightSearchOpenedApp,
                withProperties: ["via": WPActivityType.notifications.rawValue]
            )
            return openNotificationsTab()
        default:
            return false
        }
    }

    fileprivate func handleCoreSpotlightSearchableActivityType(activity: NSUserActivity) -> Bool {
        guard activity.activityType == CSSearchableItemActionType,
            let compositeIdentifier = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
            SearchIdentifierGenerator.decomposeFromUniqueIdentifier(compositeIdentifier) != nil
        else {
            return false
        }

        Task { @MainActor in
            await self.openItem(withUniqueIdentifier: compositeIdentifier, source: .spotlight)
        }
        return true
    }

    /// Opens the content a composite Spotlight identifier points to, with the
    /// same routing as tapping the item in Spotlight. App Intents share this
    /// entry point because their entity identifiers use the same format.
    ///
    /// - Returns: Whether the target could be resolved and put on screen, so
    ///   callers can surface a failure instead of reporting success blindly.
    @discardableResult
    @MainActor
    func openItem(withUniqueIdentifier compositeIdentifier: String, source: ItemSource) async -> Bool {
        if let identifier = AbstractPost.AppIntentIdentifier(identifier: compositeIdentifier) {
            return await handleAbstractPost(identifier, source: source)
        }
        if let identifier = ReaderPost.AppIntentIdentifier(identifier: compositeIdentifier) {
            return handleReaderPost(identifier, source: source)
        }
        DDLogError("Search manager unable to parse identifier: \(compositeIdentifier)")
        return false
    }

    @MainActor
    fileprivate func handleAbstractPost(
        _ identifier: AbstractPost.AppIntentIdentifier,
        source: ItemSource
    ) async -> Bool {
        guard let post = await fetchPost(identifier), post.status != .trash else {
            DDLogError("Search manager unable to open post - postID:\(identifier.postID) domain:\(identifier.domain)")
            return false
        }

        navigateToScreen(for: post, isDotCom: identifier.isDotCom, source: source)
        return true
    }

    @MainActor
    fileprivate func handleReaderPost(_ identifier: ReaderPost.AppIntentIdentifier, source: ItemSource) -> Bool {
        if source == .spotlight {
            var properties = [AnyHashable: Any]()
            properties[WPAppAnalyticsKeyBlogID] = identifier.siteID
            properties[WPAppAnalyticsKeyPostID] = identifier.postID
            WPAppAnalytics.track(.spotlightSearchOpenedReaderPost, withProperties: properties)
        }
        guard openReader(for: identifier.postID, siteID: identifier.siteID) else {
            DDLogError(
                "Search manager unable to open reader for readerPostID:\(identifier.postID) siteID:\(identifier.siteID)"
            )
            return false
        }
        return true
    }

    fileprivate func handleSite(activity: NSUserActivity) -> Bool {
        guard let userInfo = activity.userInfo as? [String: Any],
            let siteID = userInfo.valueAsString(forKey: WPActivityUserInfoKeys.siteId.rawValue)
        else {
            return false
        }

        if let siteID = validWPComSiteID(with: siteID) {
            fetchBlog(
                siteID,
                onSuccess: { [weak self] blog in
                    self?.openSiteDetailsScreen(for: blog)
                },
                onFailure: {
                    DDLogError("Search manager unable to open site - siteID:\(siteID)")
                }
            )
        } else {
            fetchSelfHostedBlog(
                siteID,
                onSuccess: { [weak self] blog in
                    self?.openSiteDetailsScreen(for: blog)
                },
                onFailure: {
                    DDLogError("Search manager unable to open self hosted site - xmlrpc:\(siteID)")
                }
            )
        }
        return true
    }
}

// MARK: - Private Helpers

fileprivate extension SearchManager {
    func validWPComSiteID(with domainString: String) -> NSNumber? {
        NumberFormatter().number(from: domainString)
    }

    // MARK: Fetching

    @MainActor
    func fetchPost(_ identifier: AbstractPost.AppIntentIdentifier) async -> AbstractPost? {
        let coreDataStack = ContextManager.shared
        guard let blog = identifier.blog(in: coreDataStack.mainContext) else {
            return nil
        }
        // A cached copy opens immediately; the network fetch covers posts
        // that are indexed but no longer cached locally.
        if let post = blog.lookupPost(withID: identifier.postID, in: coreDataStack.mainContext) {
            return post
        }

        let postRepository = PostRepository(coreDataStack: coreDataStack)
        do {
            let postObjectID = try await postRepository.getPost(
                withID: NSNumber(value: identifier.postID),
                from: .init(blog)
            )
            return try coreDataStack.mainContext.existingObject(with: postObjectID)
        } catch {
            return nil
        }
    }

    func fetchBlog(
        _ blogID: NSNumber,
        onSuccess: @escaping (_ blog: Blog) -> Void,
        onFailure: @escaping () -> Void
    ) {
        let context = ContextManager.shared.mainContext

        guard let blog = Blog.lookup(withID: blogID, in: context) else {
            onFailure()
            return
        }
        onSuccess(blog)
    }

    func fetchSelfHostedBlog(
        _ blogXMLRpcString: String,
        onSuccess: @escaping (_ blog: Blog) -> Void,
        onFailure: @escaping () -> Void
    ) {
        let context = ContextManager.shared.mainContext
        guard let blog = Blog.selfHosted(in: context).first(where: { $0.xmlrpc == blogXMLRpcString }) else {
            onFailure()
            return
        }
        onSuccess(blog)
    }

    // MARK: Site Tab Navigation

    func openMySitesTab() -> Bool {
        RootViewCoordinator.sharedPresenter.showMySitesTab()
        return true
    }

    func openSiteDetailsScreen(for blog: Blog) {
        RootViewCoordinator.sharedPresenter.showBlogDetails(for: blog)
    }

    // MARK: Reader Tab Navigation

    func openReaderTab() -> Bool {
        RootViewCoordinator.sharedPresenter.showReader()
        return true
    }

    // MARK: Me Tab Navigation

    func openMeTab() -> Bool {
        RootViewCoordinator.sharedPresenter.showMeScreen()
        return true
    }

    func openAppSettingsScreen() -> Bool {
        RootViewCoordinator.sharedPresenter.navigateToAppSettings()
        return true
    }

    func openSupportScreen() -> Bool {
        RootViewCoordinator.sharedPresenter.navigateToSupport()
        return true
    }

    // MARK: Notification Tab Navigation

    func openNotificationsTab() -> Bool {
        RootViewCoordinator.sharedPresenter.showNotificationsTab()
        return true
    }

    func openNotificationSettingsScreen() -> Bool {
        RootViewCoordinator.sharedPresenter.switchNotificationsTabToNotificationSettings()
        return true
    }

    // MARK: Specific Post & Page Navigation

    func navigateToScreen(for apost: AbstractPost, isDotCom: Bool, source: ItemSource) {
        if source == .spotlight {
            WPAppAnalytics.track(apost is Page ? .spotlightSearchOpenedPage : .spotlightSearchOpenedPost, post: apost)
        }
        let isPublishedOrScheduled = (apost.status == .publish || apost.status == .scheduled)
        if isPublishedOrScheduled && isDotCom && openReader(for: apost) {
            return
        }
        if isPublishedOrScheduled {
            // If opening the reader fails, just open preview.
            openPreview(for: apost, source: source)
        } else if let post = apost as? Post {
            openEditor(for: post)
        } else if let page = apost as? Page {
            openEditor(for: page)
        }
    }

    func openListView(for apost: AbstractPost) {
        closePreviewIfNeeded(for: apost)
        if let post = apost as? Post {
            RootViewCoordinator.sharedPresenter.showBlogDetails(for: post.blog, then: .posts)
        } else if let page = apost as? Page {
            RootViewCoordinator.sharedPresenter.showBlogDetails(for: page.blog, then: .pages)
        }
    }

    func openReader(for apost: AbstractPost) -> Bool {
        closePreviewIfNeeded(for: apost)
        guard let postID = apost.postID, let blogID = apost.blog.dotComID else {
            return false
        }
        return openReader(for: postID.intValue, siteID: blogID.intValue)
    }

    func openReader(for postID: Int, siteID: Int) -> Bool {
        closeAnyOpenPreview()
        guard postID > 0, siteID > 0 else {
            return false
        }
        RootViewCoordinator.sharedPresenter.showReader(path: .post(postID: postID, siteID: siteID))
        return true
    }

    // MARK: - Editor

    func openEditor(for post: Post) {
        closePreviewIfNeeded(for: post)
        openListView(for: post)
        let editor = EditPostViewController(post: post)
        editor.modalPresentationStyle = .fullScreen
        RootViewCoordinator.sharedPresenter.rootViewController.present(editor, animated: true)
    }

    func openEditor(for page: Page) {
        closePreviewIfNeeded(for: page)
        openListView(for: page)

        let editorViewController = EditPageViewController(page: page)
        RootViewCoordinator.sharedPresenter.rootViewController.present(editorViewController, animated: false)
    }

    // MARK: - Preview

    func openPreview(for apost: AbstractPost, source: ItemSource) {
        RootViewCoordinator.sharedPresenter.showMySitesTab()
        closePreviewIfNeeded(for: apost)

        let controller = PreviewWebKitViewController(post: apost, source: source.previewAnalyticsSource)
        controller.trackOpenEvent()
        let navWrapper = UINavigationController(rootViewController: controller)
        let rootViewController = RootViewCoordinator.sharedPresenter.rootViewController
        if rootViewController.traitCollection.userInterfaceIdiom == .pad {
            navWrapper.modalPresentationStyle = .fullScreen
        }
        rootViewController.present(navWrapper, animated: true)

        openListView(for: apost)
    }

    /// If there is a post preview window open and it is already displaying the provided
    /// AbstractPost, leave it open, otherwise close it.
    ///
    func closePreviewIfNeeded(for apost: AbstractPost) {
        let rootViewController = RootViewCoordinator.sharedPresenter.rootViewController
        guard let navController = rootViewController.presentedViewController as? UINavigationController else {
            return
        }

        guard let previewVC = navController.topViewController as? PreviewWebKitViewController,
            previewVC.post != apost
        else {
            // Do nothing — post is already loaded or the post preview view controller isn't visible
            return
        }

        navController.dismiss(animated: true)
    }

    /// If there is any post preview window open, close it.
    ///
    func closeAnyOpenPreview() {
        let rootViewController = RootViewCoordinator.sharedPresenter.rootViewController
        guard let navController = rootViewController.presentedViewController as? UINavigationController,
            navController.topViewController is PreviewWebKitViewController
        else {
            return
        }
        navController.dismiss(animated: true)
    }
}
