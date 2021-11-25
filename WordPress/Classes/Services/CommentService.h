#import <Foundation/Foundation.h>
#import "LocalCoreDataService.h"

@import WordPressKit;

extern NSUInteger const WPTopLevelHierarchicalCommentsPerPage;

@class Blog;
@class Comment;
@class ReaderPost;
@class BasePost;
@class RemoteUser;
@class CommentServiceRemoteFactory;

@interface CommentService : LocalCoreDataService

/// Initializes the instance with a custom service remote provider.
///
/// @param context The context this instance will use for interacting with CoreData.
/// @param commentServiceRemoteFactory The factory this instance will use to get service remote instances from.
- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)context
                 commentServiceRemoteFactory:(CommentServiceRemoteFactory *)remoteFactory NS_DESIGNATED_INITIALIZER;

+ (BOOL)isSyncingCommentsForBlog:(Blog *)blog;

// Create comment
- (Comment *)createCommentForBlog:(Blog *)blog;

// Create reply
- (Comment *)createReplyForComment:(Comment *)comment;

// Restore draft reply
- (Comment *)restoreReplyForComment:(Comment *)comment;

- (NSSet *)findCommentsWithPostID:(NSNumber *)postID inBlog:(Blog *)blog;

- (Comment *)findCommentWithID:(NSNumber *)commentID inBlog:(Blog *)blog;

// Sync comments
- (void)syncCommentsForBlog:(Blog *)blog
                    success:(void (^)(BOOL hasMore))success
                    failure:(void (^)(NSError *error))failure;

- (void)syncCommentsForBlog:(Blog *)blog
                 withStatus:(CommentStatusFilter)status
                    success:(void (^)(BOOL hasMore))success
                    failure:(void (^)(NSError *error))failure;

- (void)syncCommentsForBlog:(Blog *)blog
                 withStatus:(CommentStatusFilter)status
            filterUnreplied:(BOOL)filterUnreplied
                    success:(void (^)(BOOL hasMore))success
                    failure:(void (^)(NSError *error))failure;

// Determine if a recent cache is available
+ (BOOL)shouldRefreshCacheFor:(Blog *)blog;

// Load extra comments
- (void)loadMoreCommentsForBlog:(Blog *)blog
                        success:(void (^)(BOOL hasMore))success
                        failure:(void (^)(NSError *))failure;

- (void)loadMoreCommentsForBlog:(Blog *)blog
                     withStatus:(CommentStatusFilter)status
                        success:(void (^)(BOOL hasMore))success
                        failure:(void (^)(NSError *))failure;
    
// Upload comment
- (void)uploadComment:(Comment *)comment
              success:(void (^)(void))success
              failure:(void (^)(NSError *error))failure;

// Approve comment
- (void)approveComment:(Comment *)comment
               success:(void (^)(void))success
               failure:(void (^)(NSError *error))failure;

// Unapprove (Pending) comment
- (void)unapproveComment:(Comment *)comment
                 success:(void (^)(void))success
                 failure:(void (^)(NSError *error))failure;

// Spam comment
- (void)spamComment:(Comment *)comment
            success:(void (^)(void))success
            failure:(void (^)(NSError *error))failure;

// Trash comment
- (void)trashComment:(Comment *)comment
             success:(void (^)(void))success
             failure:(void (^)(NSError *error))failure;

// Delete comment
- (void)deleteComment:(Comment *)comment
              success:(void (^)(void))success
              failure:(void (^)(NSError *error))failure;

// Sync a list of comments sorted by hierarchy, fetched by page number.
- (void)syncHierarchicalCommentsForPost:(ReaderPost *)post
                                   page:(NSUInteger)page
                                success:(void (^)(BOOL hasMore, NSNumber *totalComments))success
                                failure:(void (^)(NSError *error))failure;

// Sync a list of comments sorted by hierarchy, restricted by the specified number of _top level_ comments.
// This method is intended to get a small number of comments.
// Therefore it is restricted to page 1 only.
- (void)syncHierarchicalCommentsForPost:(ReaderPost *)post
                       topLevelComments:(NSUInteger)number
                                success:(void (^)(BOOL hasMore, NSNumber *totalComments))success
                                failure:(void (^)(NSError *error))failure;

// Get the specified number of top level comments for the specified post.
// This method is intended to get a small number of comments.
// Therefore it is restricted to page 1 only.
- (NSArray *)topLevelComments:(NSUInteger)number forPost:(ReaderPost *)post;

// Counts and returns the number of full pages of hierarchcial comments synced for a post.
// A partial set does not count toward the total number of pages. 
- (NSInteger)numberOfHierarchicalPagesSyncedforPost:(ReaderPost *)post;


/**
    REST Helpers:
    =============
 
    Decoupled from the CoreData Model, the main goal of the following helpers is to
    to allow Comment Interaction in scenarios in which the Comment / Blog instances may not be available.
*/

// Edit comment
- (void)updateCommentWithID:(NSNumber *)commentID
                     siteID:(NSNumber *)siteID
                    content:(NSString *)content
                    success:(void (^)(void))success
                    failure:(void (^)(NSError *error))failure;

// Replies
- (void)replyToPost:(ReaderPost *)post
            content:(NSString *)content
            success:(void (^)(void))success
            failure:(void (^)(NSError *error))failure;

- (void)replyToHierarchicalCommentWithID:(NSNumber *)commentID
                                  post:(ReaderPost *)post
                                 content:(NSString *)content
                                 success:(void (^)(void))success
                                 failure:(void (^)(NSError *error))failure;

- (void)replyToCommentWithID:(NSNumber *)commentID
                      siteID:(NSNumber *)siteID
                     content:(NSString *)content
                     success:(void (^)(void))success
                     failure:(void (^)(NSError *error))failure;

// Like comment
- (void)likeCommentWithID:(NSNumber *)commentID
                   siteID:(NSNumber *)siteID
                  success:(void (^)(void))success
                  failure:(void (^)(NSError *error))failure;

// Unlike comment
- (void)unlikeCommentWithID:(NSNumber *)commentID
                     siteID:(NSNumber *)siteID
                    success:(void (^)(void))success
                    failure:(void (^)(NSError *error))failure;

// Approve comment
- (void)approveCommentWithID:(NSNumber *)commentID
                      siteID:(NSNumber *)siteID
                     success:(void (^)(void))success
                     failure:(void (^)(NSError *error))failure;

// Unapprove comment
- (void)unapproveCommentWithID:(NSNumber *)commentID
                        siteID:(NSNumber *)siteID
                       success:(void (^)(void))success
                       failure:(void (^)(NSError *error))failure;

// Spam comment
- (void)spamCommentWithID:(NSNumber *)commentID
                   siteID:(NSNumber *)siteID
                  success:(void (^)(void))success
                  failure:(void (^)(NSError *error))failure;

// Delete comment
- (void)deleteCommentWithID:(NSNumber *)commentID
                     siteID:(NSNumber *)siteID
                    success:(void (^)(void))success
                    failure:(void (^)(NSError *error))failure;

/**
 This method will toggle the like status for a comment and optimistically save it. It will also
 trigger either likeCommentWithID or unlikeCommentWithID. In case the request fails, like status
 will be reverted back.

 @param siteID is used since the blog might be nil for comment. It's not optional!
 */
- (void)toggleLikeStatusForComment:(Comment *)comment
                            siteID:(NSNumber *)siteID
                           success:(void (^)(void))success
                           failure:(void (^)(NSError *error))failure;

/**
 Get a CommentServiceRemoteREST for the given site.
 This is public so it can be accessed from Swift extensions.
 
 @param siteID The ID of the site the remote will be used for.
 */
- (CommentServiceRemoteREST *_Nullable)restRemoteForSite:(NSNumber *_Nonnull)siteID;


@end
