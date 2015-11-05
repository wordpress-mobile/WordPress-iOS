import Foundation


public class BlogSettings : NSManagedObject
{
    @NSManaged var blog                                 : Blog
    
    @NSManaged var commentsAllowed                      : Bool
    @NSManaged var commentsCloseAutomatically           : Bool
    @NSManaged var commentsCloseAutomaticallyAfterDays  : Bool

    @NSManaged var commentsPageSize                     : Int
    @NSManaged var commentsPagingEnabled                : Bool
    
    @NSManaged var commentsRequireManualModeration      : Bool
    @NSManaged var commentsRequireRegistration          : Bool
    
    @NSManaged var commentsSortOrder                    : Int
    
    @NSManaged var commentsThreadingEnabled             : Bool
    @NSManaged var commentsThreadingDepth               : Int

    @NSManaged var pingbacksOutboundEnabled             : Bool
    @NSManaged var pingbacksInboundEnabled              : Bool
    
    @NSManaged var relatedPostsAllowed                  : Bool
    @NSManaged var relatedPostsEnabled                  : Bool
    @NSManaged var relatedPostsShowHeadline             : Bool
    @NSManaged var relatedPostsShowThumbnails           : Bool
}
