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
    func indexItem(_ item: SearchableItemConvertable) {
        indexItems([item])
    }

    /// Index items to the on-device index
    ///
    /// - Parameters:
    ///   - items: the items to be indexed
    ///
    func indexItems(_ items: [SearchableItemConvertable]) {
        let items = items.map({ $0.indexableItem() }).flatMap({ $0 })
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
    func deleteSearchableItem(_ item: SearchableItemConvertable) {
        deleteSearchableItems([item])
    }

    /// Remove items from the on-device index
    ///
    /// - Parameters:
    ///   - items: items to remove
    ///
    func deleteSearchableItems(_ items: [SearchableItemConvertable]) {
        let ids = items.map({ $0.uniqueIdentifier }).flatMap({ $0 })
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
    func deleteAllSearchableItemsFromDomain(_ domain: String) {
        deleteAllSearchableItemsFromDomains([domain])
    }

    /// Removes all items with the given domain identifiers from the on-device index
    ///
    /// - Parameters:
    ///   - domains: the domain identifiers
    ///
    func deleteAllSearchableItemsFromDomains(_ domains: [String]) {
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

    /// Removes *all* items from the on-device index.
    ///
    /// Note: Be careful, this clears the entire index!
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

    /// Handle a NSUserAcitivity
    ///
    /// - Parameter activity: NSUserActivity that opened the app
    /// - Returns: true if it was handled correctly and activitytype was `CSSearchableItemActionType`, otherwise false
    ///
    @discardableResult
    @objc static func handle(activity: NSUserActivity?) -> Bool {
        guard activity?.activityType == CSSearchableItemActionType,
            let compositeIdentifier = activity?.userInfo?[CSSearchableItemActivityIdentifier] as? String else {
                return false
        }

        let (domainString, identifier) = SearchIdentifierGenerator.decomposeFromUniqueIdentifier(compositeIdentifier)
        let siteID = NumberFormatter().number(from: domainString)
        guard let postID = NumberFormatter().number(from: identifier) else {
            DDLogError("Search manager unable to open post - postID:\(identifier) siteID:\(domainString)")
                return false
        }

        if let siteID = siteID {
            fetchPost(postID, blogID: siteID, onSuccess: { post in
                switchToPostListAndOpenEditorForPost(post)
            }, onFailure: {
                DDLogError("Search manager unable to open post - postID:\(postID) siteID:\(siteID)")
            })
        } else {
            fetchSelfHostedPost(postID, blogXMLRpcString: domainString, onSuccess: { post in
                switchToPostListAndOpenEditorForPost(post)
            }, onFailure: {
                DDLogError("Search manager unable to open self hosted post - postID:\(postID) xmlrpc:\(domainString)")
            })
        }
        return true
    }
}

// MARK: - Private Helpers

fileprivate extension SearchManager {
    static func fetchPost(_ postID: NSNumber,
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

    static func fetchSelfHostedPost(_ postID: NSNumber,
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

    static func switchToPostListAndOpenEditorForPost(_ apost: AbstractPost) {

        if let post = apost as? Post {
            WPTabBarController.sharedInstance().switchTabToPostsList(for: post)
            let editor = EditPostViewController.init(post: post)
            editor.modalPresentationStyle = .fullScreen
            WPTabBarController.sharedInstance().present(editor, animated: false, completion: nil)
        } else if let page = apost as? Page {
            WPTabBarController.sharedInstance().switchTabToPagesList(for: page)
        }
    }
}
