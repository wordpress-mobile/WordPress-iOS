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

@end
