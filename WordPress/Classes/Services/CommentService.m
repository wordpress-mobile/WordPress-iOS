#import "CommentService.h"
#import "AccountService.h"
#import "Blog.h"
#import "Comment.h"
#import "CommentServiceRemote.h"
#import "CommentServiceRemoteXMLRPC.h"
#import "CommentServiceRemoteREST.h"
#import "ContextManager.h"
#import "NSString+Helpers.h"
#import "ReaderPost.h"
#import "WPAccount.h"
#import "PostService.h"
#import "AbstractPost.h"
#import "NSDate+WordPressJSON.h"

NSUInteger const WPTopLevelHierarchicalCommentsPerPage = 20;
NSInteger const  WPNumberOfCommentsToSync = 100;

@implementation CommentService

+ (NSMutableSet *)syncingCommentsLocks
{
    static NSMutableSet *syncingCommentsLocks;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        syncingCommentsLocks = [NSMutableSet set];
    });
    return syncingCommentsLocks;
}

+ (BOOL)isSyncingCommentsForBlog:(Blog *)blog {
    return [self isSyncingCommentsForBlogID:blog.objectID];
}

+ (BOOL)isSyncingCommentsForBlogID:(NSManagedObjectID *)blogID
{
    NSParameterAssert(blogID);
    return [[self syncingCommentsLocks] containsObject:blogID];
}

+ (BOOL)startSyncingCommentsForBlog:(NSManagedObjectID *)blogID
{
    NSParameterAssert(blogID);
    @synchronized([self syncingCommentsLocks]) {
        if ([self isSyncingCommentsForBlogID:blogID]){
            return NO;
        }
        [[self syncingCommentsLocks] addObject:blogID];
         return YES;
    }
}

+ (void)stopSyncingCommentsForBlog:(NSManagedObjectID *)blogID
{
    NSParameterAssert(blogID);
    @synchronized([self syncingCommentsLocks]) {
        [[self syncingCommentsLocks] removeObject:blogID];
    }
}

- (NSSet *)findCommentsWithPostID:(NSNumber *)postID inBlog:(Blog *)blog
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"postID = %@", postID];
    return [blog.comments filteredSetUsingPredicate:predicate];
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
                    success:(void (^)(BOOL hasMore))success
                    failure:(void (^)(NSError *error))failure
{
    NSManagedObjectID *blogID = blog.objectID;
    if (![[self class] startSyncingCommentsForBlog:blogID]){
        // We assume success because a sync is already running and it will change the comments
        if (success) {
            success(YES);
        }
        return;
    }
    
    id<CommentServiceRemote> remote = [self remoteForBlog:blog];
    [remote getCommentsWithMaximumCount:WPNumberOfCommentsToSync success:^(NSArray *comments) {
         [self.managedObjectContext performBlock:^{
             Blog *blogInContext = (Blog *)[self.managedObjectContext existingObjectWithID:blogID error:nil];
             if (blogInContext) {
                 [self mergeComments:comments
                             forBlog:blog
                       purgeExisting:YES
                   completionHandler:^{
                       [[self class] stopSyncingCommentsForBlog:blogID];
                       
                       blogInContext.lastCommentsSync = [NSDate date];
                       [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
                       
                       if (success) {
                           // Note:
                           // We'll assume that if the requested page size couldn't be filled, there are no
                           // more comments left to retrieve.
                           BOOL hasMore = comments.count >= WPNumberOfCommentsToSync;
                           success(hasMore);
                       }
                   }];
             }
         }];
     } failure:^(NSError *error) {
         [[self class] stopSyncingCommentsForBlog:blogID];
         if (failure) {
             [self.managedObjectContext performBlock:^{
                 failure(error);
             }];
         }
     }];
}

- (Comment *)oldestCommentForBlog:(Blog *)blog {
    NSString *entityName = NSStringFromClass([Comment class]);
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    request.predicate = [NSPredicate predicateWithFormat:@"dateCreated != NULL && blog=%@", blog];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"dateCreated" ascending:YES];
    request.sortDescriptors = @[sortDescriptor];
    Comment *oldestComment = [[self.managedObjectContext executeFetchRequest:request error:nil] firstObject];
    return oldestComment;
}

- (void)loadMoreCommentsForBlog:(Blog *)blog
                        success:(void (^)(BOOL hasMore))success
                        failure:(void (^)(NSError *))failure
{
    NSManagedObjectID *blogID = blog.objectID;
    if (![[self class] startSyncingCommentsForBlog:blogID]){
        // We assume success because a sync is already running and it will change the comments
        if (success) {
            success(YES);
        }
    }

    id<CommentServiceRemote> remote = [self remoteForBlog:blog];
    NSMutableDictionary *options = [NSMutableDictionary dictionary];
    if ([remote isKindOfClass:[CommentServiceRemoteREST class]]) {
        Comment *oldestComment = [self oldestCommentForBlog:blog];
        if (oldestComment.dateCreated) {
            options[@"before"] = [oldestComment.dateCreated WordPressComJSONString];
            options[@"order"] = @"desc";
        }
    } else if ([remote isKindOfClass:[CommentServiceRemoteXMLRPC class]]) {
        NSUInteger commentCount = [blog.comments count];
        options[@"offset"] = @(commentCount);
    }
    [remote getCommentsWithMaximumCount:WPNumberOfCommentsToSync options:options success:^(NSArray *comments) {
        [self.managedObjectContext performBlock:^{
            Blog *blog = (Blog *)[self.managedObjectContext existingObjectWithID:blogID error:nil];
            if (!blog) {
                return;
            }
            [self mergeComments:comments forBlog:blog purgeExisting:NO completionHandler:^{
                 [[self class] stopSyncingCommentsForBlog:blogID];
                 if (success) {
                     success(comments.count > 1);
                 }
             }];
        }];
        
    } failure:^(NSError *error) {
        [[self class] stopSyncingCommentsForBlog:blogID];
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
                      success:successBlock
                      failure:failure];
    } else {
        [remote createComment:remoteComment
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
               withStatus:CommentStatusApproved
                  success:success
                  failure:failure];
}

// Unapprove
- (void)unapproveComment:(Comment *)comment
                 success:(void (^)())success
                 failure:(void (^)(NSError *error))failure
{
    [self moderateComment:comment
               withStatus:CommentStatusPending
                  success:success
                  failure:failure];
}

// Spam
- (void)spamComment:(Comment *)comment
            success:(void (^)())success
            failure:(void (^)(NSError *error))failure
{
    NSManagedObjectID *commentID = comment.objectID;
    [self moderateComment:comment
               withStatus:CommentStatusSpam
                  success:^{
                      Comment *commentInContext = (Comment *)[self.managedObjectContext existingObjectWithID:commentID error:nil];
                      [self.managedObjectContext deleteObject:commentInContext];
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
        [remote trashComment:remoteComment success:success failure:failure];
    }
    [self.managedObjectContext deleteObject:comment];
    [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
}


#pragma mark - Post-centric methods

- (void)syncHierarchicalCommentsForPost:(ReaderPost *)post
                                   page:(NSUInteger)page
                                success:(void (^)(NSInteger count, BOOL hasMore))success
                                failure:(void (^)(NSError *error))failure
{
    NSManagedObjectID *postObjectID = post.objectID;
    CommentServiceRemoteREST *service = [self restRemoteForSite:post.siteID];
    [service syncHierarchicalCommentsForPost:post.postID
                                        page:page
                                      number:WPTopLevelHierarchicalCommentsPerPage
                                     success:^(NSArray *comments) {
                                         [self.managedObjectContext performBlock:^{
                                             NSError *error;
                                             ReaderPost *aPost = (ReaderPost *)[self.managedObjectContext existingObjectWithID:postObjectID error:&error];
                                             if (!aPost) {
                                                 if (failure) {
                                                     failure(error);
                                                 }
                                                 return;
                                             }

                                             [self mergeHierarchicalComments:comments forPage:page forPost:aPost];

                                             if (success) {
                                                 NSArray *parents = [self topLevelCommentsForPage:page forPost:aPost];
                                                 BOOL hasMore = [parents count] == WPTopLevelHierarchicalCommentsPerPage;
                                                 success([comments count], hasMore);
                                             }
                                         }];
                                     } failure:^(NSError *error) {
                                         [self.managedObjectContext performBlock:^{
                                             if (failure) {
                                                 failure(error);
                                             }
                                         }];
                                     }];
}

- (NSInteger)numberOfHierarchicalPagesSyncedforPost:(ReaderPost *)post
{
    NSSet *topComments = [post.comments filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"parentID = NULL"]];
    CGFloat page = [topComments count] / WPTopLevelHierarchicalCommentsPerPage;
    return (NSInteger)page;
}

#pragma mark - REST Helpers

// Edition
- (void)updateCommentWithID:(NSNumber *)commentID
                     siteID:(NSNumber *)siteID
                    content:(NSString *)content
                    success:(void (^)())success
                    failure:(void (^)(NSError *error))failure
{
    CommentServiceRemoteREST *remote = [self restRemoteForSite:siteID];
    [remote updateCommentWithID:commentID
                        content:content
                        success:success
                        failure:failure];
}

// Replies
- (void)replyToPostWithID:(NSNumber *)postID
                   siteID:(NSNumber *)siteID
                  content:(NSString *)content
                  success:(void (^)())success
                  failure:(void (^)(NSError *error))failure
{
    // Create and optimistically save a comment, based on the current wpcom acct
    // post and content provided.
    Comment *comment = [self createHierarchicalCommentWithContent:content withParent:nil postID:postID siteID:siteID];
    NSManagedObjectID *commentID = comment.objectID;
    void (^successBlock)(RemoteComment *remoteComment) = ^void(RemoteComment *remoteComment) {
        [self.managedObjectContext performBlock:^{
            Comment *comment = (Comment *)[self.managedObjectContext existingObjectWithID:commentID error:nil];
            if (!comment) {
                return;
            }
            // Update and save the comment
            [self updateCommentAndSave:comment withRemoteComment:remoteComment];
            if (success) {
                success();
            }
        }];
    };

    void (^failureBlock)(NSError *error) = ^void(NSError *error) {
        [self.managedObjectContext performBlock:^{
            Comment *comment = (Comment *)[self.managedObjectContext existingObjectWithID:commentID error:nil];
            if (!comment) {
                return;
            }
            // Remove the optimistically saved comment.
            [self deleteComment:comment success:nil failure:nil];
            if (failure) {
                failure(error);
            }
        }];
    };

    CommentServiceRemoteREST *remote = [self restRemoteForSite:siteID];
    [remote replyToPostWithID:postID
                      content:content
                      success:successBlock
                      failure:failureBlock];
}

- (void)replyToHierarchicalCommentWithID:(NSNumber *)commentID
                                  postID:(NSNumber *)postID
                                  siteID:(NSNumber *)siteID
                                 content:(NSString *)content
                                 success:(void (^)())success
                                 failure:(void (^)(NSError *error))failure
{
    // Create and optimistically save a comment, based on the current wpcom acct
    // post and content provided.
    Comment *comment = [self createHierarchicalCommentWithContent:content withParent:commentID postID:postID siteID:siteID];
    NSManagedObjectID *commentObjectID = comment.objectID;
    void (^successBlock)(RemoteComment *remoteComment) = ^void(RemoteComment *remoteComment) {
        // Update and save the comment
        [self.managedObjectContext performBlock:^{
            Comment *comment = (Comment *)[self.managedObjectContext existingObjectWithID:commentObjectID error:nil];
            if (!comment) {
                return;
            }
            [self updateCommentAndSave:comment withRemoteComment:remoteComment];
            if (success) {
                success();
            }
        }];
    };

    void (^failureBlock)(NSError *error) = ^void(NSError *error) {
        [self.managedObjectContext performBlock:^{
            Comment *comment = (Comment *)[self.managedObjectContext existingObjectWithID:commentObjectID error:nil];
            if (!comment) {
                return;
            }
            // Remove the optimistically saved comment.
            ReaderPost *post = (ReaderPost *)comment.post;
            post.commentCount = @([post.commentCount integerValue] - 1);
            [self deleteComment:comment success:nil failure:nil];
            if (failure) {
                failure(error);
            }
        }];
    };

    CommentServiceRemoteREST *remote = [self restRemoteForSite:siteID];
    [remote replyToCommentWithID:commentID
                         content:content
                         success:successBlock
                         failure:failureBlock];
}

- (void)replyToCommentWithID:(NSNumber *)commentID
                      siteID:(NSNumber *)siteID
                     content:(NSString *)content
                     success:(void (^)())success
                     failure:(void (^)(NSError *error))failure
{
    CommentServiceRemoteREST *remote = [self restRemoteForSite:siteID];
    [remote replyToCommentWithID:commentID
                         content:content
                         success:^(RemoteComment *comment){
                             if (success){
                                 success();
                             }
                         }
                         failure:failure];
}


// Likes
- (void)likeCommentWithID:(NSNumber *)commentID
                   siteID:(NSNumber *)siteID
                  success:(void (^)())success
                  failure:(void (^)(NSError *error))failure
{
    CommentServiceRemoteREST *remote = [self restRemoteForSite:siteID];
    [remote likeCommentWithID:commentID
                      success:success
                      failure:failure];
}

- (void)unlikeCommentWithID:(NSNumber *)commentID
                     siteID:(NSNumber *)siteID
                    success:(void (^)())success
                    failure:(void (^)(NSError *error))failure
{
    CommentServiceRemoteREST *remote = [self restRemoteForSite:siteID];
    [remote unlikeCommentWithID:commentID
                        success:success
                        failure:failure];
}

// Moderation
- (void)approveCommentWithID:(NSNumber *)commentID
                      siteID:(NSNumber *)siteID
                     success:(void (^)())success
                     failure:(void (^)(NSError *error))failure
{
    CommentServiceRemoteREST *remote = [self restRemoteForSite:siteID];
    [remote moderateCommentWithID:commentID
                           status:@"approved"
                          success:success
                          failure:failure];
}

- (void)unapproveCommentWithID:(NSNumber *)commentID
                        siteID:(NSNumber *)siteID
                       success:(void (^)())success
                       failure:(void (^)(NSError *error))failure
{
    CommentServiceRemoteREST *remote = [self restRemoteForSite:siteID];
    [remote moderateCommentWithID:commentID
                           status:@"unapproved"
                          success:success
                          failure:failure];
}

- (void)spamCommentWithID:(NSNumber *)commentID
                   siteID:(NSNumber *)siteID
                  success:(void (^)())success
                  failure:(void (^)(NSError *error))failure
{
    CommentServiceRemoteREST *remote = [self restRemoteForSite:siteID];
    [remote moderateCommentWithID:commentID
                           status:CommentStatusSpam
                          success:success
                          failure:failure];
}

// Trash
- (void)deleteCommentWithID:(NSNumber *)commentID
                     siteID:(NSNumber *)siteID
                    success:(void (^)())success
                    failure:(void (^)(NSError *error))failure
{
    CommentServiceRemoteREST *remote = [self restRemoteForSite:siteID];
    [remote trashCommentWithID:commentID
                       success:success
                       failure:failure];
}

- (void)toggleLikeStatusForComment:(Comment *)comment
                            siteID:(NSNumber *)siteID
                           success:(void (^)())success
                           failure:(void (^)(NSError *error))failure
{
    // toggle the like status and change the like count and save it
    comment.isLiked = !comment.isLiked;
    comment.likeCount = @([comment.likeCount intValue] + (comment.isLiked ? 1 : -1));

    [[ContextManager sharedInstance] saveContext:self.managedObjectContext];

    __weak __typeof(self) weakSelf = self;
    NSManagedObjectID *commentID = comment.objectID;

    // This block will reverse the like/unlike action
    void (^failureBlock)(NSError *) = ^(NSError *error) {
        Comment *comment = (Comment *)[self.managedObjectContext existingObjectWithID:commentID error:nil];
        if (!comment) {
            return;
        }
        DDLogError(@"Error while %@ comment: %@", comment.isLiked ? @"liking" : @"unliking", error);

        comment.isLiked = !comment.isLiked;
        comment.likeCount = @([comment.likeCount intValue] + (comment.isLiked ? 1 : -1));

        [[ContextManager sharedInstance] saveContext:weakSelf.managedObjectContext];

        if (failure) {
            failure(error);
        }
    };

    if (comment.isLiked) {
        [self likeCommentWithID:comment.commentID siteID:siteID success:success failure:failureBlock];
    }
    else {
        [self unlikeCommentWithID:comment.commentID siteID:siteID success:success failure:failureBlock];
    }
}


#pragma mark - Private methods

// Deletes orphaned comments. Does not save context.
- (void)deleteUnownedComments
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([Comment class])];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"post = NULL && blog = NULL"];

    NSError *error;
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
        DDLogError(@"Error fetching orphaned comments: %@", error);
    }
    for (Comment *comment in results) {
        [self.managedObjectContext deleteObject:comment];
    }
}


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
    NSManagedObjectID *commentID = comment.objectID;
    [remote moderateComment:remoteComment
                    success:^(RemoteComment *comment) {
                        if (success) {
                            success();
                        }
                    } failure:^(NSError *error) {
                        [self.managedObjectContext performBlock:^{
                            // Note: The comment might have been deleted at this point
                            Comment *commentInContext = (Comment *)[self.managedObjectContext existingObjectWithID:commentID error:nil];
                            if (commentInContext) {
                                commentInContext.status = prevStatus;
                                [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
                            }

                            if (failure) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    failure(error);
                                });
                            }
                        }];
                    }];
}

- (void)mergeComments:(NSArray *)comments
              forBlog:(Blog *)blog
        purgeExisting:(BOOL)purgeExisting
    completionHandler:(void (^)(void))completion
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

    if (purgeExisting) {
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
    }

    [self deleteUnownedComments];
    [[ContextManager sharedInstance] saveDerivedContext:self.managedObjectContext withCompletionBlock:^{
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), completion);
        }
    }];
}

- (Comment *)findCommentWithID:(NSNumber *)commentID inBlog:(Blog *)blog
{
    NSSet *comments = [blog.comments filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"commentID = %@", commentID]];
    return [comments anyObject];
}

#pragma mark - Post centric methods

- (NSMutableArray *)ancestorsForCommentWithParentID:(NSNumber *)parentID andCurrentAncestors:(NSArray *)currentAncestors
{
    NSMutableArray *ancestors = [currentAncestors mutableCopy];

    // Calculate hierarchy and depth.
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
    NSArray *arr = [ancestors arrayByAddingObject:commentID];
    arr = [self formatHierarchyElements:arr];
    return [arr componentsJoinedByString:@"."];
}

- (NSArray *)formatHierarchyElements:(NSArray *)hierarchy
{
    NSMutableArray *arr = [NSMutableArray array];
    for (NSNumber *commentID in hierarchy) {
        [arr addObject:[self formattedHierarchyElement:commentID]];
    }
    return arr;
}

- (NSString *)formattedHierarchyElement:(NSNumber *)commentID
{
    return [NSString stringWithFormat:@"%010u", [commentID integerValue]];
}

- (Comment *)createHierarchicalCommentWithContent:(NSString *)content withParent:(NSNumber *)parentID postID:(NSNumber *)postID siteID:(NSNumber *)siteID
{
    // Fetch the relevant ReaderPost
    NSError *error;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([ReaderPost class])];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"postID = %@ AND siteID = %@", postID, siteID];
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
        DDLogError(@"Error fetching post with id %@ and site %@. %@", postID, siteID, error);
        return nil;
    }

    ReaderPost *post = [results firstObject];
    if (!post) {
        return nil;
    }

    // (Insert a new comment into core data. Check for its existance first for paranoia sake.
    // In theory a sync could include a newly created comment before the request that created it returned.
    Comment *comment = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([Comment class]) inManagedObjectContext:self.managedObjectContext];

    AccountService *service = [[AccountService alloc] initWithManagedObjectContext:self.managedObjectContext];
    comment.author = [[service defaultWordPressComAccount] username];
    comment.content = content;
    comment.dateCreated = [NSDate date];
    comment.parentID = parentID;
    comment.postID = postID;
    comment.postTitle = post.postTitle;
    comment.status = CommentStatusDraft;
    comment.post = post;

    // Increment the post's comment count. 
    post.commentCount = @([post.commentCount integerValue] + 1);

    // Find its parent comment (if it exists)
    Comment *parentComment;
    if (parentID) {
        parentComment = [self findCommentWithID:parentID fromPost:post];
    }

    // Update depth and hierarchy
    [self setHierarchAndDepthOnComment:comment withParentComment:parentComment];

    [self.managedObjectContext obtainPermanentIDsForObjects:@[comment] error:&error];
    if (error) {
        DDLogError(@"%@ error obtaining permanent ID for a hierarchical comment %@: %@", NSStringFromSelector(_cmd), comment, error);
    }
    [[ContextManager sharedInstance] saveContext:self.managedObjectContext];

    return comment;
}

- (void)setHierarchAndDepthOnComment:(Comment *)comment withParentComment:(Comment *)parentComment
{
    // Update depth and hierarchy
    NSNumber *commentID = comment.commentID;
    if (!commentID) {
        // A new comment will have a nil commentID.  If nil is used when formatting the hierarchy,
        // the comment will preceed any other comment in its level of the hierarchy.
        // Instead we'll pass a number so large as to ensure the comment will appear last in a list.
        commentID = @9999999;
    }

    if (parentComment) {
        comment.hierarchy = [NSString stringWithFormat:@"%@.%@", parentComment.hierarchy, [self formattedHierarchyElement:commentID]];
        comment.depth = @([parentComment.depth integerValue] + 1);
    } else {
        comment.hierarchy = [self formattedHierarchyElement:commentID];
        comment.depth = @(0);
    }

    [self.managedObjectContext performBlock:^{
        [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
    }];
}

- (void)updateCommentAndSave:(Comment *)comment withRemoteComment:(RemoteComment *)remoteComment
{
    [self updateComment:comment withRemoteComment:remoteComment];
    // Find its parent comment (if it exists)
    Comment *parentComment;
    if (comment.parentID) {
        parentComment = [self findCommentWithID:comment.parentID fromPost:(ReaderPost *)comment.post];
    }

    // Update depth and hierarchy
    [self setHierarchAndDepthOnComment:comment withParentComment:parentComment];
    [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
}

- (void)mergeHierarchicalComments:(NSArray *)comments forPage:(NSUInteger)page forPost:(ReaderPost *)post
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
        comment.content = [comment.content stringByReplacingHTMLEmoticonsWithEmoji];
        [commentsToKeep addObject:comment];
    }

    // Remove deleted comments
    // When merging the first fetched page of comments, clear out anything that was previously
    // cached and missing from the comments just synced. This provides for a clean slate and
    // helps avoid certain cases where some pages might not be resynced, creating gaps in the content.
    if (page == 1) {
        [self deleteCommentsMissingFromHierarchicalComments:commentsToKeep forPost:post];
        [self deleteUnownedComments];
    }

    // Make sure the post's comment count is at least the number of comments merged.
    if ([post.commentCount integerValue] < [commentsToKeep count]) {
        post.commentCount = @([commentsToKeep count]);
    }

    [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
}

// Does not save context
- (void)deleteCommentsMissingFromHierarchicalComments:(NSArray *)commentsToKeep forPost:(ReaderPost *)post
{
    for (Comment *comment in post.comments) {
        if (![commentsToKeep containsObject:comment]) {
            [self.managedObjectContext deleteObject:comment];
        }
    }
}

- (NSArray *)topLevelCommentsForPage:(NSUInteger)page forPost:(ReaderPost *)post
{
    NSString *entityName = NSStringFromClass([Comment class]);

    // Retrieve the starting and ending comments for the specified page.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entityName];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"post = %@ AND parentID = NULL", post];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"hierarchy" ascending:YES];
    fetchRequest.sortDescriptors = @[sortDescriptor];
    [fetchRequest setFetchLimit:WPTopLevelHierarchicalCommentsPerPage];
    NSUInteger offset = WPTopLevelHierarchicalCommentsPerPage * (page - 1);
    [fetchRequest setFetchOffset:offset];

    NSError *error = nil;
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
        DDLogError(@"Error fetching top level comments for page %i : %@", page, error);
    }
    return fetchedObjects;
}

- (Comment *)firstCommentForPage:(NSUInteger)page forPost:(ReaderPost *)post
{
    NSArray *comments = [self topLevelCommentsForPage:page forPost:post];
    return [comments firstObject];
}

- (Comment *)lastCommentForPage:(NSUInteger)page forPost:(ReaderPost *)post
{
    NSArray *comments = [self topLevelCommentsForPage:page forPost:post];
    Comment *lastParentComment = [comments lastObject];

    NSString *entityName = NSStringFromClass([Comment class]);
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entityName];
    NSString *wildCard = [NSString stringWithFormat:@"%@*", lastParentComment.hierarchy];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"post = %@ AND hierarchy LIKE %@", post, wildCard];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"hierarchy" ascending:YES];
    fetchRequest.sortDescriptors = @[sortDescriptor];

    NSError *error = nil;
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
        DDLogError(@"Error fetching last comment for page %i : %@", page, error);
    }
    return [fetchedObjects lastObject];
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
    comment.isLiked = remoteComment.isLiked;
    comment.likeCount = remoteComment.likeCount;

    // if the post for the comment is not set, check if that post is already stored and associate them
    if (!comment.post) {
        PostService *postService = [[PostService alloc] initWithManagedObjectContext:self.managedObjectContext];
        comment.post = [postService findPostWithID:comment.postID inBlog:comment.blog];
    }
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
    remoteComment.isLiked = comment.isLiked;
    remoteComment.likeCount = comment.likeCount;
    return remoteComment;
}


#pragma mark - Remotes

- (id<CommentServiceRemote>)remoteForBlog:(Blog *)blog
{
    id<CommentServiceRemote>remote;
    // TODO: refactor API creation so it's not part of the model
    if (blog.restApi) {
        remote = [[CommentServiceRemoteREST alloc] initWithApi:blog.restApi siteID:blog.dotComID];
    } else {
        remote = [[CommentServiceRemoteXMLRPC alloc] initWithApi:blog.api username:blog.username password:blog.password];
    }
    return remote;
}

- (CommentServiceRemoteREST *)restRemoteForSite:(NSNumber *)siteID
{
    return [[CommentServiceRemoteREST alloc] initWithApi:[self apiForRESTRequest] siteID:siteID];
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
