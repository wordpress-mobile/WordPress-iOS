#import <Foundation/Foundation.h>
#import "LocalCoreDataService.h"

extern NSUInteger const WPTopLevelHierarchicalCommentsPerPage;

@class Blog;
@class Comment;
@class ReaderPost;
@class BasePost;

@interface CommentService : LocalCoreDataService

+ (BOOL)isSyncingCommentsForBlog:(Blog *)blog;

// Create comment
- (Comment *)createCommentForBlog:(Blog *)blog;

// Create reply
- (Comment *)createReplyForComment:(Comment *)comment;

// Restore draft reply
- (Comment *)restoreReplyForComment:(Comment *)comment;

- (NSSet *)findCommentsWithPostID:(NSNumber *)postID inBlog:(Blog *)blog;

// Sync comments
- (void)syncCommentsForBlog:(Blog *)blog
                    success:(void (^)(BOOL hasMore))success
                    failure:(void (^)(NSError *error))failure;

// Load extra comments
- (void)loadMoreCommentsForBlog:(Blog *)blog
                        success:(void (^)(BOOL hasMore))success
                        failure:(void (^)(NSError *))failure;

// Upload comment
- (void)uploadComment:(Comment *)comment
              success:(void (^)())success
              failure:(void (^)(NSError *error))failure;

// Approve comment
- (void)approveComment:(Comment *)comment
               success:(void (^)())success
               failure:(void (^)(NSError *error))failure;

// Unapprove comment
- (void)unapproveComment:(Comment *)comment
                 success:(void (^)())success
                 failure:(void (^)(NSError *error))failure;

// Spam comment
- (void)spamComment:(Comment *)comment
            success:(void (^)())success
            failure:(void (^)(NSError *error))failure;

// Trash comment
- (void)deleteComment:(Comment *)comment
              success:(void (^)())success
              failure:(void (^)(NSError *error))failure;

// Sync a list of comments sorted by hierarchy
- (void)syncHierarchicalCommentsForPost:(ReaderPost *)post
                                   page:(NSUInteger)page
                                success:(void (^)(NSInteger count, BOOL hasMore))success
                                failure:(void (^)(NSError *error))failure;

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
                    success:(void (^)())success
                    failure:(void (^)(NSError *error))failure;

// Replies
- (void)replyToPostWithID:(NSNumber *)postID
                   siteID:(NSNumber *)siteID
                  content:(NSString *)content
                  success:(void (^)())success
                  failure:(void (^)(NSError *error))failure;

- (void)replyToHierarchicalCommentWithID:(NSNumber *)commentID
                                  postID:(NSNumber *)postID
                                  siteID:(NSNumber *)siteID
                                 content:(NSString *)content
                                 success:(void (^)())success
                                 failure:(void (^)(NSError *error))failure;

- (void)replyToCommentWithID:(NSNumber *)commentID
                      siteID:(NSNumber *)siteID
                     content:(NSString *)content
                     success:(void (^)())success
                     failure:(void (^)(NSError *error))failure;

// Like comment
- (void)likeCommentWithID:(NSNumber *)commentID
                   siteID:(NSNumber *)siteID
                  success:(void (^)())success
                  failure:(void (^)(NSError *error))failure;

// Unlike comment
- (void)unlikeCommentWithID:(NSNumber *)commentID
                     siteID:(NSNumber *)siteID
                    success:(void (^)())success
                    failure:(void (^)(NSError *error))failure;

// Approve comment
- (void)approveCommentWithID:(NSNumber *)commentID
                      siteID:(NSNumber *)siteID
                     success:(void (^)())success
                     failure:(void (^)(NSError *error))failure;

// Unapprove comment
- (void)unapproveCommentWithID:(NSNumber *)commentID
                        siteID:(NSNumber *)siteID
                       success:(void (^)())success
                       failure:(void (^)(NSError *error))failure;

// Spam comment
- (void)spamCommentWithID:(NSNumber *)commentID
                   siteID:(NSNumber *)siteID
                  success:(void (^)())success
                  failure:(void (^)(NSError *error))failure;

// Delete comment
- (void)deleteCommentWithID:(NSNumber *)commentID
                     siteID:(NSNumber *)siteID
                    success:(void (^)())success
                    failure:(void (^)(NSError *error))failure;

/**
 This method will toggle the like status for a comment and optimistically save it. It will also
 trigger either likeCommentWithID or unlikeCommentWithID. In case the request fails, like status
 will be reverted back.

 @param siteID is used since the blog might be nil for comment. It's not optional!
 */
- (void)toggleLikeStatusForComment:(Comment *)comment
                            siteID:(NSNumber *)siteID
                           success:(void (^)())success
                           failure:(void (^)(NSError *error))failure;

@end
