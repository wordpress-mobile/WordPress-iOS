#import <Foundation/Foundation.h>
#import "CommentServiceRemote.h"
#import "ServiceRemoteREST.h"

@interface CommentServiceRemoteREST : NSObject <CommentServiceRemote, ServiceRemoteREST>

/**
 Fetch a hierarchical list of comments for the specified post on the specified site.
 The comments are returned in the order of nesting, not date.
 The request fetches the default number of *parent* comments (20) but may return more
 depending on the number of child comments.

 @param postID The ID of the post.
 @param siteID The ID of the origin site.
 @param page The page number to fetch.
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)syncHierarchicalCommentsForPost:(NSNumber *)postID
                               fromSite:(NSNumber *)siteID
                                   page:(NSUInteger)page
                                success:(void (^)(NSArray *comments))success
                                failure:(void (^)(NSError *error))failure;
@end
