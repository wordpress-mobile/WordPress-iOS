#import <Foundation/Foundation.h>
#import <WordPressKit/CommentServiceRemote.h>
#import <WordPressKit/SiteServiceRemoteWordPressComREST.h>

@class RemoteUser;
@class RemoteLikeUser;

@interface CommentServiceRemoteREST : SiteServiceRemoteWordPressComREST <CommentServiceRemote>

/**
 Fetch a hierarchical list of comments for the specified post on the specified site.
 The comments are returned in the order of nesting, not date.
 The request fetches the default number of *parent* comments (20) but may return more
 depending on the number of child comments.

 @param postID The ID of the post.
 @param page The page number to fetch.
 @param number The number to fetch per page.
 @param success block called on a successful fetch. Returns the comments array and total comments count.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)syncHierarchicalCommentsForPost:(NSNumber * _Nonnull)postID
                                   page:(NSUInteger)page
                                 number:(NSUInteger)number
                                success:(void (^ _Nullable)(NSArray * _Nullable comments, NSNumber * _Nonnull found))success
                                failure:(void (^ _Nullable)(NSError * _Nullable error))failure;

/**
 Update a comment with a commentID
 */
- (void)updateCommentWithID:(NSNumber * _Nonnull)commentID
                    content:(NSString * _Nonnull)content
                    success:(void (^ _Nullable)(void))success
                    failure:(void (^ _Nullable)(NSError * _Nullable error))failure;

/**
 Adds a reply to a post with postID
 */
- (void)replyToPostWithID:(NSNumber * _Nonnull)postID
                  content:(NSString * _Nonnull)content
                  success:(void (^ _Nullable)(RemoteComment * _Nullable comment))success
                  failure:(void (^ _Nullable)(NSError * _Nullable error))failure;

/**
 Adds a reply to a comment with commentID.
 */
- (void)replyToCommentWithID:(NSNumber * _Nonnull)commentID
                     content:(NSString * _Nonnull)content
                     success:(void (^ _Nullable)(RemoteComment * _Nullable comment))success
                     failure:(void (^ _Nullable)(NSError * _Nullable error))failure;

/**
 Moderate a comment with a commentID
 */
- (void)moderateCommentWithID:(NSNumber * _Nonnull)commentID
                       status:(NSString * _Nonnull)status
                      success:(void (^ _Nullable)(void))success
                      failure:(void (^ _Nullable)(NSError * _Nullable error))failure;

/**
 Trashes a comment with a commentID
 */
- (void)trashCommentWithID:(NSNumber * _Nonnull)commentID
                   success:(void (^ _Nullable)(void))success
                   failure:(void (^ _Nullable)(NSError * _Nullable error))failure;

/**
 Like a comment with a commentID
 */
- (void)likeCommentWithID:(NSNumber * _Nonnull)commentID
                  success:(void (^ _Nullable)(void))success
                  failure:(void (^ _Nullable)(NSError * _Nullable error))failure;


/**
 Unlike a comment with a commentID
 */
- (void)unlikeCommentWithID:(NSNumber * _Nonnull)commentID
                    success:(void (^ _Nullable)(void))success
                    failure:(void (^ _Nullable)(NSError * _Nullable error))failure;

/**
 Requests a list of users that liked the comment with the specified ID. Due to
 API limitation, up to 90 users will be returned from the endpoint.
 
 @param commentID       The ID for the comment. Cannot be nil.
 @param count           Number of records to retrieve. Cannot be nil. If 0, will default to endpoint max.
 @param before          Filter results to Likes before this date/time string. Can be nil.
 @param excludeUserIDs  Array of user IDs to exclude from response. Can be nil.
 @param success         The block that will be executed on success. Can be nil.
 @param failure         The block that will be executed on failure. Can be nil.
 */
- (void)getLikesForCommentID:(NSNumber * _Nonnull)commentID
                       count:(NSNumber * _Nonnull)count
                      before:(NSString * _Nullable)before
              excludeUserIDs:(NSArray<NSNumber *> * _Nullable)excludeUserIDs
                     success:(void (^ _Nullable)(NSArray<RemoteLikeUser *> * _Nonnull users, NSNumber * _Nonnull found))success
                     failure:(void (^ _Nullable)(NSError * _Nullable))failure;

@end
