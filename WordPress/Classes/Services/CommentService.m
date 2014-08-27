#import "CommentService.h"
#import "Blog.h"
#import "Comment.h"
#import "CommentServiceRemote.h"
#import "CommentServiceRemoteXMLRPC.h"
#import "CommentServiceRemoteREST.h"
#import "WPAccount.h"
#import "AccountService.h"
#import "ContextManager.h"
#import "WPAccount.h"
#import "AccountService.h"
#import "ReaderPost.h"

@interface CommentService ()

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end

@implementation CommentService

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context
{
    self = [super init];
    if (self) {
        _managedObjectContext = context;
    }

    return self;
}

#pragma mark Public methods

#pragma mark Blog-centric methods

// Create comment
- (Comment *)createCommentForBlog:(Blog *)blog
{
    Comment *comment = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([Comment class]) inManagedObjectContext:blog.managedObjectContext];
    comment.blog = blog;
    return comment;
}

// Create reply
- (Comment *)createReplyForComment:(Comment *)comment
{
    Comment *reply = [self createCommentForBlog:comment.blog];
    reply.postID = comment.postID;
    reply.post = comment.post;
    reply.parentID = comment.commentID;
    reply.status = CommentStatusApproved;
    return reply;
}

// Restore draft reply
- (Comment *)restoreReplyForComment:(Comment *)comment
{
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
                    failure:(void (^)(NSError *error))failure
{
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

// Upload comment
- (void)uploadComment:(Comment *)comment
              success:(void (^)())success
              failure:(void (^)(NSError *error))failure
{
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
               failure:(void (^)(NSError *error))failure
{
    [self moderateComment:comment
               withStatus:@"approve"
                  success:success
                  failure:failure];
}

// Unapprove
- (void)unapproveComment:(Comment *)comment
                 success:(void (^)())success
                 failure:(void (^)(NSError *error))failure
{
    [self moderateComment:comment
               withStatus:@"hold"
                  success:success
                  failure:failure];
}

// Spam
- (void)spamComment:(Comment *)comment
            success:(void (^)())success
            failure:(void (^)(NSError *error))failure
{
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
              failure:(void (^)(NSError *error))failure
{
    NSNumber *commentID = comment.commentID;
    if (commentID) {
        RemoteComment *remoteComment = [self remoteCommentWithComment:comment];
        id<CommentServiceRemote> remote = [self remoteForBlog:comment.blog];
        [remote trashComment:remoteComment forBlog:comment.blog success:success failure:failure];
    }
    [self.managedObjectContext deleteObject:comment];
    [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
}


#pragma mark - Post-centric methods

- (void)syncHierarchicalCommentsForPost:(ReaderPost *)post
                                   page:(NSUInteger)page
                                success:(void (^)(NSInteger count))success
                                failure:(void (^)(NSError *error))failure
{

    NSManagedObjectID *postObjectID = post.objectID;
    CommentServiceRemoteREST *service = [self remoteForREST];
    [service syncHierarchicalCommentsForPost:post.postID fromSite:post.siteID page:page success:^(NSArray *comments) {
        [self.managedObjectContext performBlock:^{
            NSError *error;
            ReaderPost *aPost = (ReaderPost *)[self.managedObjectContext existingObjectWithID:postObjectID error:&error];
            if (!aPost) {
                if (failure) {
                    failure(error);
                }
                return;
            }

            [self mergeHierarchicalComments:comments forPost:aPost];

            if (success) {
                success([comments count]);
            }
        }];
    } failure:^(NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}


#pragma mark - REST Helpers

// Edition
- (void)updateCommentWithID:(NSNumber *)commentID
                     siteID:(NSNumber *)siteID
                    content:(NSString *)content
                    success:(void (^)())success
                    failure:(void (^)(NSError *error))failure
{
    CommentServiceRemoteREST *remote = [self remoteForREST];
    [remote updateCommentWithID:commentID
                         siteID:siteID
                        content:content
                        success:success
                        failure:failure];
}

// Likes
- (void)likeCommentWithID:(NSNumber *)commentID
                   siteID:(NSNumber *)siteID
                  success:(void (^)())success
                  failure:(void (^)(NSError *error))failure
{
    CommentServiceRemoteREST *remote = [self remoteForREST];
    [remote likeCommentWithID:commentID
                       siteID:siteID
                      success:success
                      failure:failure];
}

- (void)unlikeCommentWithID:(NSNumber *)commentID
                     siteID:(NSNumber *)siteID
                    success:(void (^)())success
                    failure:(void (^)(NSError *error))failure
{
    CommentServiceRemoteREST *remote = [self remoteForREST];
    [remote unlikeCommentWithID:commentID
                         siteID:siteID
                        success:success
                        failure:failure];
}

// Moderation
- (void)approveCommentWithID:(NSNumber *)commentID
                      siteID:(NSNumber *)siteID
                     success:(void (^)())success
                     failure:(void (^)(NSError *error))failure
{
    CommentServiceRemoteREST *remote = [self remoteForREST];
    [remote moderateCommentWithID:commentID
                           siteID:siteID
                           status:@"approved"
                          success:success
                          failure:failure];
}

- (void)unapproveCommentWithID:(NSNumber *)commentID
                        siteID:(NSNumber *)siteID
                       success:(void (^)())success
                       failure:(void (^)(NSError *error))failure
{
    CommentServiceRemoteREST *remote = [self remoteForREST];
    [remote moderateCommentWithID:commentID
                           siteID:siteID
                           status:@"unapproved"
                          success:success
                          failure:failure];
}

- (void)spamCommentWithID:(NSNumber *)commentID
                   siteID:(NSNumber *)siteID
                  success:(void (^)())success
                  failure:(void (^)(NSError *error))failure
{
    CommentServiceRemoteREST *remote = [self remoteForREST];
    [remote moderateCommentWithID:commentID
                           siteID:siteID
                           status:@"spam"
                          success:success
                          failure:failure];
}

// Trash
- (void)deleteCommentWithID:(NSNumber *)commentID
                     siteID:(NSNumber *)siteID
                    success:(void (^)())success
                    failure:(void (^)(NSError *error))failure
{
    CommentServiceRemoteREST *remote = [self remoteForREST];
    [remote trashCommentWithID:commentID
                        siteID:siteID
                       success:success
                       failure:failure];
}


#pragma mark - Private methods

#pragma mark - Blog centric methods
// Generic moderation
- (void)moderateComment:(Comment *)comment
             withStatus:(NSString *)status
                success:(void (^)())success
                failure:(void (^)(NSError *error))failure
{
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

- (void)mergeComments:(NSArray *)comments forBlog:(Blog *)blog completionHandler:(void (^)(void))completion
{
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
            if (![commentsToKeep containsObject:comment] && comment.commentID != nil) {
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

- (Comment *)findCommentWithID:(NSNumber *)commentID inBlog:(Blog *)blog
{
    NSSet *comments = [blog.comments filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"commentID = %@", commentID]];
    return [comments anyObject];
}

#pragma mark - Post centric methods

- (NSMutableArray *)ancestorsForCommentWithParentID:(NSNumber *)commentParentID andCurrentAncestors:(NSArray *)currentAncestors
{
    NSMutableArray *ancestors = [currentAncestors mutableCopy];

    // Calculate hierarchy and depth.
    NSString *parentID = [commentParentID stringValue];
    if (parentID) {
        if ([ancestors containsObject:parentID]) {
            NSUInteger index = [ancestors indexOfObject:parentID] + 1;
            NSArray *subarray = [ancestors subarrayWithRange:NSMakeRange(0, index)];
            [ancestors removeAllObjects];
            [ancestors addObjectsFromArray:subarray];
        } else {
            [ancestors addObject:parentID];
        }
    } else {
        [ancestors removeAllObjects];
    }
    return ancestors;
}

- (NSString *)hierarchyFromAncestors:(NSArray *)ancestors andCommentID:(NSNumber *)commentID
{
    NSString *hierarchy = [commentID stringValue];
    if ([ancestors count] > 0) {
        hierarchy = [NSString stringWithFormat:@"%@.%@", [ancestors componentsJoinedByString:@"."], hierarchy];
    }
    return hierarchy;
}

- (void)mergeHierarchicalComments:(NSArray *)comments forPost:(ReaderPost *)post
{
    if (![comments count]) {
        return;
    }

    NSMutableArray *ancestors = [NSMutableArray array];
    NSMutableArray *commentsToKeep = [NSMutableArray array];
    NSString *entityName = NSStringFromClass([Comment class]);

    for (RemoteComment *remoteComment in comments) {
        Comment *comment = [self findCommentWithID:remoteComment.commentID fromPost:post];
        if (!comment) {
            comment = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:self.managedObjectContext];
        }
        [self updateComment:comment withRemoteComment:remoteComment];

        // Calculate hierarchy and depth.
        ancestors = [self ancestorsForCommentWithParentID:comment.parentID andCurrentAncestors:ancestors];
        comment.hierarchy = [self hierarchyFromAncestors:ancestors andCommentID:comment.commentID];
        comment.depth = @([ancestors count]);
        comment.post = post;

        [commentsToKeep addObject:comment];
    }

    // Remove deleted comments
    [self deleteCommentsMissingFromHierarchicalComments:commentsToKeep forPost:post];

    [self.managedObjectContext performBlock:^{
        [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
    }];
}

// Does not save context
- (void)deleteCommentsMissingFromHierarchicalComments:(NSArray *)commentsToKeep forPost:(ReaderPost *)post
{
    // Remove deleted comments
    NSString *entityName = NSStringFromClass([Comment class]);
    NSString *starting = [[commentsToKeep firstObject] hierarchy];
    NSString *ending = [[commentsToKeep lastObject] hierarchy];

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entityName];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"post = %@ AND hierarchy >= %@ AND hierarchy <= %@", post, starting, ending];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"hierarchy" ascending:YES];
    fetchRequest.sortDescriptors = @[sortDescriptor];

    NSError *error = nil;
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
        DDLogError(@"Error fetching existing comments : %@", error);
    }

    for (Comment *comment in fetchedObjects) {
        if (![commentsToKeep containsObject:comment]) {
            [self.managedObjectContext deleteObject:comment];
        }
    }
}

- (Comment *)findCommentWithID:(NSNumber *)commentID fromPost:(ReaderPost *)post
{
    NSSet *comments = [post.comments filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"commentID = %@", commentID]];
    return [comments anyObject];
}


#pragma mark - Transformations

- (void)updateComment:(Comment *)comment withRemoteComment:(RemoteComment *)remoteComment
{
    comment.commentID = remoteComment.commentID;
    comment.author = remoteComment.author;
    comment.author_email = remoteComment.authorEmail;
    comment.author_url = remoteComment.authorUrl;
    comment.authorAvatarURL = remoteComment.authorAvatarURL;
    comment.content = remoteComment.content;
    comment.dateCreated = remoteComment.date;
    comment.link = remoteComment.link;
    comment.parentID = remoteComment.parentID;
    comment.postID = remoteComment.postID;
    comment.postTitle = remoteComment.postTitle;
    comment.status = remoteComment.status;
    comment.type = remoteComment.type;
}

- (RemoteComment *)remoteCommentWithComment:(Comment *)comment
{
    RemoteComment *remoteComment = [RemoteComment new];
    remoteComment.commentID = comment.commentID;
    remoteComment.author = comment.author;
    remoteComment.authorEmail = comment.author_email;
    remoteComment.authorUrl = comment.author_url;
    remoteComment.authorAvatarURL = comment.authorAvatarURL;
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


#pragma mark - Remotes

- (id<CommentServiceRemote>)remoteForBlog:(Blog *)blog
{
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

- (CommentServiceRemoteREST *)remoteForREST
{
    return [[CommentServiceRemoteREST alloc] initWithApi:[self apiForRESTRequest]];
}

/**
 Get the api to use for the request.
 */
- (WordPressComApi *)apiForRESTRequest
{
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:self.managedObjectContext];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];
    WordPressComApi *api = [defaultAccount restApi];
    if (![api hasCredentials]) {
        api = [WordPressComApi anonymousApi];
    }
    return api;
}

@end
