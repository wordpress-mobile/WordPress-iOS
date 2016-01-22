import CoreData
import WordPressComAnalytics

public extension Blog
{
    /// Only WordPress.com hosted sites we administer may be deleted
    ///
    /// - Returns: Whether this blog may be deleted
    ///
    func supportsDeleteSiteServices() -> Bool {
        return isHostedAtWPcom && isAdmin
    }
}

/// DeleteSiteService handles deletion of a user's site.
///
public class DeleteSiteService : LocalCoreDataService
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
        let remote = deleteSiteServiceRemoteForBlog(blog)
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
    
    /// Creates a remote service for site deletion
    ///
    /// - Note: Only WordPress.com API supports delete site
    ///
    /// - Parameters:
    ///     - blog: The Blog whose site to delete
    ///
    /// - Returns: Remote service for site deletion
    ///
    func deleteSiteServiceRemoteForBlog(blog: Blog) -> DeleteSiteServiceRemote {
        return DeleteSiteServiceRemote(api: blog.restApi())
    }
}
