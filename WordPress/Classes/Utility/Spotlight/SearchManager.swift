import UIKit
import CoreSpotlight
import MobileCoreServices

/// Encapsulates CoreSpotlight operations for WPiOS
///
@objc class SearchManager: NSObject {

    // MARK: - Singleton

    @objc static let shared: SearchManager = SearchManager()
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
        let items = items.map({ $0.indexableItem() }).compactMap({ $0 })
        guard !items.isEmpty else {
            return
        }

        CSSearchableIndex.default().indexSearchableItems(items, completionHandler: { (error: Error?) -> Void in
            guard let error = error else {
                return
            }
            DDLogError("Could not index post. Error: \(error.localizedDescription)")
        })

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

        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: ids, completionHandler: { (error: Error?) -> Void in
            guard let error = error else {
                return
            }
            DDLogError("Could not delete CSSearchableItem item. Error: \(error.localizedDescription)")
        })
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

        CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: domains, completionHandler: { (error: Error?) -> Void in
            guard let error = error else {
                return
            }
            DDLogError("Could not delete CSSearchableItem items for domains: \(domains.joined(separator: ", ")). Error: \(error.localizedDescription)")
        })
    }

    /// Removes *all* items from the on-device, CoreSpotlight index.
    ///
    /// Note: This clears the entire index for CoreSpotlight only! NSUserActivity indexing will *not* be cleared
    /// if this function is called (each indexed activity item will expire automatically based on the original expiration date).
    ///
    @objc func deleteAllSearchableItems() {
        CSSearchableIndex.default().deleteAllSearchableItems(completionHandler: { (error: Error?) -> Void in
            guard let error = error else {
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
        guard let activity = activity else {
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
            WPAppAnalytics.track(.spotlightSearchOpenedApp, withProperties: ["via": WPActivityType.siteDetails.rawValue])
            return handleSite(activity: activity)
        case WPActivityType.reader.rawValue:
            WPAppAnalytics.track(.spotlightSearchOpenedApp, withProperties: ["via": WPActivityType.reader.rawValue])
            return openReaderTab()
        case WPActivityType.me.rawValue:
            WPAppAnalytics.track(.spotlightSearchOpenedApp, withProperties: ["via": WPActivityType.me.rawValue])
            return openMeTab()
        case WPActivityType.appSettings.rawValue:
            WPAppAnalytics.track(.spotlightSearchOpenedApp, withProperties: ["via": WPActivityType.appSettings.rawValue])
            return openAppSettingsScreen()
        case WPActivityType.notificationSettings.rawValue:
            WPAppAnalytics.track(.spotlightSearchOpenedApp, withProperties: ["via": WPActivityType.notificationSettings.rawValue])
            return openNotificationSettingsScreen()
        case WPActivityType.support.rawValue:
            WPAppAnalytics.track(.spotlightSearchOpenedApp, withProperties: ["via": WPActivityType.support.rawValue])
            return openSupportScreen()
        case WPActivityType.notifications.rawValue:
            WPAppAnalytics.track(.spotlightSearchOpenedApp, withProperties: ["via": WPActivityType.notifications.rawValue])
            return openNotificationsTab()
        default:
            return false
        }
    }

    fileprivate func handleCoreSpotlightSearchableActivityType(activity: NSUserActivity) -> Bool {
        guard activity.activityType == CSSearchableItemActionType,
            let compositeIdentifier = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String else {
            return false
        }

        let (itemType, domainString, identifier) = SearchIdentifierGenerator.decomposeFromUniqueIdentifier(compositeIdentifier)
        switch itemType {
        case .abstractPost:
            return handleAbstractPost(domainString: domainString, identifier: identifier)
        case .readerPost:
            return handleReaderPost(domainString: domainString, identifier: identifier)
        default:
            return false
        }
    }

    fileprivate func handleAbstractPost(domainString: String, identifier: String) -> Bool {
        guard let postID = NumberFormatter().number(from: identifier) else {
            DDLogError("Search manager unable to parse postID/siteID for identifier:\(identifier) domain:\(domainString)")
            return false
        }

        if let siteID = validWPComSiteID(with: domainString) {
            fetchPost(postID, blogID: siteID, onSuccess: { [weak self] apost in
                self?.navigateToScreen(for: apost)
                }, onFailure: {
                    DDLogError("Search manager unable to open post - postID:\(postID) siteID:\(siteID)")
            })
        } else {
            fetchSelfHostedPost(postID, blogXMLRpcString: domainString, onSuccess: { [weak self] apost in
                self?.navigateToScreen(for: apost, isDotCom: false)
                }, onFailure: {
                    DDLogError("Search manager unable to open self hosted post - postID:\(postID) xmlrpc:\(domainString)")
            })
        }

        return true
    }

    fileprivate func handleReaderPost(domainString: String, identifier: String) -> Bool {
        guard let siteID = validWPComSiteID(with: domainString),
            let readerPostID = NumberFormatter().number(from: identifier) else {
                DDLogError("Search manager unable to parse postID/siteID for identifier:\(identifier) domain:\(domainString)")
                return false
        }
        var properties = [AnyHashable: Any]()
        properties[WPAppAnalyticsKeyBlogID] = siteID
        properties[WPAppAnalyticsKeyPostID] = readerPostID
        WPAppAnalytics.track(.spotlightSearchOpenedReaderPost, withProperties: properties)
        openReader(for: readerPostID, siteID: siteID, onFailure: {
            DDLogError("Search manager unable to open reader for readerPostID:\(readerPostID) siteID:\(siteID)")
        })

        return true
    }

    fileprivate func handleSite(activity: NSUserActivity) -> Bool {
        guard let userInfo = activity.userInfo as? [String: Any],
            let siteID = userInfo.valueAsString(forKey: WPActivityUserInfoKeys.siteId.rawValue) else {
            return false
        }

        if let siteID = validWPComSiteID(with: siteID) {
            fetchBlog(siteID, onSuccess: { [weak self] blog in
                self?.openSiteDetailsScreen(for: blog)
                }, onFailure: {
                    DDLogError("Search manager unable to open site - siteID:\(siteID)")
            })
        } else {
            fetchSelfHostedBlog(siteID, onSuccess: { [weak self] blog in
                self?.openSiteDetailsScreen(for: blog)
                }, onFailure: {
                    DDLogError("Search manager unable to open self hosted site - xmlrpc:\(siteID)")
            })
        }
        return true
    }
}

// MARK: - Private Helpers

fileprivate extension SearchManager {
    func validWPComSiteID(with domainString: String) -> NSNumber? {
        return NumberFormatter().number(from: domainString)
    }

    // MARK: Fetching

    func fetchPost(_ postID: NSNumber,
                   blogID: NSNumber,
                   onSuccess: @escaping (_ post: AbstractPost) -> Void,
                   onFailure: @escaping () -> Void) {
        let context = ContextManager.sharedInstance().mainContext
        let blogService = BlogService(managedObjectContext: context)
        guard let blog = blogService.blog(byBlogId: blogID) else {
                onFailure()
                return
        }

        let postService = PostService(managedObjectContext: context)
        postService.getPostWithID(postID, for: blog, success: { apost in
            onSuccess(apost)
        }, failure: { error in
            onFailure()
        })
    }

    func fetchSelfHostedPost(_ postID: NSNumber,
                             blogXMLRpcString: String,
                             onSuccess: @escaping (_ post: AbstractPost) -> Void,
                             onFailure: @escaping () -> Void) {
        let context = ContextManager.sharedInstance().mainContext
        let blogService = BlogService(managedObjectContext: context)
        guard let selfHostedBlogs = blogService.blogsWithNoAccount() as? [Blog],
            let blog = selfHostedBlogs.filter({ $0.xmlrpc == blogXMLRpcString }).first else {
                onFailure()
                return
        }

        let postService = PostService(managedObjectContext: context)
        postService.getPostWithID(postID, for: blog, success: { apost in
            onSuccess(apost)
        }, failure: { error in
            onFailure()
        })
    }

    func fetchBlog(_ blogID: NSNumber,
                   onSuccess: @escaping (_ blog: Blog) -> Void,
                   onFailure: @escaping () -> Void) {
        let context = ContextManager.sharedInstance().mainContext
        let blogService = BlogService(managedObjectContext: context)
        guard let blog = blogService.blog(byBlogId: blogID) else {
            onFailure()
            return
        }
        onSuccess(blog)
    }

    func fetchSelfHostedBlog(_ blogXMLRpcString: String,
                             onSuccess: @escaping (_ blog: Blog) -> Void,
                             onFailure: @escaping () -> Void) {
        let context = ContextManager.sharedInstance().mainContext
        let blogService = BlogService(managedObjectContext: context)
        guard let selfHostedBlogs = blogService.blogsWithNoAccount() as? [Blog],
            let blog = selfHostedBlogs.filter({ $0.xmlrpc == blogXMLRpcString }).first else {
                onFailure()
                return
        }
        onSuccess(blog)
    }

    // MARK: Site Tab Navigation

    func openMySitesTab() -> Bool {
        WPTabBarController.sharedInstance().showMySitesTab()
        return true
    }

    func openSiteDetailsScreen(for blog: Blog) {
        WPTabBarController.sharedInstance().switchMySitesTabToBlogDetails(for: blog)
    }

    // MARK: Reader Tab Navigation

    func openReaderTab() -> Bool {
        WPTabBarController.sharedInstance().showReaderTab()
        return true
    }

    // MARK: Me Tab Navigation

    func openMeTab() -> Bool {
        WPTabBarController.sharedInstance().showMeTab()
        return true
    }

    func openAppSettingsScreen() -> Bool {
        WPTabBarController.sharedInstance().switchMeTabToAppSettings()
        return true
    }

    func openSupportScreen() -> Bool {
        WPTabBarController.sharedInstance().switchMeTabToSupport()
        return true
    }

    // MARK: Notification Tab Navigation

    func openNotificationsTab() -> Bool {
        WPTabBarController.sharedInstance().showNotificationsTab()
        return true
    }

    func openNotificationSettingsScreen() -> Bool {
        WPTabBarController.sharedInstance().switchNotificationsTabToNotificationSettings()
        return true
    }

    // MARK: Specific Post & Page Navigation

    func navigateToScreen(for apost: AbstractPost, isDotCom: Bool = true) {
        if let post = apost as? Post {
            self.navigateToScreen(for: post, isDotCom: isDotCom)
        } else if let page = apost as? Page {
            self.navigateToScreen(for: page, isDotCom: isDotCom)
        }
    }

    func navigateToScreen(for post: Post, isDotCom: Bool) {
        WPAppAnalytics.track(.spotlightSearchOpenedPost, with: post)
        let postIsPublishedOrScheduled = (post.status == .publish || post.status == .scheduled)
        if postIsPublishedOrScheduled && isDotCom {
            openReader(for: post, onFailure: {
                // If opening the reader fails, just open preview.
                openPreview(for: post)
            })
        } else if postIsPublishedOrScheduled {
            openPreview(for: post)
        } else {
            openEditor(for: post)
        }
    }

    func navigateToScreen(for page: Page, isDotCom: Bool) {
        WPAppAnalytics.track(.spotlightSearchOpenedPage, with: page)
        let pageIsPublishedOrScheduled = (page.status == .publish || page.status == .scheduled)
        if pageIsPublishedOrScheduled && isDotCom {
            openReader(for: page, onFailure: {
                // If opening the reader fails, just open preview.
                openPreview(for: page)
            })
        } else if pageIsPublishedOrScheduled {
            openPreview(for: page)
        } else {
            openEditor(for: page)
        }
    }

    func openListView(for apost: AbstractPost) {
        closePreviewIfNeeded(for: apost)
        if let post = apost as? Post {
            WPTabBarController.sharedInstance().switchTabToPostsList(for: post)
        } else if let page = apost as? Page {
            WPTabBarController.sharedInstance().switchTabToPagesList(for: page)
        }
    }

    func openReader(for apost: AbstractPost, onFailure: () -> Void) {
        closePreviewIfNeeded(for: apost)
        guard let postID = apost.postID,
            postID.intValue > 0,
            let blogID = apost.blog.dotComID else {
                onFailure()
                return
        }
        WPTabBarController.sharedInstance().showReaderTab(forPost: postID, onBlog: blogID)
    }

    func openReader(for postID: NSNumber, siteID: NSNumber, onFailure: () -> Void) {
        closeAnyOpenPreview()
        guard postID.intValue > 0, siteID.intValue > 0 else {
            onFailure()
            return
        }
        WPTabBarController.sharedInstance().showReaderTab(forPost: postID, onBlog: siteID)
    }

    // MARK: - Editor

    func openEditor(for post: Post) {
        closePreviewIfNeeded(for: post)
        openListView(for: post)
        let editor = EditPostViewController.init(post: post)
        editor.modalPresentationStyle = .fullScreen
        WPTabBarController.sharedInstance().present(editor, animated: true)
    }

    func openEditor(for page: Page) {
        closePreviewIfNeeded(for: page)
        openListView(for: page)
        let editorFactory = EditorFactory()

        let editor = editorFactory.instantiateEditor(
            for: page,
            replaceEditor: { [weak self] (editor, replacement) in
                self?.replaceEditor(editor: editor, replacement: replacement)
        })

        open(editor)
    }

    private func open(_ editor: EditorViewController) {
        editor.onClose = { [unowned editor] changesSaved, _ in
            editor.dismiss(animated: true)
        }

        let navController = UINavigationController(rootViewController: editor)
        navController.restorationIdentifier = Restorer.Identifier.navigationController.rawValue
        navController.modalPresentationStyle = .fullScreen
        WPTabBarController.sharedInstance().present(navController, animated: true)
    }

    func replaceEditor(editor: EditorViewController, replacement: EditorViewController) {
        editor.dismiss(animated: true) { [weak self] in
            self?.open(replacement)
        }
    }

    // MARK: - Preview

    func openPreview(for apost: AbstractPost) {
        WPTabBarController.sharedInstance().showMySitesTab()
        closePreviewIfNeeded(for: apost)
        let controller = PostPreviewViewController(post: apost)
        controller.hidesBottomBarWhenPushed = true
        let navWrapper = UINavigationController(rootViewController: controller)
        controller.onClose = {
            navWrapper.dismiss(animated: true) {}
        }
        WPTabBarController.sharedInstance().present(navWrapper, animated: true)
        openListView(for: apost)
    }

    /// If there is a PostPreviewViewController window open and it is already displaying the provided
    /// AbstractPost, leave it open, otherwise close it.
    ///
    func closePreviewIfNeeded(for apost: AbstractPost) {
        guard let navController = WPTabBarController.sharedInstance().presentedViewController as? UINavigationController,
            let previewVC = navController.topViewController as? PostPreviewViewController,
            previewVC.apost != apost else {
                // Do nothing — post is already loaded or PostPreviewViewController isn't visible
                return
        }
        navController.dismiss(animated: true)
    }

    /// If there is any PostPreviewViewController window open, close it.
    ///
    func closeAnyOpenPreview() {
        guard let navController = WPTabBarController.sharedInstance().presentedViewController as? UINavigationController,
            let _ = navController.topViewController as? PostPreviewViewController else {
                return
        }
        navController.dismiss(animated: true)
    }
}
