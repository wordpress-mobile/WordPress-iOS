import Foundation


public class RemoteBlogSettings : NSObject
{
    // MARK: - General
    var name                                : String!
    var tagline                             : String!
    var privacy                             : NSNumber!

    // MARK: - Writing
    var defaultCategory                     : NSNumber!
    var defaultPostFormat                   : String!

    // MARK: - Discussion
    var commentsAllowed                     : NSNumber!
    var commentsCloseAutomatically          : NSNumber!
    var commentsCloseAutomaticallyAfterDays : NSNumber!
    
    var commentsPagingEnabled               : NSNumber!
    var commentsPageSize                    : NSNumber!
    
    var commentsRequireManualModeration     : NSNumber!
    var commentsRequireNameAndEmail         : NSNumber!
    var commentsRequireRegistration         : NSNumber!
    
    var commentsSortOrder                   : String!
    
    var commentsThreadingEnabled            : NSNumber!
    var commentsThreadingDepth              : NSNumber!
    
    var pingbacksOutboundEnabled            : NSNumber!
    var pingbacksInboundEnabled             : NSNumber!
    
    // MARK: - Related Posts
    var relatedPostsAllowed                 : NSNumber!
    var relatedPostsEnabled                 : NSNumber!
    var relatedPostsShowHeadline            : NSNumber!
    var relatedPostsShowThumbnails          : NSNumber!
}
