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

/// SiteManagementService handles deletion of a user's site.
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
        let remote = siteManagementServiceRemoteForBlog(blog)
        remote.deleteSite(blog.dotComID,
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
    
    /// Creates a remote service for site management
    ///
    /// - Note: Only WordPress.com API supports site management
    ///
    /// - Parameters:
    ///     - blog: The Blog currently at the site
    ///
    /// - Returns: Remote service for site management
    ///
    func siteManagementServiceRemoteForBlog(blog: Blog) -> SiteManagementServiceRemote {
        return SiteManagementServiceRemote(api: blog.restApi())
    }
}
