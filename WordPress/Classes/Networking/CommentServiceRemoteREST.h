#import <Foundation/Foundation.h>
#import "CommentServiceRemote.h"
#import "SiteServiceRemoteREST.h"

@interface CommentServiceRemoteREST : SiteServiceRemoteREST <CommentServiceRemote>

/**
 Fetch a hierarchical list of comments for the specified post on the specified site.
 The comments are returned in the order of nesting, not date.
 The request fetches the default number of *parent* comments (20) but may return more
 depending on the number of child comments.

 @param postID The ID of the post.
 @param page The page number to fetch.
 @param number The number to fetch per page.
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)syncHierarchicalCommentsForPost:(NSNumber *)postID
                                   page:(NSUInteger)page
                                 number:(NSUInteger)number
                                success:(void (^)(NSArray *comments))success
                                failure:(void (^)(NSError *error))failure;

/**
 Update a comment with a commentID
 */
- (void)updateCommentWithID:(NSNumber *)commentID
                    content:(NSString *)content
                    success:(void (^)())success
                    failure:(void (^)(NSError *error))failure;

/**
 Adds a reply to a post with postID
 */
- (void)replyToPostWithID:(NSNumber *)postID
                  content:(NSString *)content
                  success:(void (^)(RemoteComment *comment))success
                  failure:(void (^)(NSError *error))failure;

/**
 Adds a reply to a comment with commentID
 */
- (void)replyToCommentWithID:(NSNumber *)commentID
                     content:(NSString *)content
                     success:(void (^)(RemoteComment *comment))success
                     failure:(void (^)(NSError *error))failure;

/**
 Moderate a comment with a commentID
 */
- (void)moderateCommentWithID:(NSNumber *)commentID
                       status:(NSString *)status
                      success:(void (^)())success
                      failure:(void (^)(NSError *error))failure;

/**
 Trashes a comment with a commentID
 */
- (void)trashCommentWithID:(NSNumber *)commentID
                   success:(void (^)())success
                   failure:(void (^)(NSError *error))failure;

/**
 Like a comment with a commentID
 */
- (void)likeCommentWithID:(NSNumber *)commentID
                  success:(void (^)())success
                  failure:(void (^)(NSError *error))failure;


/**
 Unlike a comment with a commentID
 */
- (void)unlikeCommentWithID:(NSNumber *)commentID
                    success:(void (^)())success
                    failure:(void (^)(NSError *error))failure;

@end
