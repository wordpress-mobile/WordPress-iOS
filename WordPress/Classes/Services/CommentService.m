#import "CommentService.h"
#import "Blog.h"
#import "Comment.h"
#import "ContextManager.h"

@interface CommentService ()

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end

@implementation CommentService

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context {
    self = [super init];
    if (self) {
        _managedObjectContext = context;
    }

    return self;
}

// Create comment
- (Comment *)createCommentForBlog:(Blog *)blog {
    Comment *comment = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([Comment class]) inManagedObjectContext:blog.managedObjectContext];
    comment.blog = blog;
    return comment;
}

// Create reply
- (Comment *)createReplyForComment:(Comment *)comment {
    Comment *reply = [self createCommentForBlog:comment.blog];
    reply.postID = comment.postID;
    reply.post = comment.post;
    reply.parentID = comment.commentID;
    reply.status = CommentStatusApproved;
    return reply;
}

// Restore draft reply
- (Comment *)restoreReplyForComment:(Comment *)comment {
    NSFetchRequest *existingReply = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Comment class])];
    existingReply.predicate = [NSPredicate predicateWithFormat:@"status == %@ AND parentID == %@", CommentStatusDraft, comment.commentID];
    existingReply.fetchLimit = 1;

    Comment *reply = nil;
    NSError *error;
    NSArray *replies = [self.managedObjectContext executeFetchRequest:existingReply error:&error];
    if (error) {
        DDLogError(@"Failed to fetch reply: %@", error);
    }
    if ([replies count] > 0) {
        reply = [replies objectAtIndex:0];
    }

    if (!reply) {
        reply = [self createReplyForComment:comment];
    }

    reply.status = CommentStatusDraft;

    return reply;

}

@end
