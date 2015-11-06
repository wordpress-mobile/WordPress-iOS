import Foundation


public class BlogSettings : NSManagedObject
{
    @NSManaged var blog                                 : Blog
    @NSManaged var blogID                               : NSNumber!
    
    // MARK: - Discussion
    @NSManaged var commentsAllowed                      : Bool
    @NSManaged var commentsCloseAutomatically           : Bool
    @NSManaged var commentsCloseAutomaticallyAfterDays  : Int

    @NSManaged var commentsPagingEnabled                : Bool
    @NSManaged var commentsPageSize                     : Int
    
    @NSManaged var commentsRequireManualModeration      : Bool
    @NSManaged var commentsRequireNameAndEmail          : Bool
    @NSManaged var commentsRequireRegistration          : Bool
    
    @NSManaged var commentsSortOrder                    : Int
    
    @NSManaged var commentsThreadingEnabled             : Bool
    @NSManaged var commentsThreadingDepth               : Int

    @NSManaged var pingbacksOutboundEnabled             : Bool
    @NSManaged var pingbacksInboundEnabled              : Bool

    // MARK: - Related Posts
    @NSManaged var relatedPostsAllowed                  : Bool
    @NSManaged var relatedPostsEnabled                  : Bool
    @NSManaged var relatedPostsShowHeadline             : Bool
    @NSManaged var relatedPostsShowThumbnails           : Bool
}
