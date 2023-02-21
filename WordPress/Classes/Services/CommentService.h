#import <Foundation/Foundation.h>
#import "CoreDataService.h"

NS_ASSUME_NONNULL_BEGIN

@import WordPressKit;

extern NSUInteger const WPTopLevelHierarchicalCommentsPerPage;

@class Blog;
@class Comment;
@class ReaderPost;
@class BasePost;
@class RemoteUser;
@class CommentServiceRemoteFactory;

@interface CommentService : CoreDataService

/// Initializes the instance with a custom service remote provider.
///
/// @param coreDataStack The `CoreDataStack` this instance will use for interacting with CoreData.
/// @param commentServiceRemoteFactory The factory this instance will use to get service remote instances from.
- (instancetype)initWithCoreDataStack:(id<CoreDataStack>)coreDataStack
          commentServiceRemoteFactory:(CommentServiceRemoteFactory *)remoteFactory NS_DESIGNATED_INITIALIZER;

// Create reply
- (void)createReplyForComment:(Comment *)comment content:(NSString *)content completion:(void (^)(Comment *reply))completion;

// Sync comments
- (void)syncCommentsForBlog:(Blog *)blog
                 withStatus:(CommentStatusFilter)status
                    success:(void (^ _Nullable)(BOOL hasMore))success
                    failure:(void (^ _Nullable)(NSError * _Nullable error))failure;

- (void)syncCommentsForBlog:(Blog *)blog
                 withStatus:(CommentStatusFilter)status
            filterUnreplied:(BOOL)filterUnreplied
                    success:(void (^ _Nullable)(BOOL hasMore))success
                    failure:(void (^ _Nullable)(NSError * _Nullable error))failure;

// Determine if a recent cache is available
+ (BOOL)shouldRefreshCacheFor:(Blog *)blog;

// Load extra comments
- (void)loadMoreCommentsForBlog:(Blog *)blog
                     withStatus:(CommentStatusFilter)status
                        success:(void (^ _Nullable)(BOOL hasMore))success
                        failure:(void (^ _Nullable)(NSError * _Nullable))failure;

// Load a single comment
- (void)loadCommentWithID:(NSNumber *_Nonnull)commentID
                  forBlog:(Blog *_Nonnull)blog
                  success:(void (^_Nullable)(Comment *_Nullable))success
                  failure:(void (^_Nullable)(NSError *_Nullable))failure;

- (void)loadCommentWithID:(NSNumber *_Nonnull)commentID
                  forPost:(ReaderPost *_Nonnull)post
                  success:(void (^_Nullable)(Comment *_Nullable))success
                  failure:(void (^_Nullable)(NSError *_Nullable))failure;

// Upload comment
- (void)uploadComment:(Comment *)comment
              success:(void (^ _Nullable)(void))success
              failure:(void (^ _Nullable)(NSError * _Nullable error))failure;

// Approve comment
- (void)approveComment:(Comment *)comment
               success:(void (^ _Nullable)(void))success
               failure:(void (^ _Nullable)(NSError * _Nullable error))failure;

// Unapprove (Pending) comment
- (void)unapproveComment:(Comment *)comment
                 success:(void (^ _Nullable)(void))success
                 failure:(void (^ _Nullable)(NSError * _Nullable error))failure;

// Spam comment
- (void)spamComment:(Comment *)comment
            success:(void (^ _Nullable)(void))success
            failure:(void (^ _Nullable)(NSError * _Nullable error))failure;

// Trash comment
- (void)trashComment:(Comment *)comment
             success:(void (^ _Nullable)(void))success
             failure:(void (^ _Nullable)(NSError * _Nullable error))failure;

// Delete comment
- (void)deleteComment:(Comment *)comment
              success:(void (^ _Nullable)(void))success
              failure:(void (^ _Nullable)(NSError * _Nullable error))failure;

// Sync a list of comments sorted by hierarchy, fetched by page number.
- (void)syncHierarchicalCommentsForPost:(ReaderPost *)post
                                   page:(NSUInteger)page
                                success:(void (^ _Nullable)(BOOL hasMore, NSNumber * _Nullable totalComments))success
                                failure:(void (^ _Nullable)(NSError * _Nullable error))failure;

// Sync a list of comments sorted by hierarchy, restricted by the specified number of _top level_ comments.
// This method is intended to get a small number of comments.
// Therefore it is restricted to page 1 only.
- (void)syncHierarchicalCommentsForPost:(ReaderPost *)post
                       topLevelComments:(NSUInteger)number
                                success:(void (^ _Nullable)(BOOL hasMore, NSNumber * _Nullable totalComments))success
                                failure:(void (^ _Nullable)(NSError * _Nullable error))failure;

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
                    success:(void (^ _Nullable)(void))success
                    failure:(void (^ _Nullable)(NSError * _Nullable error))failure;

// Replies
- (void)replyToPost:(ReaderPost *)post
            content:(NSString *)content
            success:(void (^ _Nullable)(void))success
            failure:(void (^ _Nullable)(NSError * _Nullable error))failure;

- (void)replyToHierarchicalCommentWithID:(NSNumber *)commentID
                                  post:(ReaderPost *)post
                                 content:(NSString *)content
                                 success:(void (^ _Nullable)(void))success
                                 failure:(void (^ _Nullable)(NSError * _Nullable error))failure;

- (void)replyToCommentWithID:(NSNumber *)commentID
                      siteID:(NSNumber *)siteID
                     content:(NSString *)content
                     success:(void (^ _Nullable)(void))success
                     failure:(void (^ _Nullable)(NSError * _Nullable error))failure;

// Like comment
- (void)likeCommentWithID:(NSNumber *)commentID
                   siteID:(NSNumber *)siteID
                  success:(void (^ _Nullable)(void))success
                  failure:(void (^ _Nullable)(NSError * _Nullable error))failure;

// Unlike comment
- (void)unlikeCommentWithID:(NSNumber *)commentID
                     siteID:(NSNumber *)siteID
                    success:(void (^ _Nullable)(void))success
                    failure:(void (^ _Nullable)(NSError * _Nullable error))failure;

// Approve comment
- (void)approveCommentWithID:(NSNumber *)commentID
                      siteID:(NSNumber *)siteID
                     success:(void (^ _Nullable)(void))success
                     failure:(void (^ _Nullable)(NSError * _Nullable error))failure;

// Unapprove comment
- (void)unapproveCommentWithID:(NSNumber *)commentID
                        siteID:(NSNumber *)siteID
                       success:(void (^ _Nullable)(void))success
                       failure:(void (^ _Nullable)(NSError * _Nullable error))failure;

// Spam comment
- (void)spamCommentWithID:(NSNumber *)commentID
                   siteID:(NSNumber *)siteID
                  success:(void (^ _Nullable)(void))success
                  failure:(void (^ _Nullable)(NSError * _Nullable error))failure;

// Delete comment
- (void)deleteCommentWithID:(NSNumber *)commentID
                     siteID:(NSNumber *)siteID
                    success:(void (^ _Nullable)(void))success
                    failure:(void (^ _Nullable)(NSError * _Nullable error))failure;

/**
 This method will toggle the like status for a comment and optimistically save it. It will also
 trigger either likeCommentWithID or unlikeCommentWithID. In case the request fails, like status
 will be reverted back.

 @param siteID is used since the blog might be nil for comment. It's not optional!
 */
- (void)toggleLikeStatusForComment:(Comment *)comment
                            siteID:(NSNumber *)siteID
                           success:(void (^ _Nullable)(void))success
                           failure:(void (^ _Nullable)(NSError * _Nullable error))failure;

/**
 Get a CommentServiceRemoteREST for the given site.
 This is public so it can be accessed from Swift extensions.
 
 @param siteID The ID of the site the remote will be used for.
 */
- (CommentServiceRemoteREST *_Nullable)restRemoteForSite:(NSNumber *_Nonnull)siteID;


@end

NS_ASSUME_NONNULL_END
