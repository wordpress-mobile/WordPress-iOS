import CoreData
import WordPressComAnalytics

public extension Blog
{
    /// Only WordPress.com hosted sites we administer may be deleted
    func supportsDeleteSiteServices() -> Bool {
        return isHostedAtWPcom && isAdmin
    }
}

/// DeleteSiteService handles deletion of a user's site.

public class DeleteSiteService : LocalCoreDataService
{
    /**
     Deletes the WordPress.com site for the specified Blog.
     
     - parameter blog:    The Blog whose site to delete
     - parameter success: Optional success block with no parameters
     - parameter failure: Optional failure block with NSError parameter
     */
    public func deleteSiteForBlog(blog: Blog, success: (() -> Void)?, failure: (NSError -> Void)?) {
        let blogObjectID = blog.objectID
        let remote = deleteSiteServiceRemoteForBlog(blog)
        remote.deleteSite(blog.dotComID,
            success: {
                self.removeBlogWithObjectID(blogObjectID, success: success)
            },
            failure: { error in
                failure?(error)
            })
    }
    
    /**
     Removes Blog with the specified ID from Core Data.
     
     - parameter objectID: Core Data ID of the Blog to remove
     - parameter success:  Optional success block with no parameters
     */
    public func removeBlogWithObjectID(objectID: NSManagedObjectID, success: (() -> Void)?) {
        managedObjectContext.performBlock {
            guard let blog = (try? self.managedObjectContext.existingObjectWithID(objectID)) as? Blog else {
                DDLogSwift.logError("Error fetching Blog after site deletion")
                success?()
                return
            }
            
            let jetpackAccount = blog.jetpackAccount
            
            self.managedObjectContext.deleteObject(blog)
            self.managedObjectContext.processPendingChanges()
            
            if let purgeableAccount = jetpackAccount {
                let accountService = AccountService(managedObjectContext: self.managedObjectContext)
                accountService.purgeAccount(purgeableAccount)
            }
            
            ContextManager.sharedInstance().saveContext(self.managedObjectContext, withCompletionBlock: {
                WPAnalytics.refreshMetadata()
                success?()
            })
        }
    }
    
    /// Only WordPress.com API supports delete site
    func deleteSiteServiceRemoteForBlog(blog: Blog) -> DeleteSiteServiceRemote {
        return DeleteSiteServiceRemote(api: blog.restApi())
    }
}
