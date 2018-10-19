import CoreData
import WordPressShared

public extension Blog {
    /// Only WordPress.com hosted sites we administer may be managed
    ///
    /// - Returns: Whether site management is permitted
    ///
    @objc func supportsSiteManagementServices() -> Bool {
        return isHostedAtWPcom && isAdmin
    }
}

/// SiteManagementService handles operations for managing a WordPress.com site.
///
open class SiteManagementService: LocalCoreDataService {
    /// Deletes the specified WordPress.com site.
    ///
    /// - Parameters:
    ///     - blog: The Blog whose site to delete
    ///     - success: Optional success block with no parameters
    ///     - failure: Optional failure block with NSError
    ///
    @objc open func deleteSiteForBlog(_ blog: Blog, success: (() -> Void)?, failure: ((NSError) -> Void)?) {
        guard let remote = siteManagementServiceRemoteForBlog(blog) else {
            return
        }
        remote.deleteSite(blog.dotComID!,
            success: {
                self.managedObjectContext.perform {
                    let blogService = BlogService(managedObjectContext: self.managedObjectContext)
                    blogService.remove(blog)

                    ContextManager.sharedInstance().save(self.managedObjectContext, withCompletionBlock: {
                        success?()
                    })
                }
            },
            failure: { error in
                failure?(error)
            })
    }

    /// Triggers content export of the specified WordPress.com site.
    ///
    /// - Note: An email will be sent with download link when export completes.
    ///
    /// - Parameters:
    ///     - blog: The Blog whose content to export
    ///     - success: Optional success block with no parameters
    ///     - failure: Optional failure block with NSError
    ///
    @objc open func exportContentForBlog(_ blog: Blog, success: (() -> Void)?, failure: ((NSError) -> Void)?) {
        guard let remote = siteManagementServiceRemoteForBlog(blog) else {
            return
        }
        remote.exportContent(blog.dotComID!,
            success: {
                success?()
            },
            failure: { error in
                failure?(error)
            })
    }

    /// Gets the list of active purchases of the specified WordPress.com site.
    ///
    /// - Parameters:
    ///     - blog:    The Blog whose site to retrieve purchases for
    ///     - success: Optional success block with array of purchases (if any)
    ///     - failure: Optional failure block with NSError
    ///
    @objc open func getActivePurchasesForBlog(_ blog: Blog, success: (([SitePurchase]) -> Void)?, failure: ((NSError) -> Void)?) {
        guard let remote = siteManagementServiceRemoteForBlog(blog) else {
            return
        }
        remote.getActivePurchases(blog.dotComID!,
            success: { purchases in
                success?(purchases)
            },
            failure: { error in
                failure?(error)
            })
    }

    /// Trigger a masterbar notification celebrating completion of mobile quick start.
    ///
    /// - Parameters:
    ///   - blog: The Blog whose quick start checklist is completed
    ///   - completion: Optional completion block
    ///
    @objc open func markQuickStartChecklistAsComplete(for blog: Blog, completion: ((Bool, NSError?) -> Void)? = nil) {
        guard let remote = siteManagementServiceRemoteForBlog(blog),
            let blogId = blog.dotComID else {
                return
        }

        remote.markQuickStartChecklistAsComplete(blogId, success: {
            completion?(true, nil)
        }, failure: { error in
            completion?(false, error)
        })
    }

    /// Creates a remote service for site management
    ///
    /// - Note: Only WordPress.com API supports site management
    ///
    /// - Parameter blog: The Blog currently at the site
    ///
    /// - Returns: Remote service for site management
    ///
    @objc func siteManagementServiceRemoteForBlog(_ blog: Blog) -> SiteManagementServiceRemote? {
        guard let api = blog.wordPressComRestApi() else {
            return nil
        }

        return SiteManagementServiceRemote(wordPressComRestApi: api)
    }
}
