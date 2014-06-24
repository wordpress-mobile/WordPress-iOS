#import <Foundation/Foundation.h>
#import "LocalCoreDataService.h"

@class Blog, Comment;

@interface CommentService : NSObject <LocalCoreDataService>

// Create comment
- (Comment *)createCommentForBlog:(Blog *)blog;

// Create reply
- (Comment *)createReplyForComment:(Comment *)comment;

// Restore draft reply
- (Comment *)restoreReplyForComment:(Comment *)comment;

// Sync comments
- (void)syncCommentsForBlog:(Blog *)blog
                    success:(void (^)())success
                    failure:(void (^)(NSError *error))failure;

// Upload comment
- (void)uploadComment:(Comment *)comment
              success:(void (^)())success
              failure:(void (^)(NSError *error))failure;

// Approve
- (void)approveComment:(Comment *)comment
               success:(void (^)())success
               failure:(void (^)(NSError *error))failure;

// Unapprove
- (void)unapproveComment:(Comment *)comment
                 success:(void (^)())success
                 failure:(void (^)(NSError *error))failure;

// Spam
- (void)spamComment:(Comment *)comment
            success:(void (^)())success
            failure:(void (^)(NSError *error))failure;

// Trash comment
- (void)deleteComment:(Comment *)comment
              success:(void (^)())success
              failure:(void (^)(NSError *error))failure;

@end
