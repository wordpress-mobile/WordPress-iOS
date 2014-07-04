#import "CommentService.h"
#import "Blog.h"
#import "Comment.h"
#import "CommentServiceRemote.h"
#import "CommentServiceRemoteXMLRPC.h"
#import "CommentServiceRemoteREST.h"
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

    NSError *error;
    NSArray *replies = [self.managedObjectContext executeFetchRequest:existingReply error:&error];
    if (error) {
        DDLogError(@"Failed to fetch reply: %@", error);
    }

    Comment *reply = [replies firstObject];
    if (!reply) {
        reply = [self createReplyForComment:comment];
    }

    reply.status = CommentStatusDraft;

    return reply;

}

// Sync comments
- (void)syncCommentsForBlog:(Blog *)blog
                    success:(void (^)())success
                    failure:(void (^)(NSError *error))failure {
    id<CommentServiceRemote> remote = [self remoteForBlog:blog];
    [remote getCommentsForBlog:blog
                       success:^(NSArray *comments) {
                           [self.managedObjectContext performBlock:^{
                               [self mergeComments:comments forBlog:blog completionHandler:success];
                           }];
                       } failure:^(NSError *error) {
                           if (failure) {
                               [self.managedObjectContext performBlock:^{
                                   failure(error);
                               }];
                           }
                       }];
}

// Load a comment

- (void)loadCommentWithID:(NSNumber *)commentID
                 fromBlog:(Blog *)blog
                  success:(void (^)(Comment *comment))success
                  failure:(void (^)(NSError *error))failure {
    
    void (^successBlock)(RemoteComment *remoteComment) = ^(RemoteComment *remoteComment) {
        [self.managedObjectContext performBlock:^{
            Comment *comment = [self findCommentWithID:commentID inBlog:blog];
            if (!comment) {
                comment = [self createCommentForBlog:blog];
            }
            [self updateComment:comment withRemoteComment:remoteComment];
            
            [[ContextManager sharedInstance] saveDerivedContext:self.managedObjectContext];
            
            if (success) {
                dispatch_async(dispatch_get_main_queue(), ^(){
                    success(comment);
                });
            }
        }];
    };
    
    id<CommentServiceRemote> remote = [self remoteForBlog:blog];
    [remote getCommentWithID:commentID forBlog:blog success:successBlock failure:failure];
}

// Upload comment
- (void)uploadComment:(Comment *)comment
              success:(void (^)())success
              failure:(void (^)(NSError *error))failure {
    id<CommentServiceRemote> remote = [self remoteForBlog:comment.blog];
    RemoteComment *remoteComment = [self remoteCommentWithComment:comment];

    NSManagedObjectID *commentObjectID = comment.objectID;
    void (^successBlock)(RemoteComment *comment) = ^(RemoteComment *comment) {
        [self.managedObjectContext performBlock:^{
            Comment *commentInContext = (Comment *)[self.managedObjectContext existingObjectWithID:commentObjectID error:nil];
            if (commentInContext) {
                [self updateComment:commentInContext withRemoteComment:comment];
            }
            [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
            if (success) {
                success();
            }
        }];
    };

    if (comment.commentID) {
        [remote updateComment:remoteComment
                      forBlog:comment.blog
                      success:successBlock
                      failure:failure];
    } else {
        [remote createComment:remoteComment
                      forBlog:comment.blog
                      success:successBlock
                      failure:failure];
    }
}

// Approve
- (void)approveComment:(Comment *)comment
               success:(void (^)())success
               failure:(void (^)(NSError *error))failure {
    [self moderateComment:comment
               withStatus:@"approve"
                  success:success
                  failure:failure];
}

// Unapprove
- (void)unapproveComment:(Comment *)comment
                 success:(void (^)())success
                 failure:(void (^)(NSError *error))failure {
    [self moderateComment:comment
               withStatus:@"hold"
                  success:success
                  failure:failure];
}

// Spam
- (void)spamComment:(Comment *)comment
            success:(void (^)())success
            failure:(void (^)(NSError *error))failure {
    [self moderateComment:comment
               withStatus:@"spam"
                  success:^{
                      [self.managedObjectContext deleteObject:comment];
                      [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
                      if (success) {
                          success();
                      }
                  } failure:failure];
}

// Delete comment
- (void)deleteComment:(Comment *)comment
              success:(void (^)())success
              failure:(void (^)(NSError *error))failure {
    NSNumber *commentID = comment.commentID;
    if (commentID) {
        RemoteComment *remoteComment = [self remoteCommentWithComment:comment];
        id<CommentServiceRemote> remote = [self remoteForBlog:comment.blog];
        [remote trashComment:remoteComment forBlog:comment.blog success:success failure:failure];
    }
    [self.managedObjectContext deleteObject:comment];
    [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
}

#pragma mark - Private methods

// Generic moderation
- (void)moderateComment:(Comment *)comment
             withStatus:(NSString *)status
                success:(void (^)())success
                failure:(void (^)(NSError *error))failure {
	NSString *prevStatus = comment.status;
	if ([prevStatus isEqualToString:status]) {
        if (success) {
            success();
        }
        return;
    }

	comment.status = status;
    [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
    id <CommentServiceRemote> remote = [self remoteForBlog:comment.blog];
    RemoteComment *remoteComment = [self remoteCommentWithComment:comment];
    [remote moderateComment:remoteComment
                    forBlog:comment.blog success:^(RemoteComment *comment) {
                        if (success) {
                            success();
                        }
                    } failure:^(NSError *error) {
                        [self.managedObjectContext performBlock:^{
                            comment.status = prevStatus;
                            [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
                            if (failure) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    failure(error);
                                });
                            }
                        }];
                    }];
}

- (void)mergeComments:(NSArray *)comments forBlog:(Blog *)blog completionHandler:(void (^)(void))completion {
    NSMutableArray *commentsToKeep = [NSMutableArray array];
    for (RemoteComment *remoteComment in comments) {
        Comment *comment = [self findCommentWithID:remoteComment.commentID inBlog:blog];
        if (!comment) {
            comment = [self createCommentForBlog:blog];
        }
        [self updateComment:comment withRemoteComment:remoteComment];
        [commentsToKeep addObject:comment];
    }

    NSSet *existingComments = blog.comments;
    if (existingComments.count > 0) {
        for (Comment *comment in existingComments) {
            // Don't delete unpublished comments
            if(![commentsToKeep containsObject:comment] && comment.commentID != nil) {
                DDLogInfo(@"Deleting Comment: %@", comment);
                [self.managedObjectContext deleteObject:comment];
            }
        }
    }

    [[ContextManager sharedInstance] saveDerivedContext:self.managedObjectContext];

    if (completion) {
        dispatch_async(dispatch_get_main_queue(), completion);
    }
}

- (Comment *)findCommentWithID:(NSNumber *)commentID inBlog:(Blog *)blog {
    NSSet *comments = [blog.comments filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"commentID = %@", commentID]];
    return [comments anyObject];
}

- (void)updateComment:(Comment *)comment withRemoteComment:(RemoteComment *)remoteComment {
    comment.commentID = remoteComment.commentID;
    comment.author = remoteComment.author;
    comment.author_email = remoteComment.authorEmail;
    comment.author_url = remoteComment.authorUrl;
    comment.content = remoteComment.content;
    comment.dateCreated = remoteComment.date;
    comment.link = remoteComment.link;
    comment.parentID = remoteComment.parentID;
    comment.postID = remoteComment.postID;
    comment.postTitle = remoteComment.postTitle;
    comment.status = remoteComment.status;
    comment.type = remoteComment.type;
}

- (RemoteComment *)remoteCommentWithComment:(Comment *)comment {
    RemoteComment *remoteComment = [RemoteComment new];
    remoteComment.commentID = comment.commentID;
    remoteComment.author = comment.author;
    remoteComment.authorEmail = comment.author_email;
    remoteComment.authorUrl = comment.author_url;
    remoteComment.content = comment.content;
    remoteComment.date = comment.dateCreated;
    remoteComment.link = comment.link;
    remoteComment.parentID = comment.parentID;
    remoteComment.postID = comment.postID;
    remoteComment.postTitle = comment.postTitle;
    remoteComment.status = comment.status;
    remoteComment.type = comment.type;
    return remoteComment;
}

- (id<CommentServiceRemote>)remoteForBlog:(Blog *)blog {
    id<CommentServiceRemote>remote;
    // TODO: refactor API creation so it's not part of the model
    if (blog.restApi) {
        remote = [[CommentServiceRemoteREST alloc] initWithApi:blog.restApi];
    } else {
        WPXMLRPCClient *client = [WPXMLRPCClient clientWithXMLRPCEndpoint:[NSURL URLWithString:blog.xmlrpc]];
        remote = [[CommentServiceRemoteXMLRPC alloc] initWithApi:client];
    }
    return remote;
}

@end
