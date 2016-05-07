import CoreData
import WordPressComAnalytics

public extension Blog
{
    /// Only WordPress.com hosted sites we administer may be managed
    ///
    /// - Returns: Whether site management is permitted
    ///
    func supportsSiteManagementServices() -> Bool {
        return isHostedAtWPcom && isAdmin
    }
}

/// SiteManagementService handles operations for managing a WordPress.com site.
///
public class SiteManagementService : LocalCoreDataService
{
    /// Deletes the specified WordPress.com site.
    ///
    /// - Parameters:
    ///     - blog:    The Blog whose site to delete
    ///     - success: Optional success block with no parameters
    ///     - failure: Optional failure block with NSError
    ///
    public func deleteSiteForBlog(blog: Blog, success: (() -> Void)?, failure: (NSError -> Void)?) {
        guard let remote = siteManagementServiceRemoteForBlog(blog) else {
            return
        }
        
        guard let dotComID = blog.dotComID else {
            assertionFailure("Expected a dotComID.")
            return
        }
        
        remote.deleteSite(dotComID,
            success: {
                self.managedObjectContext.performBlock {
                    let blogService = BlogService(managedObjectContext: self.managedObjectContext)
                    blogService.removeBlog(blog)
                    
                    ContextManager.sharedInstance().saveContext(self.managedObjectContext, withCompletionBlock: {
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
    ///     - blog:    The Blog whose content to export
    ///     - success: Optional success block with no parameters
    ///     - failure: Optional failure block with NSError
    ///
    public func exportContentForBlog(blog: Blog, success: (() -> Void)?, failure: (NSError -> Void)?) {
        guard let remote = siteManagementServiceRemoteForBlog(blog) else {
            return
        }
        
        guard let dotComID = blog.dotComID else {
            assertionFailure("Expected a dotComID.")
            return
        }
        
        remote.exportContent(dotComID,
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
    public func getActivePurchasesForBlog(blog: Blog, success: (([SitePurchase]) -> Void)?, failure: (NSError -> Void)?) {
        guard let remote = siteManagementServiceRemoteForBlog(blog) else {
            return
        }
        
        guard let dotComID = blog.dotComID else {
            assertionFailure("Expected a dotComID.")
            return
        }
        
        remote.getActivePurchases(dotComID,
            success: { purchases in
                success?(purchases)
            },
            failure: { error in
                failure?(error)
            })
    }
    
    /// Creates a remote service for site management
    ///
    /// - Note: Only WordPress.com API supports site management
    ///
    /// - Parameters:
    ///     - blog: The Blog currently at the site
    ///
    /// - Returns: Remote service for site management
    ///
    func siteManagementServiceRemoteForBlog(blog: Blog) -> SiteManagementServiceRemote? {
        guard let api = blog.restApi() else {
            return nil
        }

        return SiteManagementServiceRemote(api: api)
    }
}
