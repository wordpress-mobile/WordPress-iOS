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
        let blogObjectID = blog.objectID
        let remote = siteManagementServiceRemoteForBlog(blog)
        remote.deleteSite(blog.dotComID,
            success: {
                self.removeBlogWithObjectID(blogObjectID, success: success, failure: failure)
            },
            failure: { error in
                failure?(error)
            })
    }
    
    /// Removes Blog with the specified ID from Core Data.
    ///
    /// - Parameters:
    ///     - objectID: Core Data ID of the Blog to remove
    ///     - success:  Optional success block with no parameters
    ///     - failure:  Optional failure block with NSError
    ///
    public func removeBlogWithObjectID(objectID: NSManagedObjectID, success: (() -> Void)?, failure: (NSError -> Void)?) {
        managedObjectContext.performBlock {
            do {
                let blog = try self.managedObjectContext.existingObjectWithID(objectID) as! Blog
                
                let jetpackAccount = blog.jetpackAccount
                
                self.managedObjectContext.deleteObject(blog)
                self.managedObjectContext.processPendingChanges()
                
                if let purgeableAccount = jetpackAccount {
                    let accountService = AccountService(managedObjectContext: self.managedObjectContext)
                    accountService.purgeAccount(purgeableAccount)
                }
            } catch let error as NSError {
                DDLogSwift.logError(error.localizedDescription)
                failure?(error)
                return
            }
            
            ContextManager.sharedInstance().saveContext(self.managedObjectContext, withCompletionBlock: {
                WPAnalytics.refreshMetadata()
                success?()
            })
        }
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
